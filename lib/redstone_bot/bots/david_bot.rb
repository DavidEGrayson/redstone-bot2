require 'forwardable'
require 'fiber'

require "redstone_bot/bot"
require "redstone_bot/chat_evaluator"
require "redstone_bot/pathfinder"
require "redstone_bot/body_movers"
require "redstone_bot/chat_filter"
require "redstone_bot/chat_mover"

module RedstoneBot
  module Bots; end

  class Bots::DavidBot < RedstoneBot::Bot
    extend Forwardable
    include BodyMovers
    
    FarmBounds = [(-294..-156), (63..63), (682..797)]
    
    Aliases = {
      "meq" => "m -2570 -2069",
      "mpl" => "m 99.5 225.5",
      "mkn" => "m -211 785",
      }
    
    attr_reader :body, :chunk_tracker
    
    def setup
      standard_setup
      
      @chat_filter = ChatFilter.new(@client)
      @chat_filter.only_player_chats
      @chat_filter.reject_from_self      
      @chat_filter.aliases Aliases
      @chat_filter.only_from_user(MASTER) if defined?(MASTER)
      
      @ce = ChatEvaluator.new(@client, self)      
      @cm = ChatMover.new(@chat_filter, self, @entity_tracker)
      
      @body.on_position_update do
        if !@body.current_fiber
          fall_update
          @body.look_at @entity_tracker.closest_entity
        end
      end
      
      @pathfinder = Pathfinder.new(@chunk_tracker)
      
      @chat_filter.listen do |p|
        next unless p.is_a?(Packet::ChatMessage) && p.player_chat?
        
        case p.chat
        when /d (\-?\d+) (\-?\d+) (\-?\d+)/
          x, y, z = $1.to_i, $2.to_i, $3.to_i
          puts "using #{x},#{y},#{z}!"
          #@client.send_packet Packet::PlayerDigging.new(2, [x, y, z], 0)
          @client.send_packet Packet::PlayerDigging.start [x,y,z]
        end
      end
      
      @client.listen do |p|
        case p
        when Packet::ChatMessage
          puts p
        when Packet::Disconnect
          puts "Position = #{@body.position}"
          exit 2
        end
      end 
      
    end
    
    def miracle_jump(x,z)
      @start_fly = Time.now
      super
      chat "I be at #{@body.position} after #{Time.now - @start_fly} seconds."
    end
    
    def tmphax_find_path
      @pathfinder.start = @body.position.to_a.collect(&:to_i)
      @pathfinder.bounds = [94..122, 69..78, 233..261]
      @pathfinder.goal = [104, 73, 240]
      puts "Finding path from #{@pathfinder.start} to #{@pathfinder.goal}..."
      result = @pathfinder.find_path
      puts "t: " + result.inspect
    end
    
    def standing_on
      coord_array = (@body.position - Coords::Y*0.5).to_a.collect &:floor
      "#{block_type coord_array} #{@body.position.y}->#{coord_array[1]}"
    end
    
    def jump_to_height(*args)
      result = super
      chat "I bumped my head!" if !result
      result
    end
    
    def run_time
      start = Time.now
      yield
      Time.now - start
    end

    protected
    def_delegators :@chunk_tracker, :block_type, :block_metadata
    def_delegators :@client, :chat
  end
end