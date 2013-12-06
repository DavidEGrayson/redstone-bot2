module RedstoneBot
  module ChatTime
    def chat_time(p)
      case p.chat
      when /\Atime\??\Z/
        chat time_report
      end
    end
    
    def time_report
      if time_tracker.time_known?
        #day_age_s = time_tracker.convert_ticks_to_seconds(time_tracker.day_age)
        r = fake_time.strftime("%l:%M %P, ")
        if time_tracker.day?
          r += "%s real time until night" % seconds_to_mmss(time_tracker.seconds_until_night)
        else
          r += "%s real time until day" % seconds_to_mmss(time_tracker.seconds_until_day)
        end
      else
        "dunno what time it is"
      end
    end
    
    def fake_time
      x = (time_tracker.day_age + 6000) % 24000   # Recenter it so noon is at 12000
      x = x * 60 * 60 / 1000                      # Convert to seconds since midnight.
      Time.at(x).utc
    end
    
    def seconds_to_mmss(seconds)
      seconds = seconds.to_i
      "%02d:%02d" % [seconds / 60, seconds % 60]
    end
  end
end