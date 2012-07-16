require 'matrix'

module RedstoneBot
  class Look < Struct.new(:yaw, :pitch)
  end

  class Body
    attr_accessor :position, :look, :on_ground, :stance
    attr_accessor :update_period
    
    def on_ground?
      @on_ground
    end
    
    def initialize(client)
      @position_updaters = []
      @client = client
      @update_period = 0.05
      client.listen do |p|
        case p
          when Packet::PlayerPositionAndLook
            #puts "rx pos&look: %7.4f %7.4f %7.4f" % [p.x, p.y, p.z]
            @position = Vector[p.x, p.y, p.z]
            @stance = p.stance
            @look = Look.new(p.yaw, p.pitch)
            @on_ground = p.on_ground
            send_update
            @regular_update_thread ||= start_regular_update_thread
          when Packet::Respawn
            raise "TODO: handle respawn plz"
        end
      end
    end
    
    def on_position_update(&proc)
      @position_updaters << proc
    end
    
    def start_regular_update_thread
      @client.regularly(@update_period) do
        @position_updaters.each do |p|
          p.call
        end
        send_update
      end
    end
    
    def look_at(target)
		  @look = angle_to_look_at(target)
    end

    def angle_to_look_at(target)
      if target.respond_to?(:position)
        target = target.position
      end
      look_vector = target - position
      x, y, z = look_vector.to_a
      yaw = Math::atan2(x, -z) * 180 / Math::PI + 180
      pitch = -Math::atan2(y, Math::sqrt((x * x) + (z * z))) * 180 / Math::PI
      Look.new(yaw, pitch)
    end
    
    protected  
    def send_update
      #puts "tx pos: %7.4f %7.4f %7.4f dy=%7.4f g=%d" % (position.to_a + [stance - position[1], on_ground? ? 1 : 0])
      @client.send_packet Packet::PlayerPositionAndLook.new(
              position[0], position[1], position[2],
              stance, look.yaw, look.pitch, on_ground)
    end
  end
end