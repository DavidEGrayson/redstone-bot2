raise 'Please use Ruby 2.0.0 or later.' if RUBY_VERSION < '2.0.0'

require_relative 'pack'
require_relative 'protocol_version'
require_relative '../has_tids'
require 'zlib'
require 'json'

# TODO: implement the rest of the packets from http://www.wiki.vg/Protocol

# TODO: add LocaleAndViewDistance and see if that lets us get more chunks loaded

class String
  def inspect_hex
     '"' + bytes.collect { |b| '\x%02X' % [b] }.join + '"'
  end
end

module RedstoneBot
  class UnknownPacketError < StandardError
    attr_reader :tid_is

    def initialize(type)
      @tid_is = type
    end
  end

  class Packet
    extend HasTids
    include DataEncoder

    def self.receive(stream)
      tid = stream.read_byte
      packet_class = types[tid] or raise UnknownPacketError, tid
      packet_class.receive_data(stream)
    end

    # The following methods are only called on subclasses or Packet:
    
    def self.receive_data(stream)
      p = allocate
      p.receive_data(stream)
      p
    end

    def receive_data(stream)
      raise "receive_data instance method or class method not implemented in #{self.class.name}"
    end

    def encode
      tid_byte + encode_data
    end

    def encode_data
      raise "encode_data instance method not implemented in #{self.class.name}"
    end

    def tid_byte
      byte(self.class.tid)
    end
  end

  class Packet::KeepAlive < Packet
    tid_is 0x00
    attr_accessor :id

    def initialize(id=0)
      @id = id
    end

    def receive_data(stream)
      @id = stream.read_int
    end

    def encode_data
      int(id)
    end
  end

  class Packet::LoginRequest < Packet
    tid_is 0x01
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

    def receive_data(stream)
      @eid = stream.read_int
      @level_type = stream.read_string
      @server_mode = stream.read_byte
      @dimension = stream.read_signed_byte
      @difficulty = stream.read_byte
      stream.read_byte  # was previously world height
      @max_players = stream.read_byte
    end
  end

  class Packet::Handshake < Packet
    tid_is 0x02
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
    tid_is 0x03
    attr_reader :data, :death_type, :killer_name, :username, :chat

    # Source: http://www.wiki.vg/Chat except I left out the funny characters
    # because I'd have to think a little bit more about encodings to make it work
    AllowedChatChars = '!\"#$%&\'`()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_abcdefghijklmnopqrstuvwxyz{|}~| '.split('')

    def initialize(data)
      @data = data
      init_player_chat_info
    end

    def receive_data(stream)
      initialize JSON.parse stream.read_string
    end

    def ==(other)
      other.respond_to?(:data) && @data == other.data
    end

    def data_as_string
      if @data.is_a? String
        @data
      else
        JSON.generate @data
      end
    end
    
    def safe_data
      data_as_string.chars.select { |c| AllowedChatChars.include?(c) }[0,100].join
    end

    def encode_data
      string(safe_data)
    end

    def to_s
		  "chat: #{data}"
    end

    def player_chat?
      !!@chat
    end

    def whisper?
      @whisper
    end
    
    def emote?
      @emote
    end

    def self.player_chat(username, chat)
      p = ChatMessage.allocate
      p.player_chat(username, chat)
      p
    end

    def player_chat(username, chat)
      @data = {"translate"=>"chat.type.text", "using"=>[username, chat]}
      @username, @chat = username, chat
    end

    protected

    def init_player_chat_info
      types = %{commands.message.display.incoming chat.type.text chat.type.emote}
      if @data["translate"] && types.include?(@data["translate"])
        @username, @chat = @data["using"]
      end
      
      @whisper = @data["translate"] == "commands.message.display.incoming"
      @emote = @data["translate"] == "chat.type.emote"
    end

  end

  class Packet::TimeUpdate < Packet
    tid_is 0x04
    attr_reader :world_age, :day_age

    def receive_data(stream)
      @world_age = stream.read_long
      @day_age = stream.read_long
    end
  end

  class Packet::EntityEquipment < Packet
    tid_is 0x05
    attr_reader :eid, :spot_id, :item

    def receive_data(stream)
      @eid = stream.read_int
      @spot_id = stream.read_short
      @item = stream.read_item
    end
  end

  class Packet::SpawnPosition < Packet
    tid_is 0x06
    attr_reader :coords

    def receive_data(stream)
      @coords = Coords[stream.read_int, stream.read_int, stream.read_int].freeze
    end
  end

  class Packet::UseEntity < Packet
    tid_is 0x07
    
    attr_reader :user_eid, :target_eid, :right_mouse_button
    
    def initialize(user_eid, target_eid, right_mouse_button)
      @user_eid = user_eid
      @target_eid = target_eid
      @right_mouse_button = right_mouse_button
    end
    
    def encode_data
      int(@user_eid) + int(@target_eid) + bool(@right_mouse_button)
    end
  end
  
  class Packet::UpdateHealth < Packet
    tid_is 0x08
    attr_reader :health
    attr_reader :food
    attr_reader :food_saturation

    def receive_data(stream)
      @health = stream.read_float   # TODO: audit other parts of the code that use health because it is a float now!
      @food = stream.read_short
      @food_saturation = stream.read_float
    end
  end

  class Packet::Respawn < Packet
    tid_is 0x09
    attr_reader :dimension
    attr_reader :difficulty
    attr_reader :game_mode
    attr_reader :world_height
    attr_reader :level_type

    def receive_data(stream)
      @dimension = stream.read_int
      @difficulty = stream.read_byte
      @game_mode = stream.read_byte
      @world_height = stream.read_short
      @level_type = stream.read_string
    end

  end

  class Packet::Player < Packet
    tid_is 0x0A
    attr_reader :on_ground
    
    def encode_data
      bool(on_ground)
    end
  end

  class Packet::PlayerPosition < Packet
    tid_is 0x0B
    attr_reader :coords, :stance, :on_ground
    
    def encode_data
      double(coords[0]) + double(coords[1]) + double(stance) +
        double(coords[2]) + bool(on_ground)
    end
  end

  class Packet::PlayerLook < Packet
    tid_is 0x0C
    attr_reader :yaw, :pitch, :on_ground
    
    def encode_data
      float(yaw) + float(pitch) + float(on_ground)
    end
  end

  class Packet::PlayerPositionAndLook < Packet
    tid_is 0x0D
    attr_reader :x, :stance, :y, :z, :yaw, :pitch, :on_ground   # TODO: use #position that returns a frozen Coords object

    def initialize(x, y, z, stance, yaw, pitch, on_ground)
      @x, @y, @z = x, y, z
      @stance = stance
      @yaw, @pitch = yaw, pitch
      @on_ground = on_ground
    end

    def receive_data(stream)
      @x = stream.read_double
      @stance = stream.read_double
      @y = stream.read_double
      @z = stream.read_double
      @yaw = stream.read_float
      @pitch = stream.read_float
      @on_ground = stream.read_bool
    end

    def encode_data
      double(x) + double(y) + double(stance) + double(z) +
      float(yaw) + float(pitch) + bool(on_ground)
    end

    def to_s
      "Pos(%7.2f %7.2f %7.2f dy=%4.2f g=%d yw=%3.0f pt=%3.0f)" % ([x, y, z, stance - y, on_ground ? 1 : 0, yaw, pitch])
    end
  end

  class Packet::PlayerDigging < Packet
    tid_is 0x0E
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
    tid_is 0x0F

    attr_reader :coords, :direction, :held_item, :cursor_x, :cursor_y, :cursor_z

    def initialize(coords, direction, held_item, cursor_x=8, cursor_y=8, cursor_z=8)
      @coords = coords
      @direction = direction
      @held_item = held_item
      @cursor_x, @cursor_y, @cursor_z = cursor_x, cursor_y, cursor_z
    end

    def encode_data
      int(coords[0]) + byte(coords[1]) + int(coords[2]) + byte(direction) +
        encode_item(held_item) + byte(cursor_x) + byte(cursor_y) + byte(cursor_z)
    end
  end

  class Packet::HeldItemChange < Packet
    tid_is 0x10
    attr_reader :spot_id

    def initialize(spot_id)
      @spot_id = spot_id
    end

    def ==(other)
      other.is_a?(self.class) && @spot_id == other.spot_id
    end

    def encode_data
      unsigned_short(@spot_id)
    end

    def receive_data(stream)
      @spot_id = stream.read_unsigned_short
    end
  end

  class Packet::UseBed < Packet
    tid_is 0x11
    attr_reader :eid, :coords

    def receive_data(stream)
      @eid = stream.read_int
      @unknown_byte = stream.read_byte
      @coords = Coords[stream.read_int, stream.read_byte, stream.read_int].freeze
    end

    def to_s
      "UseBed(eid=#@eid, unknown_byte=#@unknown_byte, #@coords)"
    end
  end

  class Packet::Animation < Packet
    tid_is 0x12
    attr_reader :eid
    attr_reader :animation

    def initialize(eid, animation)
      @eid = eid
      @animation = animation
    end

    def encode_data
      int(eid) + byte(animation)
    end

    def receive_data(stream)
      @eid = stream.read_int
      @animation = stream.read_byte
    end
  end
  
  class Packet::EntityAction < Packet
    tid_is 0x13
    
    attr_reader :eid, :action, :jump_boost
    
    Actions = [nil, :crouch, :uncrouch, :leave_bed, :start_sprinting, :stop_sprinting]
    
    def initialize(eid, action, jump_boost: 0)
      @eid = eid
      @action = action
      @jump_boost = jump_boost
    end
    
    def encode_data
      int(eid) + byte(Actions.index(action)) + int(jump_boost)
    end
  end

  class Packet::SpawnNamedEntity < Packet
    tid_is 0x14
    attr_reader :eid
    attr_reader :player_name
    attr_reader :coords, :yaw, :pitch
    attr_reader :wielded_item_type
    attr_reader :metadata

    def receive_data(stream)
      @eid = stream.read_int
      @player_name = stream.read_string
      @coords = Coords[stream.read_int/32.0, stream.read_int/32.0, stream.read_int/32.0].freeze
      @yaw = stream.read_signed_byte
      @pitch = stream.read_signed_byte

      item_type_id = stream.read_short
      if item_type_id != 0
        @wielded_item_type = ItemType.from_id item_type_id
      end

      @metadata = stream.read_metadata
    end
  end

  class Packet::CollectItem < Packet
    tid_is 0x16
    attr_reader :collected_eid
    attr_reader :collector_eid

    def receive_data(stream)
      @collected_eid = stream.read_int
      @collector_eid = stream.read_int
    end
  end

  class Packet::SpawnObject < Packet  # includes vehicles
    tid_is 0x17
    attr_reader :eid
    attr_reader :type     # http://www.wiki.vg/Entities#Objects
    attr_reader :coords
    attr_reader :yaw, :pitch
    attr_reader :int_field
    attr_reader :speed_x, :speed_y, :speed_z

    def receive_data(stream)
      @eid = stream.read_int
      @type = stream.read_byte
      @coords = Coords[stream.read_int/32.0, stream.read_int/32.0, stream.read_int/32.0].freeze
      @pitch = stream.read_signed_byte
      @yaw = stream.read_signed_byte

      # The int field has different info depending on @type.  Details are here: http://www.wiki.vg/Object_Data
      @int_field = stream.read_int

      if @int_field != 0
        @speed_x = stream.read_short
        @speed_y = stream.read_short
        @speed_z = stream.read_short
      end
    end

    def to_s
      details = [eid, "type=#{type}", coords, "yaw=#{yaw}", "pitch=#{pitch}", int_field]
      if int_field != 0
        details << "speed=(#@speed_x, #@speed_y, #@speed_z)"
      end
      "SpawnObject(#{details.join(", ")})"
    end
  end

  class Packet::SpawnMob < Packet
    tid_is 0x18
    attr_reader :eid
    attr_reader :type
    attr_reader :coords
    attr_reader :yaw, :pitch, :head_yaw
    attr_reader :vx, :vy, :vz
    attr_reader :metadata

    def receive_data(stream)
      @eid = stream.read_int
      @type = stream.read_byte
      @coords = Coords[stream.read_int/32.0, stream.read_int/32.0, stream.read_int/32.0].freeze
      @yaw = stream.read_signed_byte
      @pitch = stream.read_signed_byte
      @head_yaw = stream.read_signed_byte
      @vz = stream.read_short   # TODO: is the velocity REALLY in Z,X,Y order?
      @vx = stream.read_short
      @vy = stream.read_short
      @metadata = stream.read_metadata
    end
  end

  class Packet::SpawnPainting < Packet
    tid_is 0x19
    attr_reader :eid
    attr_reader :title
    attr_reader :coords
    attr_reader :direction

    def receive_data(stream)
      @eid = stream.read_int
      @title = stream.read_string
      @coords = Coords[stream.read_int, stream.read_int, stream.read_int]
      @direction = stream.read_int
    end
  end

  class Packet::ExperienceOrb < Packet
    tid_is 0x1A
    attr_reader :eid, :coords, :count

    def receive_data(stream)
      @eid = stream.read_int
      @coords = Coords[stream.read_int/32.0, stream.read_int/32.0, stream.read_int/32.0].freeze
      @count = stream.read_short
    end
  end

  class Packet::SteerVehicle < Packet
    tid_is 0x1B
    attr_reader :sideways, :forward, :jump, :unmount
    
    def initialize(sideways, forward, jump: false, unmount: false)
      @sideways, @forward = sideways, forward
      @jump, @unmount = jump, unmount
    end
    
    def encode_data
      float(sideways) + float(forward) + bool(jump) + bool(unmount)
    end
  end

  class Packet::EntityVelocity < Packet
    tid_is 0x1C
    attr_reader :eid
    attr_reader :vx, :vy, :vz

    def velocity
      Coords[@vx, @vy, @vz]
    end

    def receive_data(stream)
      @eid = stream.read_int
      @vx = stream.read_short
      @vy = stream.read_short
      @vz = stream.read_short
    end

    def to_s
      "EntityVelocity(#{eid}, #{velocity})"
    end
  end

  class Packet::DestroyEntity < Packet
    tid_is 0x1D
    attr_reader :eids

    def receive_data(stream)
      count = stream.read_byte
      @eids = count.times.collect { stream.read_int }
    end
  end

  class Packet::Entity < Packet
    tid_is 0x1E
    
    attr_reader :eid
    
    def receive_data(stream)
      @eid = stream.read_int
    end
  end
  
  class Packet::EntityRelativeMove < Packet
    tid_is 0x1F
    attr_reader :eid, :dx, :dy, :dz

    def coords_change
      Coords[@dx, @dy, @dz]
    end

    def receive_data(stream)
      @eid = stream.read_int
      @dx = stream.read_signed_byte/32.0
      @dy = stream.read_signed_byte/32.0
      @dz = stream.read_signed_byte/32.0
    end

    def to_s
      "EntityRelativeMove(#{eid}, #{coords_change})"
    end
  end

  class Packet::EntityLook < Packet
    tid_is 0x20
    attr_reader :eid
    attr_reader :yaw, :pitch

    def receive_data(stream)
      @eid = stream.read_int
      @yaw = stream.read_signed_byte
      @pitch = stream.read_signed_byte
    end
  end

  class Packet::EntityLookAndRelativeMove < Packet
    tid_is 0x21
    attr_reader :eid, :dx, :dy, :dz, :yaw, :pitch

    def coords_change
      Coords[@dx, @dy, @dz]
    end

    def receive_data(stream)
      @eid = stream.read_int
      @dx = stream.read_signed_byte/32.0
      @dy = stream.read_signed_byte/32.0
      @dz = stream.read_signed_byte/32.0
      @yaw = stream.read_signed_byte
      @pitch = stream.read_signed_byte
    end
  end

  class Packet::EntityTeleport < Packet
    tid_is 0x22
    attr_reader :eid, :coords, :yaw, :pitch

    def receive_data(stream)
      @eid = stream.read_int
      @coords = Coords[stream.read_int/32.0, stream.read_int/32.0, stream.read_int/32.0].freeze
      @yaw = stream.read_signed_byte
      @pitch = stream.read_signed_byte
    end

    def to_s
      "EntityTeleport(#{eid}, #{coords}, yw=#{yaw}, pt=#{pitch})"
    end
  end

  class Packet::EntityHeadLook < Packet
    tid_is 0x23
    attr_reader :eid, :head_yaw

    def receive_data(stream)
      @eid = stream.read_int
      @head_yaw = stream.read_signed_byte
    end
  end

  class Packet::EntityStatus < Packet
    tid_is 0x26
    attr_reader :eid, :status

    def receive_data(stream)
      @eid = stream.read_int
      @status = stream.read_byte
    end
  end

  class Packet::AttachEntity < Packet
    tid_is 0x27
    attr_reader :eid, :vehicle_eid, :leash

    def receive_data(stream)
      @eid = stream.read_int
      @vehicle_eid = stream.read_int
      @leash = stream.read_byte
    end
  end

  class Packet::EntityMetadata < Packet
    tid_is 0x28
    attr_reader :eid, :metadata

    def receive_data(stream)
      @eid = stream.read_int
      @metadata = stream.read_metadata
    end

    def to_s
      "EntityMetadata(#@eid, #{@metadata.inspect})"
    end
  end

  class Packet::EntityEffect < Packet
    tid_is 0x29
    attr_reader :eid, :effect_id, :amplifier, :duration

    def receive_data(stream)
      @eid = stream.read_int
      @effect_id = stream.read_byte
      @amplifier = stream.read_byte
      @duration = stream.read_unsigned_short
    end
  end
  
  class Packet::RemoveEntityEffect < Packet
    tid_is 0x2A
    attr_reader :eid, :effect_id
    
    def receive_data(stream)
      @eid = stream.read_int
      @effect_id = stream.read_byte
    end
  end

  class Packet::SetExperience < Packet
    tid_is 0x2B
    attr_reader :experience_bar, :level, :total_experience

    def receive_data(stream)
      @experience_bar = stream.read_float
      @level = stream.read_short
      @total_experience = stream.read_short
    end
  end

  class Packet::EntityProperties < Packet
    tid_is 0x2C
    attr_reader :eid, :properties
    
    def receive_data(stream)
      @eid = stream.read_int
      property_count = stream.read_int
      @properties = property_count.times.collect do
        key = stream.read_string
        value = stream.read_double
        length = stream.read_short
        list = length.times.collect do
          [stream.read_long, stream.read_long, stream.read_double, stream.read_byte]
        end
        [key, value, list]
      end
    end
  end
  
  class Packet::ChunkData < Packet
    tid_is 0x33
    attr_reader :ground_up_continuous
    attr_reader :primary_bit_map, :add_bit_map
    attr_reader :data

    def chunk_id
      [@x, @z]
    end

    def receive_data(stream)
      @x = stream.read_int*16
      @z = stream.read_int*16
      @ground_up_continuous = stream.read_bool
      @primary_bit_map = stream.read_unsigned_short
      @add_bit_map = stream.read_unsigned_short
      compressed_size = stream.read_int
      compressed_data = stream.read(compressed_size)
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
    tid_is 0x34
    attr_reader :count
    attr_reader :data

    def chunk_id
      [@x, @z]
    end

    def receive_data(stream)
      @x = stream.read_int*16
      @z = stream.read_int*16
      @count = stream.read_unsigned_short
      @data = stream.read(stream.read_unsigned_int)
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
    tid_is 0x35
    attr_reader :x, :y, :z
    attr_reader :block_type, :block_metadata

    alias :block_type_id :block_type

    def chunk_id
      [x/16*16, z/16*16]
    end

    def receive_data(stream)
      @x = stream.read_int
      @y = stream.read_byte
      @z = stream.read_int
      @block_type = stream.read_unsigned_short
      @block_metadata = stream.read_byte
    end

    def to_s
      "BlockChange(#@x, #@y, #@z, type=#{@block_type}, metadata=#{@block_metadata})"
    end
  end

  class Packet::BlockAction < Packet
    tid_is 0x36
    attr_reader :x, :y, :z
    attr_reader :data_bytes, :block_id

    def chunk_id
      [@x/16*16, @z/16*16]
    end

    def coords
      Coords[@x, @y, @z]
    end

    def receive_data(stream)
      @x = stream.read_int
      @y = stream.read_short
      @z = stream.read_int
      @data_bytes = [stream.read_byte, stream.read_byte]
      @block_id = stream.read_unsigned_short
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
    tid_is 0x37
    attr_reader :eid, :coords

    # Progress goes from 0 to 7.
    attr_reader :progress

    def receive_data(stream)
      @eid = stream.read_int
      @coords = Coords[stream.read_int, stream.read_int, stream.read_int].freeze
      @progress = stream.read_signed_byte
    end

    def to_s
      "BlockBreakAnimation(eid=#@eid, #@coords, progress=#@progress)"
    end
  end

  class Packet::MapChunkBulk < Packet
    tid_is 0x38

    attr_reader :data, :metadata

    def receive_data(stream)
      chunk_column_count = stream.read_unsigned_short
      data_size = stream.read_unsigned_int
      sky_light_sent = stream.read_bool
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
    tid_is 0x3C
    attr_reader :coords, :radius_maybe, :records, :player_motion

    def receive_data(stream)
      @coords = Coords[stream.read_double, stream.read_double, stream.read_double].freeze
      @radius_maybe = stream.read_float
      count = stream.read_int
      @records = count.times.collect do
        [stream.read_signed_byte, stream.read_signed_byte, stream.read_signed_byte]
      end
      @player_motion = Coords[stream.read_float, stream.read_float, stream.read_float].freeze
    end
  end

  class Packet::SoundOrParticleEffect < Packet
    tid_is 0x3D
    attr_reader :effect_id, :coords, :data, :disable_relative_volume

    def receive_data(stream)
      @effect_id = stream.read_int
      @coords = Coords[stream.read_int, stream.read_byte, stream.read_int].freeze
      @data = stream.read_int
      @disable_relative_volume = stream.read_bool
    end
  end

  class Packet::NamedSoundEffect < Packet
    tid_is 0x3E

    attr_reader :name, :coords, :volume, :pitch

    def receive_data(stream)
      @name = stream.read_string
      @coords = Coords[stream.read_int/8.0, stream.read_int/8.0, stream.read_int/8.0].freeze
      @volume = stream.read_float
      @pitch = stream.read_byte
    end
  end

  class Packet::Particle < Packet
    tid_is 0x3F
    attr_reader :name, :coords, :offset, :speed, :count
    
    def receive_data(stream)
      @name = stream.read_string
      @coords = Coords[stream.read_float, stream.read_float, stream.read_float]
      @offset = Coords[stream.read_float, stream.read_float, stream.read_float]
      @speed = stream.read_float
      @count = stream.read_unsigned_int
    end
  end

  class Packet::ChangeGameState < Packet
    tid_is 0x46
    attr_reader :reason, :game_mode

    ReasonCodes = %i[invalid_bed begin_raining end_raining change_game_mode enter_credits]
    
    def receive_data(stream)
      @reason = ReasonCodes[stream.read_byte]
      @game_mode = stream.read_byte
    end
  end  

  class Packet::Thunderbolt < Packet   # a.k.a GlobalEntity on the wiki
    tid_is 0x47
    attr_accessor :eid, :coords

    def receive_data(stream)
      @eid = stream.read_int
      @unknown_byte = stream.read_byte
      @coords = Coords[stream.read_int/32.0, stream.read_int/32.0, stream.read_int/32.0].freeze
    end

    def to_s
      "ThunberBolt(eid=#@eid, unknown_byte=#@unknown_byte, #@coords)"
    end
  end

  class Packet::OpenWindow < Packet
    tid_is 0x64

    attr_accessor :window_id, :type, :title, :spot_count, :display_title_as_is, :eid

    def receive_data(stream)
      @window_id = stream.read_byte
      @type = stream.read_byte
      @title = stream.read_string
      @spot_count = stream.read_byte
      @display_title_as_is = stream.read_bool
      if @type == 11
        # Animal chest: get the horse entity ID
        @eid = stream.read_int
      end
    end

    def to_s
      "OpenWindow(#{window_id}, type=#{type}, title=#{title}, spot_count=#{spot_count})"
    end
  end

  class Packet::CloseWindow < Packet
    tid_is 0x65

    attr_accessor :window_id

    def initialize(window_id)
      @window_id = window_id
    end

    def receive_data(stream)
      @window_id = stream.read_byte
    end

    def encode_data
      byte(@window_id)
    end

    def to_s
      "CloseWindow(#{window_id})"
    end
  end

  class Packet::ClickWindow < Packet
    tid_is 0x66

    attr_reader :window_id, :spot_id, :mouse_button, :action_number, :shift, :clicked_item

    # TODO: shift is really "mode" and allows for a bunch of different actions
    def initialize(window_id, spot_id, mouse_button, action_number, shift, clicked_item)
      @window_id = window_id
      @spot_id = spot_id
      @mouse_button = mouse_button
      @action_number = action_number
      @shift = shift
      @clicked_item = clicked_item
    end

    def self.outside(transaction_id)
      new 0, -999, :left, transaction_id, false, nil
    end

    def encode_mouse_button
      index = [:left, :right, :_, :middle].index(mouse_button)
      raise "Invalid mouse button #{mouse_button.inspect}" if !index
      byte index
    end

    def encode_data
      # TODO: this needs work...
      byte(window_id) + short(spot_id) + encode_mouse_button + unsigned_short(action_number) + bool(shift) + encode_item(clicked_item)
    end
  end

  class Packet::SetSlot < Packet
    tid_is 0x67
    attr_reader :window_id, :spot_id, :item

    def receive_data(stream)
      @window_id = stream.read_signed_byte
      @spot_id = stream.read_short
      @item = stream.read_item
    end

    def cursor?
      window_id == -1 && spot_id == -1
    end

    def redundant_after?(packet)
      packet.is_a?(Packet::SetWindowItems) && window_id == packet.window_id && item == packet.items[spot_id]
    end

    def to_s
      if cursor?
        "SetSlot(cursor, #{item})"
      else
        "SetSlot(window_id=#{window_id}, spot_id=#{spot_id}, #{item})"
      end
    end
  end

  class Packet::SetWindowItems < Packet
    tid_is 0x68
    attr_reader :window_id, :items

    def receive_data(stream)
      @window_id = stream.read_byte
      count = stream.read_short
      @items = count.times.collect do
        stream.read_item
      end
    end

    def to_s
      "SetWindowItems(#{window_id}, #{items.join ','})"
    end
  end

  class Packet::UpdateWindowProperty < Packet
    tid_is 0x69
    attr_reader :window_id, :property, :value

    def receive_data(stream)
      @window_id = stream.read_byte
      @property = stream.read_unsigned_short
      @value = stream.read_unsigned_short
    end

    def to_s
      "UpdateWindowProperty(#{window_id}, #{property}, #{value})"
    end
  end

  class Packet::ConfirmTransaction < Packet
    tid_is 0x6A
    attr_reader :window_id, :action_number, :accepted

    def initialize(window_id, action_number, accepted)
      @window_id = window_id
      @action_number = action_number
      @accepted = accepted
    end

    def receive_data(stream)
      @window_id = stream.read_byte
      @action_number = stream.read_unsigned_short
      @accepted = stream.read_bool
    end

    def encode_data
      byte(window_id) + unsigned_short(action_number) + bool(accepted)
    end

    def to_s
      if accepted
        "ConfirmTransaction(#{window_id}, #{action_number})"
      else
        "ConfirmTransaction(#{window_id}, #{action_number}, TRANSACTION REJECTED!)"
      end
    end
  end

  class Packet::UpdateSign < Packet
    tid_is 0x82
    attr_reader :coords, :text

    def receive_data(stream)
      @coords = Coords[stream.read_int, stream.read_short, stream.read_int].freeze
      @text = 4.times.collect { stream.read_string }.join("\n")
    end
  end

  class Packet::ItemData < Packet
    tid_is 0x83
    attr_reader :item_type, :item_id, :text

    def receive_data(stream)
      @item_type = ItemType.from_id(stream.read_short)
      @item_id = stream.read_short
      @text = stream.read_byte_array
    end
  end

  # This packet tells us all about mob spawners.  Example data:
  # {""=>{"id" =>"MobSpawner", "MinSpawnDelay"=>200, "RequiredPlayerRange"=>16,
  #       "Delay"=>20, "MaxNearbyEntities"=>6, "MaxSpawnDelay"=>800, "SpawnRange"=>4,
  #       "SpawnCount"=>4, "z"=>533, "EntityId"=>"Spider", "y"=>25, "x"=>-186} }
  class Packet::UpdateTileEntity < Packet
    tid_is 0x84
    attr_reader :coords, :action, :data

    def receive_data(stream)
      @coords = Coords[stream.read_int, stream.read_short, stream.read_int].freeze
      @action = stream.read_byte
      gzipped_data = stream.read_byte_array
      nbt_stream = stream.gunzip_stream(gzipped_data)
      nbt_hash = nbt_stream.read_nbt
      @data = nbt_hash
    end

    def to_s
      "UpdateTileEntity(#@coords, action=#@action, #{@data.inspect})"
    end
  end
  
  class Packet::TileEditorOpen < Packet
    tid_is 0x85
    attr_reader :id, :coords
    
    def receive_data(stream)
      @id = stream.read_byte
      @coords = Coords[stream.read_int, stream.read_int, stream.read_int].freeze
    end
  end

  class Packet::IncrementStatistic < Packet
    tid_is 0xC8
    attr_reader :statistic_id, :amount

    def receive_data(stream)
      @statistic_id = stream.read_int
      @amount = stream.read_int
    end
  end

  class Packet::PlayerListItem < Packet
    tid_is 0xC9
    attr_reader :player_name, :online, :ping

    def receive_data(stream)
      @player_name = stream.read_string
      @online = stream.read_bool
      @ping = stream.read_short
    end
  end

  class Packet::PlayerAbilities < Packet
    tid_is 0xCA

    attr_reader :flags
    attr_reader :flying_speed
    attr_reader :walking_speed

    def receive_data(stream)
      @flags = stream.read_byte
      @flying_speed = stream.read_float
      @walking_speed = stream.read_float
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
    tid_is 0xCC

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
    tid_is 0xCD

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
  
  class Packet::ScoreboardObjective < Packet
    tid_is 0xCE
    attr_reader :score_name, :text
    
    def remove?
      @remove
    end
    
    def receive_data(stream)
      @objective_name = stream.read_string
      @objective_value = stream.read_string
      @remove = stream.read_bool
    end
  end
  
  class Packet::UpdateScore < Packet
    tid_is 0xCF
    attr_reader :item_name, :score_name, :value
    
    def remove?
      @remove
    end
    
    def receive_data(stream)
      @item_name = stream.read_string
      @remove = stream.read_bool
      if !@remove
        @score_name = stream.read_string
        @value = stream.read_int
      end
    end
  end
  
  class Packet::DisplayScoreboard < Packet
    tid_is 0xD0
    attr_reader :score_name, :position
    Positions = %i(list sidebar below_name)
    
    def receive_data(stream)
      @position = Positions[stream.read_byte]
      @score_name = stream.read_string
    end
  end
  
  class Packet::Team < Packet
    tid_is 0xD1
    
    attr_reader :team_name, :mode, :team_display_name, :team_prefix, :team_suffix, 
      :friendly_fire, :player_names
    Modes = %i(create remove update players_add players_remove)
    
    def receive_data(stream)
      @team_name = stream.read_string
      @mode = Modes[stream.read_byte]
      
      if %i(create update).include? @mode
        @team_display_name = stream.read_string
        @team_prefix = stream.read_string
        @team_suffix = stream.read_string
        @friendly_fire = stream.read_byte        
      end
      
      if %i(create players_add players_remove).include? @mode
        count = stream.read_unsigned_short
        @player_names = count.times.collect { stream.read_string }
      end
    end
    
  end

  class Packet::PluginMessage < Packet
    tid_is 0xFA
    attr_reader :channel, :data

    def receive_data(stream)
      @channel = stream.read_string
      length = stream.read_short
      @data = stream.read(length)
    end
  end

  class Packet::EncryptionKeyResponse < Packet
    tid_is 0xFC

    attr_reader :shared_secret, :verify_token_response

    def initialize(shared_secret, verify_token_response)
      @shared_secret = shared_secret
      @verify_token_response = verify_token_response
    end

    def encode_data
      byte_array(shared_secret) + byte_array(verify_token_response)
    end

    def receive_data(stream)
      @shared_secret = stream.read_byte_array
      @verify_token_response = stream.read_byte_array
    end
  end

  class Packet::EncryptionKeyRequest < Packet
    tid_is 0xFD

    attr_reader :connection_hash, :public_key, :verify_token
    alias :server_id :connection_hash

    def receive_data(stream)
      @connection_hash = stream.read_string

      @public_key = stream.read_byte_array
      @verify_token = stream.read_byte_array
    end
  end

  class Packet::Disconnect < Packet
    tid_is 0xFF
    attr_reader :reason

    def receive_data(stream)
      @reason = stream.read_string
    end
  end


end