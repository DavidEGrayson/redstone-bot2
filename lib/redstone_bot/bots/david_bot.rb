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
      
      
      @ce = ChatEvaluator.new(@client, self)      
      @cm = ChatMover.new(@client, self, @entity_tracker)
      
      #@cm.aliases = {"meq" => "m -2570 -2069", "mpl" => "m 100 240"}
      #if defined?(MASTER)
      #  @cm.master = @ce.master = MASTER
      #end
      
      @body.on_position_update do
        if !@body.current_fiber
          fall_update
          @body.look_at @entity_tracker.closest_entity
        end
      end
      
      @pathfinder = Pathfinder.new(@chunk_tracker)
      
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
    
    def inspect
      to_s
    end

    protected
    def_delegators :@chunk_tracker, :block_type
    def_delegators :@client, :chat
  end
end