require_relative "move_fiber"

module RedstoneBot
  # Meant to be mixed into an object that has a "body" method, probably into
  # subclasses of Bot.
  # Provides high-level methods like "start" and "stop" that let you start doing
  # a movement (with a fiber), and useful functions you can call in that context.
  module MovementManager
    # This is called whenever it is time to update the body's position.
    def manage_movement
      return false unless @current_fiber
      
      if @current_fiber.respond_to? :call
        @current_fiber = MoveFiber.new &@current_fiber
      end
      
      @current_fiber.resume
      @current_fiber = nil if !@current_fiber.alive?
      true
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
    
    # TODO: change habits to run right before yielding and make "habit" to
    # set the next_update_period ?
    def wait_for_next_position_update(update_period = nil)
      if update_period
        body.next_update_period = update_period
      end
      Fiber.current.yield
    end
    
    def add_habit(*args, &proc); Fiber.current.add_habit(*args, &proc); end
    def delete_habit(*args, &proc); Fiber.current.delete_habit(*args, &proc); end
    def with_habit(*args, &proc); Fiber.current.with_habit(*args, &proc); end
    def timeout(*args, &proc); Fiber.current.timout(*args, &proc); end
  end
end