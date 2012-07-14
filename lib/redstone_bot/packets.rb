# need ordered hashes!
raise "Please use Ruby 1.9.3 or later." if RUBY_VERSION < "1.9.3"

module RedstoneBot
  class Packet
    # Associates packet id byte to packet class.
    @packet_types = {}
    
    def self.packet_types
      @packet_types
    end
    
    def self.fields
      @fields
    end
    
    # This is called in subclass definitions.
    def self.packet_type(type)
      @packet_type = type
      Packet.packet_types[type] = self
    end
    
    # This is called in subclass definitions.
    def self.field(name, codec)
      @fields ||= {}
      @fields[name] = codec
    end
    
    def self.string(name)
      field name, :read_string, :string
    end
    
    def self.byte(name)
      field name, :read_byte, :byte
    end
    
    def self.int(name)
      field name, :read_int, :int
    end
    
    def self.long(name)
      field name, :read_long, :long
    end
    
    def self.receive(socket)
      type = socket.read_byte
      packet_class = packet_types[type]
      raise "WHAT'S %02X PRECIOUSSS?" % [type] if packet_class.nil?
      return packet_class.receive_data(socket)
    end
    
    # Only called on a sublass, once the packet type has been received
    def self.receive_data(socket)
      packet = self.new
      fields.each do |field_name, methods|
        read_method_name = methods[0]
        instance_variable_set ("@" + field_name.to_s).to_sym, socket.send(:read_method_name)
      end
    end
    
    # Only called on a subclass
    def write(socket)
      data = self.class.fields.collect do |field_name, methods|
        encode_method_name = methods[1]
        val = instance_variable_get(("@" + field_name.to_s).to_sym)
        socket.string val
        socket.send :string, val
        puts val.inspect
        puts encode_method_name.inspect
        socket.send encode_method_name, val
      end.join
      puts "sending #{self.class.name}: #{data.inspect}"
      socket.write data
    end
  end

  class Packet::LoginRequest < Packet
    packet_type 0x01
    string :username
    string :level_type  # "default" => :default, "SUPERFLAT" => :superflat
    int :server_mode    # 0 => :survival, 1 => :creative
    byte :dimension     # -1 => :nether, 0 => :overworld, 1 => :the_end
    byte :difficulty
    byte :_unused
    byte :max_players
  end
  
  class Packet::Handshake < Packet
    packet_type 0x02
    string :data   # username and host, e.g. Elavid;localhost:25565
    
    def initialize(username, hostname, port)
      @data = "#{username};#{hostname}:#{port}"
    end
  end
  
  # TODO: extract meaningful data from the chat string
  class Packet::ChatMessage < Packet
    packet_type 0x03
    string :data
  end
  
  class Packet::TimeUpdate < Packet
    packet_type 0x04
    long :ticks
  end
end