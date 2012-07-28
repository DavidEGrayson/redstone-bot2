# need ordered hashes!
raise "Please use Ruby 1.9.3 or later." if RUBY_VERSION < "1.9.3"

require_relative "pack"
require_relative "inventory_item"
require "zlib"

# TODO: to be more consistent, change all Coords var names to 'position or 'position_change' if that's what they represent?
# start with the eid-related packets here

class String
  def hexpect
    bytes.collect { |b| "%02X" % [b]}.join(" ")
  end
  
  def try_zlib
    puts "Unknown = #{hexpect}"
    (0..size).each do |i|
      begin
        portion = self[i, 200]
        inflated = Zlib::Inflate.inflate portion
        puts "inflated #{i} = #{inflated.hexpect}"
      rescue
      end
    end
  end
  
  # takes a hex string where bytes are separated by colons
  def self.from_hex(hex_string)
    hex_string.split(":").collect do |h|
      h.hex.chr
    end.join
  end
end

module RedstoneBot
  ProtocolVersion = 39
  
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
      int(@id)
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
      int(ProtocolVersion) +
      string(username) +
      string("") +
      int(0)*2 +
      byte(0)*3
    end
    
    def receive_data(socket)
      @eid = socket.read_int
      @level_type = socket.read_string
      socket.read_string
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
    attr_reader :ticks
    
    def receive_data(socket)
      @ticks = socket.read_long
    end
  end
  
  class Packet::EntityEquipment < Packet
    packet_type 0x05
    attr_reader :eid
    attr_reader :slot
    attr_reader :item_id
    attr_reader :damage
    
    def receive_data(socket)
      @eid = socket.read_int
      @slot = socket.read_short
      @item_id = socket.read_short
      @damage = socket.read_short
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
    
    def initialize(dimension=0, difficulty=1, game_mode=0, world_height=256, level_type='DEFAULT')
      @dimension = dimension
      @difficulty = difficulty
      @game_mode = game_mode
      @world_height = world_height
      @level_type = level_type
    end
    
    def receive_data(socket)
      @dimension = socket.read_int
      @difficulty = socket.read_byte
      @game_mode = socket.read_byte
      @world_height = socket.read_short
      @level_type = socket.read_string
    end
    
    def encode_data
      int(dimension) + byte(difficulty) + byte(game_mode) + short(world_height) + string(level_type)
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
    
    def initialize(status, intcoords, face)
      @status = status
      @x, @y, @z = intcoords
      @face = face
    end
    
    def encode_data
      byte(status) + int(x) + byte(y) + int(z) + byte(face)
    end
    
    def self.done(intcoords, face=0)
      p = allocate
      p.send :initialize, 2, intcoords, face
      p
    end
    
    def self.start(intcoords, face=0)
      p = allocate
      p.send :initialize, 0, intcoords, face
      p
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
      @y = socket.read_int
      @z = socket.read_int
    end
  end
  
  class Packet::Animation < Packet
    packet_type 0x12
    attr_reader :eid
    attr_reader :animation
  
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
    end
  end
  
  class Packet::SpawnDroppedItem < Packet
    packet_type 0x15
    attr_reader :eid
    attr_reader :item
    attr_reader :count
    attr_reader :metadata
    attr_reader :x, :y, :z
    attr_reader :yaw, :pitch, :roll
    
    def coords
      Coords[@x, @y, @z]
    end
        
    def receive_data(socket)
      @eid = socket.read_int
      @item = socket.read_short
      @count = socket.read_byte
      @metadata = socket.read_short
      @x = socket.read_int/32.0
      @y = socket.read_int/32.0
      @z = socket.read_int/32.0
      @yaw = socket.read_signed_byte
      @pitch = socket.read_signed_byte
      @roll = socket.read_signed_byte
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
    attr_reader :fireball_thrower_eid
    attr_reader :fireball_speed_x, :fireball_speed_y, :fireball_speed_z
  
    def coords
      Coords[@x, @y, @z]
    end
  
    def receive_data(socket)
      @eid = socket.read_int
      @type = socket.read_byte
      @x = socket.read_int/32.0
      @y = socket.read_int/32.0
      @z = socket.read_int/32.0
      @fireball_thrower_eid = socket.read_int
      if @fireball_thrower_eid != 0
        @fireball_speed_x = socket.read_short
        @fireball_speed_y = socket.read_short
        @fireball_speed_z = socket.read_short
      end
    end
  end
  
  class Packet::SpawnMob < Packet
    packet_type 0x18
    attr_reader :eid
    attr_reader :type
    attr_reader :x, :y, :z
    attr_reader :yaw, :pitch, :head_yaw
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
  end
  
  class Packet::DestroyEntity < Packet
    packet_type 0x1D
    attr_reader :eid
    
    def receive_data(socket)
      @eid = socket.read_int
    end
  end
  
  class Packet::EntityRelativeMove < Packet
    packet_type 0x1F
    attr_reader :eid
    attr_reader :dx, :dy, :dz
    
    def coords_change
      Coords[@dx, @dy, @dz]
    end
    
    def receive_data(socket)
      @eid = socket.read_int
      @dx = socket.read_signed_byte/32.0
      @dy = socket.read_signed_byte/32.0
      @dz = socket.read_signed_byte/32.0
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
    
    def receive_data(socket)
      @eid = socket.read_int
      @metadata = socket.read_metadata
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
  
  class Packet::ChunkAllocation < Packet
    packet_type 0x32
    attr_reader :mode
    
    def chunk_id
      [@x, @z]
    end
    
    def receive_data(socket)
      @x = socket.read_int*16
      @z = socket.read_int*16
      @mode = socket.read_bool
    end
  end
  
  class Packet::ChunkData < Packet
    packet_type 0x33
    attr_reader :ground_up_continuous
    attr_reader :primary_bit_map, :add_bit_map
    attr_reader :compressed_data
    
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
      socket.read_int
      @compressed_data = socket.read(compressed_size)
    end
    
    # Avoid showing all the data when we inspect this packet.
    def inspect
      tmp = @compressed_data
      begin
        @compressed_data = "#{tmp.size}..."
        return super
      ensure
        @compressed_data = tmp
      end
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
        x = bytes[0] & 0x0F
        z = bytes[0] >> 4 & 0x0F
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
      @block_type = socket.read_byte
      @block_metadata = socket.read_byte
    end
  end
  
  class Packet::BlockAction < Packet
    packet_type 0x36
    attr_reader :x, :y, :z
    #attr_reader :byte_1, :byte_2
    
    def chunk_id
      [@x/16*16, @z/16*16]
    end
    
    def receive_data(socket) 
      @x = socket.read_int
      @y = socket.read_short
      @z = socket.read_int
      @byte_1 = socket.read_byte
      @byte_2 = socket.read_byte
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
      @records = @record_count.times.collect do
        [socket.read_signed_byte, socket.read_signed_byte, socket.read_signed_byte]
      end
    end
  end
  
  class Packet::SoundOrParticleEffect < Packet
    packet_type 0x3D
    attr_reader :effect_id, :x, :y, :z, :data
    
    def receive_data(socket)
      @effect_id = socket.read_int
      @x = socket.read_int
      @y = socket.read_byte
      @z = socket.read_int
      @data = socket.read_int
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
  
  class Packet::ClickWindow < Packet
    packet_type 0x66
    
    attr_reader :window_id, :slot_id, :right_click, :action_number, :shift, :clicked_item
    
    def initialize(window_id, slot_id, right_click, action_number, shift, clicked_item)
      @window_id = window_id
      @slot_id = slot_id
      @right_clock = right_click
      @action_number = action_number
      @shift = shift
      @clicked_item = clicked_item
    end
    
    def encode_data
      raise "ClickWindow: clicked_item is nil" if clicked_item.nil?
      byte(window_id) + unsigned_short(slot_id) + bool(right_click) + unsigned_short(action_number) + bool(shift) + clicked_item.encode_data
    end
  end
  
  class Packet::SetSlot < Packet
    packet_type 0x67
    attr_reader :window_id, :slot_id, :slot_data
    
    def receive_data(socket)
      @window_id = socket.read_byte
      @slot_id = socket.read_short
      @slot_data = socket.read_slot
    end
  end
  
  class Packet::SetWindowItems < Packet
    packet_type 0x68
    attr_reader :window_id, :slots_data
    
    def receive_data(socket)
      @window_id = socket.read_byte
      count = socket.read_short
      @slots_data = count.times.collect do
        socket.read_slot
      end
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
    attr_reader :window_id, :action_nuber, :accepted
    
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
    attr_reader :action, :custom1, :custom2, :custom3
    
    def receive_data(socket)
      @x = socket.read_int
      @y = socket.read_short
      @z = socket.read_int
      @action = socket.read_byte
      @custom1 = socket.read_int
      @custom2 = socket.read_int
      @custom3 = socket.read_int
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
    
    attr_reader :invulernable     # speculation
    attr_reader :flying
    attr_reader :can_fly
    attr_reader :instant_destroy  # speculation
    
    def receive_data(socket)
      @invulnerable = socket.read_bool
      @flying = socket.read_bool
      @can_fly = socket.read_bool
      @instant_destroy = socket.read_bool
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
    
    def encode_data
      byte_array(shared_secret) + byte_array(verify_token_response)
    end
    
    def receive_data(socket)
      @shared_secret = socket.read_byte_array
      @verify_token_response = socket.read_byte_array
    end
  end
  
  # TODO: read http://wiki.vg/Protocol_Encryption  http://wiki.vg/Pre-release_protocol
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