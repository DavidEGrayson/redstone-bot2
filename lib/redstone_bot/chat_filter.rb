require "forwardable"
require_relative "packets"

module RedstoneBot
  attr_accessor :master
  
  # TODO: perhaps generalize this to be a subclass of PacketFilter if we ever need to filter other
  # types of packets.
  class ChatFilter
    extend Forwardable
  
    # chatter: Must have .listen, .chat, and .username
    # So the chatter can be a RedstoneBot::Client or RedstoneBot::ChatFilter or some other object. 
    def initialize(chatter)
      @listeners = []
      @filters = []
      @chatter = chatter
      
      @chatter.listen do |p|
        p = p.dup   # Some of the filters might modify the packet, but we don't want to change the original.
        next unless p.is_a?(Packet::ChatMessage)        
        next unless @filters.all? { |f| f.call p }        
        notify_listeners p
      end
    end
        
    def listen(&proc)
      @listeners << proc
    end
    
    def filter(&proc)
      @filters << proc
    end
    
    def_delegators :@chatter, :username, :chat
    
    def modify_chat
      filter do |packet|
        packet.chat = yield packet.chat
        true
      end
    end
    
    def aliases(aliases)
      modify_chat do |str|
        aliases[str] || str
      end
    end
    
    def only_player_chats
      filter { |p| p.player_chat? }
    end
    
    def only_from_user(name)
      raise ArgumentError.new("given username is nil") unless name
      filter { |p| p.username == name }
    end
    
    def reject_from_self
      filter { |p| p.username != username }
    end

    protected
    def notify_listeners(*args)
      @listeners.each do |l|
        l.call(*args)
      end
    end
  end

end