require 'bigdecimal'

module RedstoneBot
  class TimeTracker
  
    TicksPerSecond = 20
    Sunrise = 0
    Noon = 6000
    Sunset = 12000
    Midnight = 18000
    FullDay = 24000
  
    attr_reader :world_age, :day_age
  
    def initialize(client)
      client.listen &method(:receive_packet)
    end
    
    def receive_packet(p)
      return unless p.is_a?(Packet::TimeUpdate)
      
      @world_age = p.world_age
      @sun_moving = p.day_age >= 0
      @day_age = p.day_age.abs
    end
    
    def sun_moving?
      @sun_moving
    end
    
    def day?
      @day_age && @day_age < Sunset
    end
    
    def night?
      @day_age && !day?
    end
    
    def ticks_until_night
      if @day_age
        if night?
          0
        else
          Sunset - @day_age
        end
      end
    end
    
    def ticks_until_day
      if @day_age
        if day?
          0
        else
          FullDay - @day_age
        end
      end
    end

    def seconds_until_night
      @day_age && ticks_until_night / BigDecimal(TicksPerSecond)
    end

    def seconds_until_day
      @day_age && ticks_until_day / BigDecimal(TicksPerSecond)
    end
    
  end
end