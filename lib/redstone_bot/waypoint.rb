require "redstone_bot/coords"

module RedstoneBot

  # An "action" class that moves a bot to a waypoint.
  # This will be the first of many "action" classes that make the bot do something and know when they are done.
  class Waypoint
    @default_speed = 10
    @default_tolerance = 0.2
    
    module ClassMethods
      attr_accessor :default_speed
      attr_accessor :default_tolerance
    end
    extend ClassMethods
  
    attr_accessor :coords
    attr_accessor :speed
    attr_accessor :tolerance
    
    def initialize(coords, speed=self.class.default_speed)
      @started = @done = false
      @coords = coords
      @speed = speed
      @tolerance = self.class.default_tolerance
      @axes = [Coords::X, Coords::Y, Coords::Z].cycle
    end
    
    def started?
      @started
    end
    
    def start(body)
      @started = true
    end
    
    def update_position(body)
      body.look_at @coords

      return if done?
      
      d = @coords - body.position
      if d.norm < @tolerance
        @done = true  # reached it
        return
      end
      
      max_distance = speed*body.update_period
      if d.norm > max_distance
        d = d.normalize*max_distance
      end
      
      if body.bumped?
        d = d.project_onto_unit_vector(@axes.next)*3
      end
      
      body.position += d
    end
    
    def done?
      @done
    end
  end
  
end