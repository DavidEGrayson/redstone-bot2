require 'thread'
require 'forwardable'

# monkeypatch the standard ruby class
class ConditionVariable
  def waiters_count
    @waiters_mutex.synchronize do
      @waiters.count
    end
  end
end

module RedstoneBot
  class Condition
    extend Forwardable
  
    def initialize(synchronizer)
      @synchronizer = synchronizer
      @condition_variable = ConditionVariable.new
    end
    
    def wait
      @condition_variable.wait(@synchronizer.mutex)
    end
    
    def_delegators :@condition_variable, :waiters_count, :broadcast
  end
end