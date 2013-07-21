require_relative 'test_condition'

# This module reimplements everything that RedstoneBot::Synchronizer does, but
# in a way that makes it easier to test.
module TestSynchronizer
  attr_reader :change_condition

  def setup_synchronizer
    @change_condition ||= new_condition
  end
  
  def mutex
    raise "Direct access to the mutex should not happen during tests."
  end

  def synchronize(&block)
    yield
  end
  
  def delay(time)
    Fiber.yield
  end
  
  def wait_until(&condition)
    while !condition.call
      Fiber.yield
    end
  end
  
  def regularly(time, &block)
    raise NotImplementedError.new  
  end  

  def later(time, &block)
    raise NotImplementedError.new  
  end
  
  def time(min, max=nil)
    raise NotImplementedError.new    
  end
  
  def timeout(*args, &block)
    raise NotImplementedError.new
  end
  
  def timeout!(*args, &block)
    raise NotImplementedError.new
  end
  
  def new_condition
    TestCondition.new(self)
  end
  
  def new_brain
    TestBrain.new(self)
  end
end

class TestStandaloneSynchronizer
  include TestSynchronizer
  
  def initialize
    setup_synchronizer
  end
end