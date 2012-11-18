require_relative 'test_regular_updater'
require_relative 'test_condition'

# This module reimplements everything that RedstoneBot::Synchronizer does, but
# in a way that makes it easier to test.
module TestSynchronizer
  def mutex
    raise "Direct access to the mutex should not happen during tests."
  end

  def synchronize(&block)
    yield
  end
  
  def delay(time)
  end
  
  def regular_updater(default_period, &block)
    TestRegularUpdater.new(self, default_period, &block)
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
end

class TestStandaloneSynchronizer
  include TestSynchronizer
end