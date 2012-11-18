class TestCondition
  def initialize(synchronizer)
    @waiters = []
  end

  def wait
    @waiters << Fiber.current
    Fiber.yield
  end
  
  def broadcast
    waiters = @waiters.dup
    @waiters.clear
    waiters.each do |waiter|
      # TODO: for testing purposes, tell the Fiber that it would be woken up?
    end
  end
  
  def waiters_count
    @waiters.count
  end
end