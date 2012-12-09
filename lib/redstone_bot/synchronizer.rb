require_relative 'regular_updater'
require_relative 'condition'

require 'timeout'

module RedstoneBot
  module Synchronizer
    attr_reader :mutex
  
    def synchronize(&block)
      @mutex.synchronize(&block)
    end
    
    def delay(time)
      @mutex.sleep(time)
    end
    
    def regular_updater(default_period, &block)
      RegularUpdater.new self, default_period, &block
    end
    
    # TODO: merge this with regular_updater somehow
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
    
    def new_condition
      Condition.new(self)
    end
    
    def new_brain
      Brain.new(self)
    end
  end
end