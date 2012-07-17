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
      
      @ce = ChatEvaluator.new(self, @client)
      
      @body.on_position_update do
        @body.look_at @entity_tracker.closest_entity
      end

      waypoint = [99, 70, 230]
      @body.debug = true
      @body.on_position_update do
        fall
        move_to(waypoint)
      end

      
      @pathfinder = Pathfinder.new(@chunk_tracker)
      
      @client.listen do |p|
        case p
        when :start
          #@client.later(5) do
          #  tmphax_find_path
          #end
        when Packet::ChatMessage
          waypoint[2] -= 1 if p.message == "<RyanTM> n"
          waypoint[2] += 1 if p.message == "<RyanTM> s"
          waypoint[0] += 1 if p.message == "<RyanTM> e"
          waypoint[0] -= 1 if p.message == "<RyanTM> w"
          if p.message == "<RyanTM> h"
            me = @entity_tracker.player("RyanTM")
            puts me.inspect
            waypoint = me.position.to_a
          end
          puts p.inspect
        when Packet::Disconnect
          exit 2
        end
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
        puts "#{x} #{_} #{z} #{@chunk_tracker.block_type([x,_,z])}"
        #TODO: .to_i on x and z might be wrong here
        if (@chunk_tracker.block_type([x.to_i,_,z.to_i]).solid?)
          return _+1
        end
      end 
    end
	
    def fall
      ground = find_ground
      puts "GROUND: #{ground}"
      if (@body.position[1] > ground)
        @body.position -= Vector[0,0.5,0]
        @body.stance = @body.position[1] + 1.62
      end
      if ((@body.position[1] - ground).abs < 0.5)
        @body.position = Vector[@body.position[0],ground,@body.position[2]]
        @body.stance = @body.position[1] + 1.62
      end
    end
	
    def move_to(waypoint)
      speed = 10
      waypoint = Vector[*waypoint] 
      dir = waypoint - @body.position
      dir = Vector[dir[0],0,dir[2]]
      if dir.norm < 0.2
        puts "success"
        return
      end
      
      d = dir.normalize*speed*@body.update_period
      #puts "%7.4f %7.4f %7.4f" % [d[0], d[1], d[2]]
      @body.position += d
      @body.stance = @body.position[1] + 1
      #@body.on_ground = true #false      
    end
    
    def_delegator :@chunk_tracker, :block_type, :block_type
    def_delegator :@client, :chat, :chat
  end
end