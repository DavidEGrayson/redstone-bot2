require 'forwardable'
require 'fiber'

require "redstone_bot/bot"
require "redstone_bot/chat_evaluator"
require "redstone_bot/pathfinder"
require "redstone_bot/body_movers"

module RedstoneBot
  module Bots; end

  class Bots::DavidBot < RedstoneBot::Bot
    extend Forwardable
    include BodyMovers
    
    attr_reader :body, :chunk_tracker
    
    def setup
      standard_setup
      
      @body.update_period = 0.05
      #@body.debug = true
      
      @ce = ChatEvaluator.new(self, @client)
      @ce.master = MASTER if defined?(MASTER)
      
      @body.on_position_update do
        if @current_fiber
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
      
      aliases = {"meq" => "m -2570 -2069", "mpl" => "m 100 240"}
      
      @client.listen do |p|
        case p
        when Packet::ChatMessage
          puts p
          next if !p.player_chat? || (defined?(MASTER) && p.username != MASTER)
          chat = aliases[p.chat] || p.chat
          case chat
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
            when "stop" then @current_fiber = nil
            when "n", "z-" then start_move_to @body.position - Coords::Z
            when "s", "z+" then start_move_to @body.position + Coords::Z
            when "e", "x+" then start_move_to @body.position + Coords::X
            when "w", "x-" then start_move_to @body.position - Coords::X
            when "j" then start_jump 5
            when "m"
              player = @entity_tracker.player(p.username)
              if player
                x, z = player.position.x, player.position.z
                chat "coming to #{x}, #{z}!"
                start_miracle_jump x, z
              else
                chat "dunno where U r (chat m <X> <Z> to specify)"
              end
            when /m (\-?\d+) (\-?\d+)/
              x = $1.to_i
              z = $2.to_i
              chat "coming to #{x}, #{z}!"
              start_miracle_jump x, z
            when "h"
              player = @entity_tracker.player(p.username)
              if player
                chat "coming!"
                start_move_to player.position + Coords::Y*0.2
              else
                chat "dunno where U r"
              end
            end
        when Packet::Disconnect
          puts "Position = #{@body.position}"
          exit 2
        end
      end 
      
    end
    
    def start_miracle_jump(x,z)
      start_fiber do
        @start_fly = Time.now
        miracle_jump x, z
        chat "I be at #{@body.position} after #{Time.now - @start_fly} seconds."
      end
    end
    
    def start_fiber(&proc)
      @current_fiber = proc
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

    def_delegator :@chunk_tracker, :block_type, :block_type
    def_delegator :@client, :chat, :chat
  end
end