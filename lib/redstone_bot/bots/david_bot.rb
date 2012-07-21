require 'forwardable'
require 'fiber'

require "redstone_bot/bot"
require "redstone_bot/chat_evaluator"
require "redstone_bot/pathfinder"
require "redstone_bot/waypoint"
require "redstone_bot/jump"
require "redstone_bot/multi_action"

class FiberWrapper
  def initialize(meth)
  
  end
end

module RedstoneBot
  module Bots; end

  class Bots::DavidBot < RedstoneBot::Bot
    extend Forwardable
    
    def setup
      standard_setup
      
      @body.update_period = 0.05
      #@body.debug = true
      
      @ce = ChatEvaluator.new(self, @client)
      @ce.master = MASTER if defined?(MASTER)
      
      @current_action = nil
      
      @body.on_position_update do
        if @current_action
          @current_action.start(@body) unless @current_action.started?
          @current_action.update_position(@body)
          @current_action = nil if @current_action.done?
        elsif @current_fiber
          if @current_fiber.respond_to? :call
            c = @current_fiber
            @current_fiber = Fiber.new { c.call }
          end
          @current_fiber.resume
          @current_fiber = nil if !@current_fiber.alive?
        else
          fall_update
          @body.look_at @entity_tracker.closest_entity
        end
        @body.stance = @body.position[1] + 1.62   # TODO: let @body handle setting stance correctly
      end
      
      @pathfinder = Pathfinder.new(@chunk_tracker)
      
      @client.listen do |p|
        case p
        when Packet::ChatMessage
          puts p
          next if !p.player_chat? || (defined?(MASTER) && p.username != MASTER)
          case p.chat
            when /where (.+)/ then
              name = $1
              if name == "u"
                chat "I be at #{@body.position}"
              else
                player = @entity_tracker.player(name)
                if player
                  chat "dat guy at #{player.position}"
                else
                  chat "dunno who dat '#{name}' is"
                end
              end
            when "stop" then @current_action = nil
            when "n", "z-" then @current_action = Waypoint.new @body.position - Coords::Z
            when "s", "z+" then @current_action = Waypoint.new @body.position + Coords::Z
            when "e", "x+" then @current_action = Waypoint.new @body.position + Coords::X
            when "w", "x-" then @current_action = Waypoint.new @body.position - Coords::X
            when "j" then @current_action = Jump.new(5)
            when "m"
              player = @entity_tracker.player(p.username)
              if player
                x, z = player.position.x, player.position.z
                chat "coming to #{x}, #{z}!"
                @current_fiber = new_fiber :miracle_fiber, x, z
              else
                chat "dunno where U r (chat m <X> <Z> to specify)"
              end
            when /m (\-?\d+) (\-?\d+)/
              x = $1.to_i
              z = $2.to_i
              chat "coming to #{x}, #{z}!"
              miracle x, z
            when "h"
              player = @entity_tracker.player(p.username)
              if player
                chat "coming!"
                @current_action = Waypoint.new player.position + Coords::Y*0.2
              else
                chat "dunno where U r"
              end
            when "f"
              @current_fiber = new_fiber :tmphax_fiber
            end              
        when Packet::Disconnect
          puts "Fly time = #{Time.now-@start_fly}" if @start_fly
          exit 2
        end        
      end 
      
    end
    
    def miracle_fiber(x, z)
      puts "miracle_fiber #{x} #{z}"
    
      opts = { :update_period => 0.01, :speed => 500 }
    
      @start_fly = Time.now
      jump_to_height 276, opts
      move_to Coords[x, 257, z], opts
      fall opts
      chat "I be at #{@body.position} after #{Time.now - @start_fly} seconds."
    end

    def move_to(coords, opts={})
      tolerance = opts[:tolerance] || 0.2
      speed = opts[:speed] || 10
      axes = [Coords::X, Coords::Y, Coords::Z].cycle
      
      while true
        wait_for_next_position_update(opts[:update_period])
        @body.look_at coords

        d = coords - @body.position
        if d.norm < tolerance
          return # reached it
        end
      
        max_distance = speed*@body.last_update_period
        if d.norm > max_distance
          d = d.normalize*max_distance
        end
      
        if @body.bumped?
          d = d.project_onto_unit_vector(axes.next)*3
        end
      
        @body.position += d
      end
      
    end
    
    def new_fiber(meth, *args)
      if meth.is_a? Symbol
        meth = method(meth)
      end
      @current_fiber = Proc.new { meth.call(*args) }
    end
    
    def tmphax_fiber
      jump 5
      fall
      jump 4
      fall
      jump 3
      fall
    end
    
    def jump(dy=2, opts={})
      puts "JUMPING by #{dy}"
      jump_to_height @body.position[1] + dy, opts
    end
    
    def jump_to_height(y, opts={})
      @start_fly = Time.now
      speed = opts[:speed] || 10
    
      while @body.position[1] <= y
        #puts @client.time_string + " jumping lup=#{@body.last_update_period}"
        wait_for_next_position_update(opts[:update_period])
        @body.position[1] += speed*@body.last_update_period
        if @body.bumped?
          puts "bumped my head!"
          return false
        end
      end
    end
	
    def fall(opts={})
      puts "FALL NOW"
      #@body.debug = true # TMPHAX
      while true
        wait_for_next_position_update(opts[:update_period])
        break if fall_update(opts)
      end
      delay(0.2)
    end
    
    def delay(time)
      # NOTE: we could just do wait_for_next_position_update(time)
      (time/@body.update_period).ceil.times do
        wait_for_next_position_update
      end
    end
    
    def wait_for_next_position_update(next_update_period = nil)
      if next_update_period
        @body.next_update_period = next_update_period
      end
      Fiber.yield
    end
    
    # fly through the air
    def miracle(x, z)
      # TODO: temporarily set the body_update_period to 0.1 for the miracle jump
    
      @start_fly = Time.now
      jump = Jump.new(200)
      waypoint1 = Waypoint.new(Coords[@body.position.x, 290, @body.position.z])
      waypoint2 = Waypoint.new(Coords[x, 260, z])
      jump.speed = 500
      waypoint1.speed = waypoint2.speed = 500

      # TODO: fall at 50 m/s for the miracle jump!
      
      @current_action = MultiAction.new(jump, waypoint1, waypoint2) 
    end
    
    def tmphax_find_path
      @pathfinder.start = @body.position.to_a.collect(&:to_i)
      @pathfinder.bounds = [94..122, 69..78, 233..261]
      @pathfinder.goal = [104, 73, 240]
      puts "Finding path from #{@pathfinder.start} to #{@pathfinder.goal}..."
      result = @pathfinder.find_path
      puts "t: " + result.inspect
    end
    
    def inspect
      to_s
    end
      
    def fall_update(opts={})
      speed = opts[:speed] || 10
      
      #@body.debug = true
    
      ground = find_ground
      
      max_distance = speed*@body.last_update_period
      
      dy = ground - @body.position.y
      if (dy < -max_distance)
        dy = -max_distance
      elsif (dy > max_distance)
        dy = max_distance
      end
      
      @body.position.y += dy
      
      if ((@body.position[1] - ground).abs < 0.2)
        #puts "on ground"
        return true
      end
    end
    
    def find_ground
      x,y,z = @body.position.to_a
      y.ceil.downto(0).each do |test_y|
        #puts "#{x} #{_} #{z} #{@chunk_tracker.block_type([x,_,z])}"
        #TODO: .to_i on x and z might be wrong here
        if (@chunk_tracker.block_type([x.to_i, test_y, z.to_i]).solid?)
          return test_y+1
        end
      end 
    end

    def_delegator :@chunk_tracker, :block_type, :block_type
    def_delegator :@client, :chat, :chat
  end
end