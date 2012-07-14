# need ordered hashes!
raise "Please use Ruby 1.9.3 or later." if RUBY_VERSION < "1.9.3"

require "redstone_bot/pack"

module RedstoneBot
  ProtocolVersion = 29

  class Packet
    include DataEncoder
  
    # Associates packet id byte to packet class.
    @packet_types = {}
    
    def self.packet_types
      @packet_types
    end
    
    # This is called in subclass definitions.
    def self.packet_type(type)
      @packet_type = type
      Packet.packet_types[type] = self
    end
    
    def self.type
      @packet_type
    end

    def self.receive(socket)
      type = socket.read_byte
      packet_class = packet_types[type]
      raise "WHAT'S %02X PRECIOUSSS?" % [type] if packet_class.nil?
      return packet_class.receive_data(socket)
    end
    
    # Only called on a sublass, once the packet type has been received    
    def self.receive_data(socket)
      p = allocate
      p.receive_data(socket)
      p
    end
    
    def receive_data(socket)
      raise "receive_data instance method or class method must be implemented in #{self.name}"
    end
    
    # Only called on a subclass
    def write(socket)
      raise "receive_data must be implemented in #{self.name}"      
    end
    
    def type_byte
      byte(self.class.type)
    end
  end

  class Packet::LoginRequest < Packet
    packet_type 0x01
    attr_reader :entity_id
    attr_reader :username
    attr_reader :level_type  # "default" => :default, "SUPERFLAT" => :superflat
    attr_reader :server_mode    # 0 => :survival, 1 => :creative
    attr_reader :dimension     # -1 => :nether, 0 => :overworld, 1 => :the_end
    attr_reader :difficulty
    attr_reader :max_players
    
    def initialize(username)
      @username = username
    end
    
    def encode
      type_byte + 
        int(ProtocolVersion) +
        string(username) +
        string("") +
        int(0)*2 +
        byte(0)*3
    end
    
    def receive_data(socket)
      @entity_id = socket.read_int
      @level_type = socket.read_string
      @game_mode = socket.read_int
      @dimension = socket.read_int
      @difficulty = socket.read_byte
      socket.read_byte  # was previously world height
      @max_players = socket.read_byte
    end
  end
  
  class Packet::Handshake < Packet
    packet_type 0x02
    attr_reader :username
    attr_reader :hostname
    attr_reader :port
    
    attr_reader :connection_hash
    
    def initialize(username, hostname, port)
      @username, @hostname, @port = username, hostname, port
    end
    
    def encode
      type_byte + string("#{username};#{hostname}:#{port}")
    end
    
    def receive_data(socket)
      @connection_hash = socket.read_string
    end
  end
  
  # TODO: extract meaningful data from the chat string and make many subclasses of ChatMessage
  class Packet::ChatMessage < Packet
    packet_type 0x03
    attr_reader :data
  end
  
  class Packet::TimeUpdate < Packet
    packet_type 0x04
    attr_reader :ticks
  end
end