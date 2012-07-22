# ChatMover: a class that converts chat commands into movements,
# so you can tell your bot where to go.  I am open to better name
# suggestions for ChatMover and ChatEvaluator and future chat-listening
# classes.

require "forwardable"
require_relative "packets"

module RedstoneBot
  class ChatMover
    extend Forwardable
  
    attr_accessor :master
     
    def initialize(chatter, body_mover, entity_tracker)
      @chatter = chatter
      @body_mover = body_mover
      @entity_tracker = entity_tracker
      
      @chatter.listen do |p|
        process_chat(p) if p.is_a?(Packet::ChatMessage) && p.player_chat?
      end
    end
    
    def process_chat(p)
      case p.chat
      when /where (.+)/ then
        name = $1
        if name == "u" || name == @chatter.username
          chat "I be at #{position}"
        else
          player = @entity_tracker.player(name)
          if player
            chat "dat guy at #{player.position}"
          else
            chat "dunno who dat '#{name}' is"
          end
        end
      when "stop" then stop
      when "n", "z-" then start_move_to position - Coords::Z
      when "s", "z+" then start_move_to position + Coords::Z
      when "e", "x+" then start_move_to position + Coords::X
      when "w", "x-" then start_move_to position - Coords::X
      when "j" then start_jump
      when "m"
        player = @entity_tracker.player(p.username)
        if player
          x, z = player.position.x, player.position.z
          chat "coming to #{x}, #{z}!"
          start_miracle_jump x, z
        else
          chat "dunno where U r (chat m <X> <Z> to specify)"
        end
      when /m (\-?[\.\d]+) (\-?[\.\d]+)/
        x = $1.to_f
        z = $2.to_f
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
    end
    
    protected
    
    def_delegators :@body_mover, :start_move_to, :start_jump, :start_miracle_jump, :position, :stop
    def_delegators :@chatter, :chat
  end
end