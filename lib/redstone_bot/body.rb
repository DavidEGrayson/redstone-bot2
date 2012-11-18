require_relative 'coords'

require 'thread'

# monkeypatch
class ConditionVariable
  def waiters_count
    @waiters_mutex.synchronize do
      @waiters.count
    end
  end
end

module RedstoneBot
  class Look < Struct.new(:yaw, :pitch)
  end

  class Body
    attr_accessor :position, :look, :on_ground, :stance, :health
    attr_accessor :update_period
    attr_accessor :next_update_period
    attr_accessor :last_update_period
    attr_accessor :debug
    attr_accessor :position_update_condition_variable
    attr_accessor :position_update_count
    
    def on_ground?
      @on_ground
    end
    
    def dead?
      @health <= 0
    end
    
    def bumped?
      @bumped
    end
    
    def busy?
      @position_update_condition_variable.waiters_count > 0
    end
  
    def initialize(client, synchronizer)
      @synchronizer = synchronizer
      @position_updaters = []
      @position_update_condition_variable = ConditionVariable.new
      @client = client
      @update_period = 0.05
      @position_update_count = 0
      client.listen do |p|
        case p
          when Packet::PlayerPositionAndLook
            # Either we moved into a solid block or the game is just beginning.

            # Store the new position and look.
            announce_received_position
            @position = Coords[p.x, p.y, p.z]
            @stance = p.stance
            @look = Look.new(p.yaw, p.pitch)
            @on_ground = p.on_ground
            
            # Confirm the new position with the server.
            send_update
            if @position_updater
              @bumped = true
            else
              @position_updater = start_position_updater
            end
          when Packet::UpdateHealth
            @health = p.health
            if @health <= 0
              # We died, so respawn.
              @client.send_packet Packet::ClientStatuses.respawn
            end
        end
      end
      
    end
    
    def announce_received_position(packet)
      puts "#{client.time_string} RX! #{packet}"
    end
    
    def on_position_update(&proc)
      @position_updaters << proc
    end
    
    def start_position_updater
      Thread.new do
        while true
          # TODO: get more reliable timing by using Time.now to compute how long to sleep
          @last_update_period = @next_update_period || @update_period
          @next_update_period = nil
          sleep(@last_update_period)   # this is the only time sleeping should happen in this thread
          
          @synchronizer.synchronize do
            position_update
          end
        end
      end
    end
    
    def position_update
      @position_updaters.each &:call
      self.stance = position.y + 1.62   # TODO: handle this better!
      @bumped = false
      send_update
      @position_update_count += 1
      @position_update_condition_variable.broadcast
    end
    
    def look_at(target)
      return if target.nil?
		  @look = angle_to_look_at(target)
    end

    def angle_to_look_at(target)
      target = target.to_coords
      look_vector = target - position
      x, y, z = look_vector.to_a
      yaw = Math::atan2(x, -z) * 180 / Math::PI + 180
      pitch = -Math::atan2(y, Math::sqrt((x * x) + (z * z))) * 180 / Math::PI
      Look.new(yaw, pitch)
    end
    
    def distance_to(coords)
      (coords.to_coords - position).magnitude
    end
    
    def closest(things)
      things.min_by { |t| distance_to t }
    end
    
    def wait_for_next_position_update(update_period = nil)
      if update_period
        self.next_update_period = update_period
      end
      count = position_update_count
      # $stderr.puts "waiting..."
      position_update_condition_variable.wait(@synchronizer.mutex)
      # $stderr.puts "awakened..."
      diff = position_update_count - count
      if diff != 1
        $stderr.puts "Warning: Failed to context switch to thread #{Thread.current} in time after waiting for position update (diff=#{diff})."
      end
    end
    
    protected  
    def send_update
      packet = Packet::PlayerPositionAndLook.new(
              position.x, position.y, position.z,
              stance, look.yaw, look.pitch, on_ground)
      @client.send_packet packet
      puts "#{@client.time_string} tx#{packet.to_s}" if debug
    end
  end
end