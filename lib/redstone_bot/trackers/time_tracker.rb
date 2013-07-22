require 'bigdecimal'

module RedstoneBot

  # The methods here return nil if we do not know the answer.
  class TimeTracker
  
    TicksPerSecond = 20
    Sunrise = 0
    Noon = 6000
    Sunset = 13000
    Midnight = 18000
    DayEnd = 24000
    
    DayRange = Sunrise...Sunset
    NightRange = Sunset...DayEnd
  
    attr_reader :world_age, :day_age
  
    def initialize(client)
      client.listen &method(:receive_packet)
    end
    
    def receive_packet(p)
      return unless p.is_a?(Packet::TimeUpdate)
      
      @world_age = p.world_age
      @sun_moving = p.day_age >= 0
      @day_age = p.day_age.abs
      @day_age = @day_age % 24000
    end
    
    def time_known?
      !@day_age.nil?
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
    
    def ticks_until(range)
      if @day_age
        if range.include? @day_age
          0
        else
          (range.min - @day_age) % 24000
        end
      end
    end

    def convert_ticks_to_seconds(ticks)
      ticks / BigDecimal(TicksPerSecond)
    end
    
    def ticks_until_night
      ticks_until NightRange
    end
    
    def ticks_until_day
      ticks_until DayRange
    end

    def seconds_until_night
      @day_age && convert_ticks_to_seconds(ticks_until_night)
    end

    def seconds_until_day
      @day_age && convert_ticks_to_seconds(ticks_until_day)
    end
    
  end
end