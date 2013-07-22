require_relative 'coords'
require_relative '../brain'

module RedstoneBot
  class Look < Struct.new(:yaw, :pitch)
  end

  class Body
    # TODO: move the concurrency stuff out of here and into an ability module or something included in BasicBot?
    # Concurrency should be handled in abilities/Bot/Client/Synchronizer, not a model. ??
    # Also, improve the concurrency so bumped? works again and the position update happens very soon after
    # it is calculated.
  
    attr_accessor :position, :look, :on_ground, :stance, :health
    attr_accessor :default_period, :default_updater
    
    def on_ground?
      @on_ground
    end
    
    def dead?
      @health <= 0
    end
    
    def immobilized?
      !!@immobilization
    end
    
    def bumped?
      @bumped
    end
    
    def busy?
      @busy
    end
  
    def initialize(client, synchronizer)
      @synchronizer = synchronizer
      @client = client
      @default_period = 0.05
      
      client.listen do |p|
        case p
          when Packet::PlayerPositionAndLook
            # Either we moved into a solid block or the game is just beginning.

            # Store the new position and look.
            @position = Coords[p.x, p.y, p.z]
            @stance = p.stance
            @look = Look.new(p.yaw, p.pitch)
            @on_ground = p.on_ground
            announce_received_position(p)
            
            # Confirm the new position with the server.
            send_update
            
            if @started
              # We already got this packet before, so it must be a bump; the server didn't like
              # out position and is correcting it.
              @bumped = true
            else
              # This is our first PlayerPositionAndLook packet, so start the falling process.
              @default_updater = @synchronizer.new_brain
              @default_updater.start &method(:default_update)
              @started = true
            end
            
          when Packet::UpdateHealth
            @health = p.health
            if @health <= 0
              # We died, so respawn.
              @client.send_packet Packet::ClientStatuses.respawn
            end
            
          when Packet::ChangeGameState
            if p.reason == :invalid_bed
              puts "Invalid bed!!"
            end
        end
      end
      
    end
    
    def default_update
      while true
        if !@busy
          delay_after_last_update @default_period
          if @default_position_update && !immobilized?
            @default_position_update.call
          end
          send_update
        else
          @synchronizer.delay @default_period
        end
      end
    end
    
    def move_loop(update_period=nil)
      immobilization_check!
      busy_check!
      
      # This must be called from inside a brain.
      # TODO: call require_brain here so this called outside of the brain?
      
      update_period ||= @default_period
      
      begin
        @busy = true
        while true
          @bumped = false
          delay_after_last_update update_period        
          yield update_period
          send_update
        end
      ensure
        @busy = false
        
        # This is necessary because otherwise if someone called loop { move_loop { break } }
        # there would be no position updates sent for a long time.
        send_update
      end
    end
    
    def with_look(look)
      move_loop do
        self.look = look
        delay_after_last_update @default_period        
        send_update
        yield
        break
      end
    end

    def delay_after_last_update(period)
      diff = period - time_since_last_update
      if diff > 0
        @synchronizer.delay diff
      end
    end

    def time_since_last_update
      Time.now - @last_update_time
    end
    
    def announce_received_position(packet)
      $stderr.puts "#{@client.time_string} #{packet}"
    end
    
    def default_position_update(&proc)
      @default_position_update = proc
    end
    
    def look_at(target)
      immobilization_check!
      @look = angle_to_look_at(target) if target
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
    
    def coords
      position
    end
    
    def to_coords
      position
    end
    
    def busy_check!
      if @busy
        raise "Body is already busy."
      end
    end
    
    def immobilization_check!
      # TODO: should death be an immobilization?
      if @immobilization
        raise "Body is immobilized by #{@immobilization}."
      end
    end
    
    def immobilize(immobilization)
      raise "Cannot immobilize because the body is busy." if busy?
      @immobilization = immobilization
    end
    
    protected  
    def send_update
      self.stance = position.y + 1.62   # TODO: handle this better!
      packet = Packet::PlayerPositionAndLook.new(
              position.x, position.y, position.z,
              stance, look.yaw, look.pitch, on_ground)
      @client.send_packet packet
      @last_update_time = Time.now
      # puts "#{@client.time_string} TX #{packet}"
    end
  end
end