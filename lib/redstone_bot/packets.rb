# need ordered hashes!
raise "Please use Ruby 1.9.3 or later." if RUBY_VERSION < "1.9.3"

require_relative "pack"
require_relative "slot"
require "zlib"

# TODO: implement the rest of the packets from http://www.wiki.vg/Protocol

# TODO: to be more consistent, change all Coords var names to 'position or 'position_change' if that's what they represent?
# start with the eid-related packets here

# TODO: add LocaleAndViewDistance and see if that lets us get more chunks loaded

class String
  def inspect_hex
     '"' + bytes.collect { |b| '\x%02X' % [b] }.join + '"'
  end
end

module RedstoneBot
  ProtocolVersion = 47
  
  class UnknownPacketError < StandardError
    attr_reader :packet_type

    def initialize(type)
      @packet_type = type
    end
  end
  
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
      raise UnknownPacketError.new(type) if packet_class.nil?
      return packet_class.receive_data(socket)
    end
    
    # Only called on a sublass, once the packet type has been received    
    def self.receive_data(socket)
      p = allocate
      p.receive_data(socket)
      p
    end
    
    def receive_data(socket)
      raise "receive_data instance method or class method not implemented in #{self.class.name}"
    end
    
    # Only called on a subclass
    def encode
      type_byte + encode_data
    end
      
    def encode_data
      raise "encode_data instance method not implemented in #{self.class.name}"      
    end
    
    def type_byte
      byte(self.class.type)
    end
  end

  class Packet::KeepAlive < Packet
    packet_type 0x00
    attr_accessor :id
    
    def initialize(id=0)
      @id = id
    end
    
    def receive_data(socket)
      @id = socket.read_int
    end
    
    def encode_data
      int(id)
    end
  end
  
  class Packet::LoginRequest < Packet
    packet_type 0x01
    attr_reader :eid
    attr_reader :username
    attr_reader :level_type  # "default" => :default, "SUPERFLAT" => :superflat
    attr_reader :server_mode    # 0 => :survival, 1 => :creative
    attr_reader :dimension     # -1 => :nether, 0 => :overworld, 1 => :the_end
    attr_reader :difficulty
    attr_reader :max_players
    
    def initialize(username)
      @username = username
    end
    
    def encode_data
      ""
    end
    
    def receive_data(socket)
      @eid = socket.read_int
      @level_type = socket.read_string
      @server_mode = socket.read_byte
      @dimension = socket.read_signed_byte
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
    
    def initialize(username, hostname, port)
      @username, @hostname, @port = username, hostname, port
    end
    
    def encode_data
      byte(ProtocolVersion) + string(username) + string(hostname) + unsigned_int(port)
    end
    
  end
  
  class Packet::ChatMessage < Packet
    packet_type 0x03
    attr_reader :data, :death_type, :killer_name, :username, :chat
    
    # Source: http://www.wiki.vg/Chat except I left out the funny characters
    # because I'd have to think a little bit more about encodings to make it work
    AllowedChatChars = '!\"#$%&\'`()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_abcdefghijklmnopqrstuvwxyz{|}~| '.split('')
    
    def initialize(data)
      @data = data      
      init_player_chat_info or init_death_info
    end
       
    def receive_data(socket)
      initialize(socket.read_string)
    end
    
    def ==(other)
      other.respond_to?(:data) && @data == other.data
    end
    
    def safe_data
      data.chars.select { |c| AllowedChatChars.include?(c) }[0,100].join
    end
       
    def encode_data
      string(safe_data)
    end

    def to_s
		  "chat: #{self.class.strip_codes(data)}"
    end

    def death?
      !!@death_type
    end
    
    def player_chat?
      !!@chat
    end
    
    # Removes Minecraft color and formatting codes.
    def self.strip_codes(str)
      str.gsub /\u00A7[0-9a-z]/, ''
    end

    def self.player_chat(username, chat)
      p = ChatMessage.allocate
      p.player_chat(username, chat)
      p
    end
    
    def player_chat(username, chat)
      @data = "<#{username}> #{chat}"
      @username = username
      @chat = chat
    end
   
    protected

    def init_player_chat_info
      if data =~ /^<([^>]+)> (.*)/
        @username, @chat = $1, $2
        return true
      end
      return false
    end
    
    def init_death_info
      @death_type = case data
        when /^(.+) drowned$/ then :drowned
        when /^(.+) hit the ground too hard$/ then :hit_ground
        when /^(.+) was slain by (.+)$/ then :slain
        when /^(.+) was shot by (.+)$/ then :shot
        when /^(.+) was killed by (.+)$/ then :killed
        when /^(.+) fell out of the world (.+)$/ then :fell_out
        when /^(.+) tried to swim in lava$/ then :lava
        when /^(.+) went up in flames$/ then :flames
        when /^(.+) burned to death$/ then :burned
        when /^(.+) blew up$/ then :blew_up
        when /^(.+) was fireballed by (.+)$/ then :fireballed
        when /^(.+) was killed by magic$/ then :magic   # suicide
        when /^(.+) suffocated in a wall$/ then :suffocated
        when /^(.+) was pricked to death$/ then :pricked
        when /^(.+) was shot by an arrow$/ then :arrow
        when /^(.+) died$/ then :died
        when /^(.+) didn't have a chance$/ then :no_chance
        when /^([^\s]*)$/ then :unknown
        end
      
      if @death_type
        @username = $1
        @killer_name = $2   # mob or player name
      end
    end  
  end
    
  class Packet::TimeUpdate < Packet
    packet_type 0x04
    attr_reader :time, :day_time
    
    def receive_data(stream)
      @time = stream.read_long
      @day_time = stream.read_long
    end
  end
  
  class Packet::EntityEquipment < Packet
    packet_type 0x05
    attr_reader :eid
    attr_reader :slot_id
    attr_reader :slot
    
    def receive_data(socket)
      @eid = socket.read_int
      @slot_id = socket.read_short
      @slot = Slot.receive_data(socket)
    end
  end
  
  class Packet::SpawnPosition < Packet
    packet_type 0x06
    attr_reader :x, :y, :z
    
    def receive_data(socket)
      @x = socket.read_int
      @y = socket.read_int
      @z = socket.read_int
    end
  end
  
  class Packet::UpdateHealth < Packet
    packet_type 0x08
    attr_reader :health
    attr_reader :food
    attr_reader :food_saturation
    
    def receive_data(socket)
      @health = socket.read_short
      @food = socket.read_short
      @food_saturation = socket.read_float
    end
  end
  
  class Packet::Respawn < Packet
    packet_type 0x09
    attr_reader :dimension
    attr_reader :difficulty
    attr_reader :game_mode
    attr_reader :world_height
    attr_reader :level_type
    
    def receive_data(socket)
      @dimension = socket.read_int
      @difficulty = socket.read_byte
      @game_mode = socket.read_byte
      @world_height = socket.read_short
      @level_type = socket.read_string
    end
    
  end
  
  class Packet::Player < Packet
    packet_type 0x0A
    attr_reader :on_ground
  end
  
  class Packet::PlayerPosition < Packet
    packet_type 0x0B
    attr_reader :x, :y, :z, :stance, :on_ground
  end
  
  class Packet::PlayerLook < Packet
    packet_type 0x0C
    attr_reader :yaw, :pitch, :on_ground
  end
  
  class Packet::PlayerPositionAndLook < Packet
    packet_type 0x0D
    attr_reader :x, :stance, :y, :z, :yaw, :pitch, :on_ground
    
    def initialize(x, y, z, stance, yaw, pitch, on_ground)
      @x, @y, @z = x, y, z
      @stance = stance
      @yaw, @pitch = yaw, pitch
      @on_ground = on_ground
    end
    
    def receive_data(socket)
      @x = socket.read_double
      @stance = socket.read_double
      @y = socket.read_double
      @z = socket.read_double
      @yaw = socket.read_float
      @pitch = socket.read_float
      @on_ground = socket.read_byte
    end
    
    def encode_data
      double(x) + double(y) + double(stance) + double(z) +
      float(yaw) + float(pitch) + bool(on_ground)
    end
    
    def to_s
      "pos: %7.2f %7.2f %7.2f dy=%4.2f g=%d yw=%6.2f pt=%6.2f" % ([x, y, z, stance - y, on_ground ? 1 : 0, yaw, pitch])
    end
  end
  
  class Packet::PlayerDigging < Packet
    packet_type 0x0E
    attr_reader :status, :x, :y, :z, :face
    
    # defaults for dropping items where only the status matters
    def initialize(status, intcoords=[0,0,0], face=0)
      @status = status
      @x, @y, @z = intcoords.to_a
      @face = face
    end
    
    def encode_data
      byte(status) + int(x) + byte(y) + int(z) + byte(face)
    end
    
    def self.done(intcoords, face=0)
      new 2, intcoords, face
    end
    
    def self.start(intcoords, face=0)
      new 0, intcoords, face
    end
    
    def self.drop
      new 4
    end
  end
  
  class Packet::PlayerBlockPlacement < Packet
    packet_type 0x0F
    
    attr_reader :coords, :direction, :held_item, :cursor_x, :cursor_y, :cursor_z
    
    def initialize(coords, direction, held_item, cursor_x=8, cursor_y=8, cursor_z=8)
      @coords = coords
      @direction = direction
      @held_item = held_item
      @cursor_x, @cursor_y, @cursor_z = cursor_x, cursor_y, cursor_z
    end
    
    def encode_data
      int(coords[0]) + byte(coords[1]) + int(coords[2]) + byte(direction) +
        Slot.encode_data(held_item) + byte(cursor_x) + byte(cursor_y) + byte(cursor_z)
    end
  end
  
  class Packet::HeldItemChange < Packet
    packet_type 0x10
    attr_reader :slot_id
    
    def initialize(slot_id)
      @slot_id = slot_id
    end

    def ==(other)
      other.respond_to?(:slot_id) && @slot_id == other.slot_id
    end

    def encode_data
      unsigned_short(@slot_id)
    end
  end
  
  class Packet::UseBed < Packet
    packet_type 0x11
    attr_reader :eid
    attr_reader :x, :y, :z
    
    def coords
      Coords[@x, @y, @z]
    end
    
    def receive_data(socket)
      @eid = socket.read_int
      socket.read_byte
      @x = socket.read_int
      @y = socket.read_byte
      @z = socket.read_int
    end
  end
  
  class Packet::Animation < Packet
    packet_type 0x12
    attr_reader :eid
    attr_reader :animation
  
    def initialize(eid, animation)
      @eid = eid
      @animation = animation
    end
    
    def encode_data
      int(eid) + byte(animation)
    end
  
    def receive_data(socket)
      @eid = socket.read_int
      @animation = socket.read_byte
    end
  end
  
  class Packet::SpawnNamedEntity < Packet
    packet_type 0x14
    attr_reader :eid
    attr_reader :player_name
    attr_reader :x, :y, :z
    attr_reader :yaw, :pitch
    attr_reader :current_item
    attr_reader :metadata
    
    def coords
      Coords[@x, @y, @z]
    end
    
    def receive_data(socket)
      @eid = socket.read_int
      @player_name = socket.read_string
      @x = socket.read_int/32.0
      @y = socket.read_int/32.0
      @z = socket.read_int/32.0
      @yaw = socket.read_signed_byte
      @pitch = socket.read_signed_byte
      @current_item = socket.read_short
      @metadata = socket.read_metadata
    end
  end
  
  class Packet::SpawnDroppedItem < Packet
    packet_type 0x15
    attr_reader :eid
    attr_reader :slot
    attr_reader :x, :y, :z
    attr_reader :yaw, :pitch, :roll
    
    def coords
      Coords[@x, @y, @z]
    end
        
    def receive_data(stream)
      @eid = stream.read_int
      @slot = stream.read_slot
      @x = stream.read_int/32.0
      @y = stream.read_int/32.0
      @z = stream.read_int/32.0
      @yaw = stream.read_signed_byte
      @pitch = stream.read_signed_byte
      @roll = stream.read_signed_byte
    end
    
    def to_s
      "SpawnDroppedItem(#{eid}, #{item_type}, #{count}, #{metadata.inspect}, #{coords}, yw=#{yaw}, pt=#{pitch}, rl=#{roll})"
    end
  end
  
  class Packet::CollectItem < Packet
    packet_type 0x16
    attr_reader :collected_eid
    attr_reader :collector_eid
    
    def receive_data(socket)
      @collected_eid = socket.read_int
      @collector_eid = socket.read_int 
    end
  end
  
  class Packet::SpawnObject < Packet  # includes vehicles
    packet_type 0x17
    attr_reader :eid
    attr_reader :type
    attr_reader :x, :y, :z
    attr_reader :thrower_eid
    attr_reader :speed_x, :speed_y, :speed_z
  
    def coords
      Coords[@x, @y, @z]
    end
  
    def receive_data(socket)
      @eid = socket.read_int
      @type = socket.read_byte
      @x = socket.read_int/32.0
      @y = socket.read_int/32.0
      @z = socket.read_int/32.0
      @thrower_eid = socket.read_int
      if @thrower_eid != 0
        @speed_x = socket.read_short
        @speed_y = socket.read_short
        @speed_z = socket.read_short
      end
    end
  end
  
  class Packet::SpawnMob < Packet
    packet_type 0x18
    attr_reader :eid
    attr_reader :type
    attr_reader :x, :y, :z
    attr_reader :yaw, :pitch, :head_yaw
    attr_reader :vx, :vy, :vz
    attr_reader :metadata
    
    def coords
      Coords[@x, @y, @z]
    end
    
    def receive_data(socket)
      @eid = socket.read_int
      @type = socket.read_byte
      @x = socket.read_int/32.0
      @y = socket.read_int/32.0
      @z = socket.read_int/32.0
      @yaw = socket.read_signed_byte
      @pitch = socket.read_signed_byte
      @head_yaw = socket.read_signed_byte
      @vz = socket.read_short   # TODO: is the velocity REALLY in Z,X,Y order?
      @vx = socket.read_short
      @vy = socket.read_short
      @metadata = socket.read_metadata
    end
  end
  
  class Packet::SpawnPainting < Packet
    packet_type 0x19
    attr_reader :eid
    attr_reader :title
    attr_reader :x, :y, :z
    attr_reader :direction
    
    def receive_data(socket)
      @eid = socket.read_int
      @title = socket.read_string
      @x = socket.read_int
      @y = socket.read_int
      @z = socket.read_int
      @direction = socket.read_int
    end
  end
  
  class Packet::ExperienceOrb < Packet
    packet_type 0x1A
    attr_reader :eid
    attr_reader :x, :y, :z
    attr_reader :count
    
    def coords
      Coords[@x, @y, @z]
    end
    
    def receive_data(socket)
      @eid = socket.read_int
      @x = socket.read_int/32.0
      @y = socket.read_int/32.0
      @z = socket.read_int/32.0
      @count = socket.read_short
    end
  end
  
  class Packet::EntityVelocity < Packet
    packet_type 0x1C
    attr_reader :eid
    attr_reader :vx, :vy, :vz
    
    def velocity
      Coords[@vx, @vy, @vz]
    end
    
    def receive_data(socket)
      @eid = socket.read_int
      @vx = socket.read_short
      @vy = socket.read_short
      @vz = socket.read_short
    end
    
    def to_s
      "EntityVelocity(#{eid}, #{velocity})"      
    end
  end
  
  class Packet::DestroyEntity < Packet
    packet_type 0x1D
    attr_reader :eids
    
    def receive_data(socket)
      count = socket.read_byte
      @eids = count.times.collect { socket.read_int }
    end
  end
  
  class Packet::EntityRelativeMove < Packet
    packet_type 0x1F
    attr_reader :eid, :dx, :dy, :dz
    
    def coords_change
      Coords[@dx, @dy, @dz]
    end
    
    def receive_data(socket)
      @eid = socket.read_int
      @dx = socket.read_signed_byte/32.0
      @dy = socket.read_signed_byte/32.0
      @dz = socket.read_signed_byte/32.0
    end
    
    def to_s
      "EntityRelativeMove(#{eid}, #{coords_change})"
    end
  end
  
  class Packet::EntityLook < Packet
    packet_type 0x20
    attr_reader :eid
    attr_reader :yaw, :pitch
    
    def receive_data(socket)
      @eid = socket.read_int
      @yaw = socket.read_signed_byte
      @pitch = socket.read_signed_byte
    end
  end
  
  class Packet::EntityLookAndRelativeMove < Packet
    packet_type 0x21
    attr_reader :eid
    attr_reader :dx, :dy, :dz
    attr_reader :yaw, :pitch
    
    def coords_change
      Coords[@dx, @dy, @dz]
    end
    
    def receive_data(socket)
      @eid = socket.read_int
      @dx = socket.read_signed_byte/32.0
      @dy = socket.read_signed_byte/32.0
      @dz = socket.read_signed_byte/32.0
      @yaw = socket.read_signed_byte
      @pitch = socket.read_signed_byte
    end
  end
  
  class Packet::EntityTeleport < Packet
    packet_type 0x22
    attr_reader :eid
    attr_reader :x, :y, :z
    attr_reader :yaw, :pitch
    
    def coords
      Coords[@x, @y, @z]
    end
    
    def receive_data(socket)
      @eid = socket.read_int
      @x = socket.read_int/32.0
      @y = socket.read_int/32.0
      @z = socket.read_int/32.0
      @yaw = socket.read_signed_byte
      @pitch = socket.read_signed_byte
    end
    
    def to_s
      "EntityTeleport(#{eid}, #{coords}, yw=#{yaw}, pt=#{pitch})"
    end
  end
  
  class Packet::EntityHeadLook < Packet
    packet_type 0x23
    attr_reader :eid
    attr_reader :head_yaw
    
    def receive_data(socket)
      @eid = socket.read_int
      @head_yaw = socket.read_signed_byte
    end
  end
  
  class Packet::EntityStatus < Packet
    packet_type 0x26
    attr_reader :eid
    attr_reader :status
    
    def receive_data(socket)
      @eid = socket.read_int
      @status = socket.read_byte
    end
  end
  
  class Packet::AttachEntity < Packet
    packet_type 0x27
    attr_reader :eid
    attr_reader :vehicle_eid
    
    def receive_data(socket)
      @eid = socket.read_int
      @vehicle_eid = socket.read_int
    end
  end
  
  class Packet::EntityMetadata < Packet
    packet_type 0x28
    attr_reader :eid
    attr_reader :metadata
    
    def receive_data(stream)
      @eid = stream.read_int
      @metadata = stream.read_metadata
    end
  end
  
  class Packet::EntityEffect < Packet
    packet_type 0x29
    attr_reader :eid, :effect_id, :amplifier, :duration
    
    def receive_data(stream)
      @eid = stream.read_int
      @effect_id = stream.read_byte
      @amplifier = stream.read_byte
      @duration = stream.read_unsigned_short
    end
  end
  
  class Packet::SetExperience < Packet
    packet_type 0x2B
    attr_reader :experience_bar, :level, :total_experience
    
    def receive_data(socket)
      @experience_bar = socket.read_float
      @level = socket.read_short
      @total_experience = socket.read_short
    end
  end
  
  class Packet::ChunkData < Packet
    packet_type 0x33
    attr_reader :ground_up_continuous
    attr_reader :primary_bit_map, :add_bit_map
    attr_reader :data
    
    def chunk_id
      [@x, @z]
    end
    
    def receive_data(socket)
      @x = socket.read_int*16
      @z = socket.read_int*16
      @ground_up_continuous = socket.read_bool
      @primary_bit_map = socket.read_unsigned_short
      @add_bit_map = socket.read_unsigned_short
      compressed_size = socket.read_int
      compressed_data = socket.read(compressed_size)
      @data = Zlib::Inflate.inflate compressed_data
    end
    
    # Avoid showing all the data when we inspect this packet.
    def inspect
      tmp = @data
      begin
        @data = nil
        @data_summary = ("#{tmp.size},#{tmp[0,256]}" if tmp)
        return super
      ensure
        @data = tmp
        @data_summary = nil
      end
    end

    def deallocation?
      ground_up_continuous && primary_bit_map == 0 && add_bit_map == 0
    end
  end
  
  class Packet::MultiBlockChange < Packet
    packet_type 0x34
    attr_reader :count
    attr_reader :data
    
    def chunk_id
      [@x, @z]
    end
    
    def receive_data(socket)
      @x = socket.read_int*16
      @z = socket.read_int*16
      @count = socket.read_unsigned_short
      @data = socket.read(socket.read_unsigned_int)
    end
    
    def each
      (0...@data.length).step(4) do |i|
        data = @data[i,4]
        bytes = data.bytes.to_a
        z = bytes[0] & 0x0F
        x = (bytes[0] >> 4) & 0x0F
        y = bytes[1]
        block_type_id = (bytes[2]<<4) | ((bytes[3]&0xF0)>>4)
        metadata = bytes[3] & 0xF
        yield [x, y, z], block_type_id, metadata
      end
    end
    
  end
  
  class Packet::BlockChange < Packet
    packet_type 0x35
    attr_reader :x, :y, :z
    attr_reader :block_type, :block_metadata
    
    alias :block_type_id :block_type 
       
    def chunk_id
      [x/16*16, z/16*16]
    end
    
    def receive_data(socket)
      @x = socket.read_int
      @y = socket.read_byte
      @z = socket.read_int
      @block_type = socket.read_unsigned_short
      @block_metadata = socket.read_byte
    end
    
  end
  
  class Packet::BlockAction < Packet
    packet_type 0x36
    attr_reader :x, :y, :z
    attr_reader :data_bytes, :block_id
    
    def chunk_id
      [@x/16*16, @z/16*16]
    end
    
    def receive_data(socket)
      @x = socket.read_int
      @y = socket.read_short
      @z = socket.read_int
      @data_bytes = [socket.read_byte, socket.read_byte]
      @block_id = socket.read_unsigned_short
    end
    
    def item_type
      ItemType.from_id @block_id
    end
    
    # Only valid for chests
    def open?
      @data_bytes[1] != 0
    end
    
    # Only valid for pistons.  Says if the piston is pushing or pulling.
    def pull?
      @data_bytes[1] != 0
    end
    
    # Only valid for noteblocks/
    def instrument
      [:harp, :double_bass, :snare_drum, :clicks, :bass][@data_bytes[0]] || :unknown
    end
    
    # Only valid for noteblocks.
    def pitch
      @data_bytes[1]
    end
    
    def to_s
      case item_type
      when ItemType::Piston
        "piston #{pull? ? 'pull' : 'push'}: (#{x}, #{y}, #{z})"
      when ItemType::Chest
        "chest #{open? ? 'open' : 'close'}: (#{x},#{y},#{z})"
      when ItemType::NoteBlock
        "note: (#{x},#{y},#{z}) instrument=#{instrument}, pitch=#{pitch}"
      else
        inspect
      end
    end
  end
  
  class Packet::BlockBreakAnimation < Packet
    packet_type 0x37
    attr_reader :eid, :coords
    
    def receive_data(stream)
      @eid = stream.read_int   # TODO: is this really an EID?
      @coords = Coords[stream.read_int, stream.read_int, stream.read_int]
      stream.read_byte    # TODO: what is this byte?
    end
  end
  
  class Packet::MapChunkBulk < Packet
    packet_type 0x38
    
    attr_reader :data, :metadata
    
    def receive_data(stream)
      chunk_column_count = stream.read_unsigned_short
      data_size = stream.read_unsigned_int
      @data = Zlib::Inflate.inflate stream.read(data_size)
      @metadata = chunk_column_count.times.collect do
        chunk_id = [stream.read_int*16, stream.read_int*16]
        primary_bit_map = stream.read_unsigned_short
        add_bit_map = stream.read_unsigned_short
        raise "Unexpected: MapChunkBulk has a non-zero add_bit_map. what does this mean?" if add_bit_map != 0
        [chunk_id, primary_bit_map, add_bit_map]
      end
    end
    
    def to_s
      "MapChunkBulk<@metadata=#{@metadata.inspect} @data.size=#{@data.size}>"
    end
  end
  
  class Packet::Explosion < Packet
    packet_type 0x3C
    attr_reader :x, :y, :z
    attr_reader :radius_maybe, :records
    
    def receive_data(socket)
      @x = socket.read_double
      @y = socket.read_double
      @z = socket.read_double
      @radius_maybe = socket.read_float
      count = socket.read_int
      @records = count.times.collect do
        [socket.read_signed_byte, socket.read_signed_byte, socket.read_signed_byte]
      end
      socket.read_float  #unknown
      socket.read_float  #unknown
      socket.read_float  #unknown
    end
  end
  
  class Packet::SoundOrParticleEffect < Packet
    packet_type 0x3D
    attr_reader :effect_id, :x, :y, :z, :data, :no_volume_decrease
    
    def receive_data(stream)
      @effect_id = stream.read_int
      @x = stream.read_int
      @y = stream.read_byte
      @z = stream.read_int
      @data = stream.read_int
      @no_volume_decrease = stream.read_bool
    end
  end
  
  class Packet::NamedSoundEffect < Packet
    packet_type 0x3E
    
    attr_reader :name, :coords, :volume, :pitch
    
    def receive_data(socket)
      @name = socket.read_string
      @coords = Coords[socket.read_int/8.0, socket.read_int/8.0, socket.read_int/8.0]
      @volume = socket.read_float
      @pitch = socket.read_byte
    end
  end
  
  class Packet::ChangeGameState < Packet
    packet_type 0x46
    attr_reader :reason, :game_mode
    
    def receive_data(socket)
      @reason = socket.read_byte
      @game_mode = socket.read_byte
    end
  end
  
  class Packet::Thunderbolt < Packet
    packet_type 0x47
    attr_accessor :eid, :x, :y, :z
    
    def coords
      Coords[@x, @y, @z]
    end
    
    def receive_data(socket)
      @eid = socket.read_int
      socket.read_byte
      @x = socket.read_int/32.0
      @y = socket.read_int/32.0
      @z = socket.read_int/32.0
    end
  end
  
  class Packet::OpenWindow < Packet
    packet_type 0x64
    
    attr_accessor :window_id, :type, :title, :slot_count
    
    def receive_data(stream)
      @window_id = stream.read_byte
      @type = stream.read_byte
      @title = stream.read_string
      @slot_count = stream.read_byte
    end
  end
  
  class Packet::CloseWindow < Packet
    packet_type 0x65
    
    attr_accessor :window_id
    
    def receive_data(stream)
      @window_id = stream.read_byte
    end
  end
  
  class Packet::ClickWindow < Packet
    packet_type 0x66

    # TODO: clean up the interface of this packet, it's weird
    # To send a middle click, set @shift to 2 and @right_click to 3.    
    
    attr_reader :window_id, :slot_id, :right_click, :action_number, :shift, :clicked_item
    
    def initialize(window_id, slot_id, right_click, action_number, shift, clicked_item)
      @window_id = window_id
      @slot_id = slot_id
      @right_click = right_click
      @action_number = action_number
      @shift = shift
      @clicked_item = clicked_item
    end
    
    def self.outside(transaction_id)
      new 0, -999, false, transaction_id, false, nil
    end
    
    def encode_data
      byte(window_id) + short(slot_id) + byte(right_click) + unsigned_short(action_number) + unsigned_byte(shift) + Slot.encode_data(clicked_item)
    end
  end
  
  class Packet::SetSlot < Packet
    packet_type 0x67
    attr_reader :window_id, :slot_id, :slot
    
    def receive_data(socket)
      @window_id = socket.read_signed_byte
      @slot_id = socket.read_short
      @slot = Slot.receive_data(socket)
    end
    
    # This packet is for the item attached to the cursor.
    def cursor?
      window_id == -1 && slot.nil?
    end
    
    def inspect
      "SetSlot(window=#{window_id}, slot_id=#{slot_id}, #{slot.inspect})"
    end
  end
  
  class Packet::SetWindowItems < Packet
    packet_type 0x68
    attr_reader :window_id, :slots
    
    def receive_data(socket)
      @window_id = socket.read_byte
      count = socket.read_short
      @slots = count.times.collect do
        Slot.receive_data(socket)
      end
    end
    
    def inspect
      "SetWindowItems(#{window_id}, #{slots.inspect})"
    end
  end
  
  class Packet::UpdateWindowProperty < Packet
    packet_type 0x69
    attr_reader :window_id, :property, :value
    
    def receive_data(socket)
      @window_id = socket.read_byte
      @property = socket.read_unsigned_short
      @value = socket.read_unsigned_short
    end
  end
  
  class Packet::ConfirmTransaction < Packet
    packet_type 0x6A
    attr_reader :window_id, :action_number, :accepted
    
    def initialize(window_id, action_number, accepted)
      @window_id = window_id
      @action_number = action_number
      @accepted = accepted
    end
    
    def receive_data(socket)
      @window_id = socket.read_byte
      @action_number = socket.read_unsigned_short
      @accepted = socket.read_bool
    end
    
    def encode_data
      byte(window_id) + unsigned_short(action_number) + bool(accepted)
    end
  end
  
  class Packet::UpdateSign < Packet
    packet_type 0x82
    attr_reader :x, :y, :z
    attr_reader :text
    
    def receive_data(socket)
      @x = socket.read_int
      @y = socket.read_short
      @z = socket.read_int
      @text = 4.times.collect { socket.read_string }.join("\n")
    end
  end
  
  class Packet::UpdateTileEntity < Packet
    packet_type 0x84
    attr_reader :x, :y, :z
    attr_reader :action, :nbt_data
    
    def receive_data(socket)
      @x = socket.read_int
      @y = socket.read_short
      @z = socket.read_int
      @action = socket.read_byte
      @nbt_data = socket.read_byte_array
    end
  end
  
  class Packet::IncrementStatistic < Packet
    packet_type 0xC8
    attr_reader :statistic_id, :amount
    
    def receive_data(socket)
      @statistic_id = socket.read_int
      @amount = socket.read_signed_byte
    end
  end
  
  class Packet::PlayerListItem < Packet
    packet_type 0xC9
    attr_reader :player_name, :online, :ping
    
    def receive_data(socket)
      @player_name = socket.read_string
      @online = socket.read_byte
      @ping = socket.read_short
    end
  end
  
  class Packet::PlayerAbilities < Packet
    packet_type 0xCA
    
    attr_reader :flags
    attr_reader :flying_speed
    attr_reader :walking_speed
    
    def receive_data(socket)
      @flags = socket.read_byte
      @flying_speed = socket.read_byte
      @walking_speed = socket.read_byte
    end
    
    def damage_disabled?
      (flags & 1) != 0
    end
    
    def flying?
      (flags & 2) != 0
    end

    def can_fly?
      (flags & 4) != 0
    end

    def creative_mode?
      (flags & 8) != 0
    end    
  end
  
  class Packet::ClientSettings < Packet  # AKA Locale and View Distance
    packet_type 0xCC
    
    attr_reader :locale, :view_distance, :chat_mode, :colors_enabled, :difficulty, :show_cape
    
    def initialize(locale, view_distance, chat_mode, colors_enabled, difficulty, show_cape)
      @locale = locale
      @view_distance = view_distance
      @chat_mode = chat_mode
      @colors_enabled = colors_enabled
      @difficulty = difficulty
      @show_cape = show_cape
    end
    
    def encode_data
      string(locale) +
        byte([:far, :normal, :short, :tiny].index view_distance) +
        byte([:enabled, :commands_only, :hidden].index(chat_mode) | (colors_enabled ? 8 : 0)) +
        byte(difficulty) +
        bool(show_cape)
    end

  end
  
  class Packet::ClientStatuses < Packet
    packet_type 0xCD
    
    # Bit field. 0: Initial spawn, 1: Respawn after death
    attr_reader :payload
    
    def initialize(payload)
      @payload = payload
    end
    
    def self.initial_spawn
      new(0)
    end
    
    def self.respawn
      new(1)
    end
    
    def encode_data
      byte(payload)
    end
  end
  
  class Packet::PluginMessage < Packet
    packet_type 0xFA
    attr_reader :channel, :data
    
    def receive_data(socket)
      @channel = socket.read_string
      length = socket.read_short
      @data = socket.read(length)
    end
  end
  
  class Packet::EncryptionKeyResponse < Packet
    packet_type 0xFC
    
    attr_reader :shared_secret, :verify_token_response
    
    def initialize(shared_secret, verify_token_response)
      @shared_secret = shared_secret
      @verify_token_response = verify_token_response
    end
    
    def encode_data
      byte_array(shared_secret) + byte_array(verify_token_response)
    end
    
    def receive_data(socket)
      @shared_secret = socket.read_byte_array
      @verify_token_response = socket.read_byte_array
    end
  end
  
  class Packet::EncryptionKeyRequest < Packet
    packet_type 0xFD

    attr_reader :connection_hash, :public_key, :verify_token    
    alias :server_id :connection_hash
    
    def receive_data(socket)
      @connection_hash = socket.read_string
      
      @public_key = socket.read_byte_array
      @verify_token = socket.read_byte_array
    end
  end
  
  class Packet::Disconnect < Packet
    packet_type 0xFF
    attr_reader :reason
    
    def receive_data(socket)
      @reason = socket.read_string
    end
  end

  
end