require "redstone_bot/bot"
require "redstone_bot/chat_evaluator"
require 'forwardable'
require "redstone_bot/pathfinder"
require "redstone_bot/waypoint"
require "redstone_bot/jump"
require "redstone_bot/multi_action"

module RedstoneBot
  module Bots; end

  class Bots::DavidBot < RedstoneBot::Bot
    extend Forwardable
    
    def setup
      standard_setup
      
      @body.update_period = 0.01
      #@body.debug = true
      
      @ce = ChatEvaluator.new(self, @client)
      @ce.master = MASTER if defined?(MASTER)
      
      @current_action = nil
      
      @body.on_position_update do
        if @current_action
          @current_action.start(@body) unless @current_action.started?
          @current_action.update_position(@body)
          @current_action = nil if @current_action.done?
        else
          fall
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
                miracle x, z
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
            end
        when Packet::Disconnect
          puts "Fly time = #{Time.now-@start_fly}" if @start_fly
          exit 2
        end        
      end 
      
    end

    # fly through the air
    def miracle(x, z)
      @start_fly = Time.now
      jump = Jump.new(200)
      waypoint1 = Waypoint.new(Coords[@body.position.x, 290, @body.position.z])
      waypoint2 = Waypoint.new(Coords[x, 260, z])
      jump.speed = 500
      waypoint1.speed = waypoint2.speed = 500

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
	
    def fall
      ground = find_ground
      if (@body.position[1] > ground)
        @body.position -= Coords[0,0.5,0]
      end
      if ((@body.position[1] - ground).abs < 0.5)
        @body.position = Coords[@body.position[0],ground,@body.position[2]]
      end
    end

    def_delegator :@chunk_tracker, :block_type, :block_type
    def_delegator :@client, :chat, :chat
  end
end