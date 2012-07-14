require 'matrix'

module RedstoneBot
  class Look < Struct.new(:yaw, :pitch)
  end

  class Body
    attr_accessor :position, :look, :on_ground, :stance
    
    def on_ground?
      @on_ground
    end
    
    def initialize(client)
      @client = client
      client.listen do |p|
        case p
          when Packet::PlayerPositionAndLook
            @position = Vector[p.x, p.y, p.z]
            @stance = p.stance
            @look = Look.new(p.yaw, p.pitch)
            @on_ground = p.on_ground
            @regular_update_thread ||= start_regular_update_thread
          when Packet::Respawn
            raise "TODO: handle respawn plz"
        end
      end
    end
    
    def start_regular_update_thread
      @client.regularly(0.05) do
        @client.send_packet Packet::PlayerPositionAndLook.new(
          position[0], position[1], position[2],
          stance, look.yaw, look.pitch, @on_ground)
      end
    end
  end
end