module RedstoneBot

  # Jumps until the desired height is attained or the player hits his head on something solid.
  class Jump
    @default_speed = 10
    @default_tolerance = 0.2
    
    module ClassMethods
      attr_accessor :default_speed
    end
    extend ClassMethods
    
    attr_accessor :speed
    attr_accessor :y_goal
    attr_accessor :height
    
    def initialize(height)
      @speed = self.class.default_speed
      @started = @done = false
      @height = height
    end
    
    def started?
      @started
    end
    
    def done?
      @done
    end
    
    def bumped?
      @bumped
    end
    
    def start(body)
      @body = body
      @started = true
      @y_goal = body.position.y + @height
    end
    
    # TODO: eventually remove this argument because body is supplied to #start
    def update_position(body)
      return if !started? || done?
      
      if body.bumped?
        @done = @bumped = true
        return
      end
      
      if body.position[1] >= @y_goal
        @done = true
        return
      end
      
      body.position[1] += speed.to_f*body.update_period
    end
  end
end