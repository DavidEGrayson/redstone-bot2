require "fiber"

module RedstoneBot
  class MoveFiber < Fiber
    def initialize
      super
      @habits = []
    end
  
    def yield(*args)
      raise "MoveFiber#yield should only be called on the current fiber." if !Fiber.current.eql?(self)
      Fiber.yield(*args)
      @habits.each &:call
    end
    
    def add_habit(habit=nil, &proc)
      raise ArgumentError.new("Choose either a habit or a proc.") if (habit && proc) || !(habit || proc)
      @habits << (habit || proc)
    end
    
    def delete_habit(habit)
      @habits.delete habit
    end
    
    def with_habit(habit)
      begin
        add_habit(habit)
        yield
      ensure
        delete_habit(habit)
      end
    end
  end
end