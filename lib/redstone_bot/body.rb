module RedstoneBot
  class Body
    def initialize(client)
      @client = client
      client.listen do |p|
        case p
          when Packet::PlayerPositionAndLook
            @position, @look = p.position, p.look
            @regular_update_thread ||= start_regular_update_thread
          when Packet::Respawn
            raise "TODO: handle respawn plz"
        end
      end
    end
    
    def start_regular_update_thread
      client.regularly(0.05) do
        client.send_packet Packet::PlayerPositionAndLook.new(position, look)
      end
    end
  end
end