require "continuation"
require "timeout"
require_relative "move_fiber"

module RedstoneBot
  # Meant to be mixed into an object that has a "body" method, probably into
  # subclasses of Bot.
  module MovementManager
    
    def start
      stop
      @current_brain = Thread.new do
        client.synchronize do
          begin
            Thread.current[:brain] = true
            yield
          ensure
            @current_brain = nil
          end
        end
      end
      nil
    end
    
    def in_brain?
      Thread.current[:brain]
    end
    
    def require_brain(&proc)
      if in_brain?
        true
      else
        start(&proc) if proc
        false
      end
    end
    
    def require_fiber(&proc)  # TODO: remove this
      require_brain(&proc)
    end
    
    def in_fiber? # TODO: Remove this
      in_brain?
    end
    
    def stop
      if @current_brain
        @current_brain.terminate
        @current_brain = nil
      end
    end
    
    def delay(time)
      sleep(time)
    end
    
    def timeout(*args, &block)
      Timeout::timeout(*args, &block)
    end
    
    def wait_for_next_position_update(update_period = nil)
      if update_period
        body.next_update_period = update_period
      end
      body.position_update_condition_variable.wait(client.mutex)
    end

  end
end