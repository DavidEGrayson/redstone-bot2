require_relative 'coords'
require 'move_fiber'

module RedstoneBot
  class Look < Struct.new(:yaw, :pitch)
  end

  class Body
    attr_accessor :position, :look, :on_ground, :stance, :health
    attr_accessor :update_period
    attr_accessor :next_update_period
    attr_accessor :last_update_period
    attr_accessor :debug
    attr_accessor :current_fiber
    
    def on_ground?
      @on_ground
    end
    
    def dead?
      @health <= 0
    end
    
    def bumped?
      @bumped
    end
  
    def initialize(client)
      @position_updaters = []
      @client = client
      @update_period = 0.05
      client.listen do |p|
        case p
          when Packet::PlayerPositionAndLook
            puts "#{client.time_string} RX! #{p}"
            @position = Coords[p.x, p.y, p.z]
            @stance = p.stance
            @look = Look.new(p.yaw, p.pitch)
            @on_ground = p.on_ground
            send_update
            if @regular_update_thread
              @bumped = true
            else
              @regular_update_thread = start_regular_update_thread
            end
          when Packet::UpdateHealth
            @health = p.health
            if @health <= 0
              @client.send_packet Packet::ClientStatuses.respawn
            end
        end
      end
      
      on_position_update do
        if @current_fiber
          if @current_fiber.respond_to? :call
            c = @current_fiber
            @current_fiber = Fiber.new { c.call }
          end
          @current_fiber.resume
          @current_fiber = nil if !@current_fiber.alive?
        end
      end
    end
    
    def on_position_update(&proc)
      @position_updaters << proc
    end
    
    def start_regular_update_thread
      Thread.new do
        while true
          # TODO: get more reliable timing by using Time.now to compute how long to sleep
          @last_update_period = @next_update_period || @update_period
          @next_update_period = nil
          sleep(@last_update_period)
          @client.synchronize do
            @position_updaters.each &:call
            self.stance = position.y + 1.62   # TODO: handle this better!
            @bumped = false
            send_update
          end
        end
      end
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
    
    def start(&proc)
      @current_fiber = proc
      nil
    end
    
    def stop
      @current_fiber = nil
    end
    
    def delay(time)
      wait_for_next_position_update(time)
    end
    
    def wait_for_next_position_update(update_period = nil)
      if update_period
        self.next_update_period = update_period
      end
      Fiber.yield
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