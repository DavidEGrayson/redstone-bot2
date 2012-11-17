# This module reimplements everything that RedstoneBot::Synchronizer does, but
# in a way that makes it easier to test.
module NullSynchronizer
  def mutex
    raise "Direct access to the mutex should not happen during tests."
  end

  def synchronize(&block)
    yield
  end
  
  def delay(time)
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
end

class TestSynchronizer
  include NullSynchronizer
end