require "redstone_bot/bot"
require "redstone_bot/chat_evaluator"
require 'forwardable'
require "redstone_bot/pathfinder"

module RedstoneBot
  module Bots; end

  class Bots::DavidBot < RedstoneBot::Bot
    extend Forwardable
    
    def setup
      standard_setup
      
      #@body.debug = true
      
      @ce = ChatEvaluator.new(self, @client)
      
      @body.on_position_update do
        @body.look_at @entity_tracker.closest_entity
      end

      @waypoint = nil
      @body.on_position_update do
        if @waypoint
          move_to_waypoint
        else
          fall
        end
        @body.stance = @body.position[1] + 1.62   # TODO: let @body handle setting stance correctly
      end

      
      @pathfinder = Pathfinder.new(@chunk_tracker)
      
      @client.listen do |p|
        case p
        when Packet::UserChatMessage
          case p.contents
            when "stop" then @waypoint = nil
            when "n", "z-" then @waypoint = [@body.position[0], @body.position[1], @body.position[2] - 1]
            when "s", "z+" then @waypoint = [@body.position[0], @body.position[1], @body.position[2] + 1]
            when "e", "x+" then @waypoint = [@body.position[0] + 1, @body.position[1], @body.position[2]]
            when "w", "x-" then @waypoint = [@body.position[0] - 1, @body.position[1], @body.position[2]]
            when "j" then @waypoint = [@body.position[0], @body.position[1]+5, @body.position[2]]
            when "h"
              player = @entity_tracker.player(p.username)
              if player
                chat "coming!"
                @waypoint = player.position.to_a
              else
                chat "dunno where U r"
              end
            end
        when Packet::Disconnect
          exit 2
        end
        
        puts p.inspect if p.is_a?(Packet::ChatMessage)
      end 
      
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
      y.ceil.downto(0).each do |_|
        #puts "#{x} #{_} #{z} #{@chunk_tracker.block_type([x,_,z])}"
        #TODO: .to_i on x and z might be wrong here
        if (@chunk_tracker.block_type([x.to_i,_,z.to_i]).solid?)
          return _+1
        end
      end 
    end
	
    def fall
      ground = find_ground
      #puts "GROUND: #{ground}"
      if (@body.position[1] > ground)
        @body.position -= Vector[0,0.5,0]
      end
      if ((@body.position[1] - ground).abs < 0.5)
        @body.position = Vector[@body.position[0],ground,@body.position[2]]
      end
    end
	
    def move_to_waypoint
      speed = 10
      waypoint_vector = Vector[*@waypoint] 
      dir = waypoint_vector - @body.position
      if dir.norm < 0.2
        @waypoint = nil  # reached it
        return
      end
      
      d = dir.normalize*speed*@body.update_period
      #puts "%7.4f %7.4f %7.4f" % [d[0], d[1], d[2]]
      @body.position += d
      #@body.on_ground = true #false      
    end
    
    def_delegator :@chunk_tracker, :block_type, :block_type
    def_delegator :@client, :chat, :chat
  end
end