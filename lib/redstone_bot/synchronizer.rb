require "timeout"

module RedstoneBot
  module Synchronizer
    attr_reader :mutex
  
    def synchronize(&block)
      @mutex.synchronize(&block)
    end
    
    def delay(time)
      @mutex.sleep(time)
    end
    
    def regularly(time, &block)
      Thread.new do
        while true
          sleep time
          synchronize &block
        end
      end
    end

    def later(time, &block)
      Thread.new do
        sleep time
        synchronize &block
      end
    end

    # timeout function that does NOT throw exceptions
    def timeout(*args, &block)
      Timeout::timeout(*args, &block)
    rescue Timeout::Error
    end
    
    # timeout function that throws exceptions
    def timeout!(*args, &block)
      Timeout::timeout(*args, &block)
    end
    
    # Function that executes the block for the given period of time.
    def time(min, max=nil)
      if max.nil? && min.respond_to?(:max)
        max = min.max
        min = min.min
      end
      
      start = Time.now
      Timeout::timeout(max) do
        while true
          yield
          if min.nil? || (Time.now - start) > min 
            break
          end
        end
      end
    rescue Timeout::Error
    end
    
  end
end