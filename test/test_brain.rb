require 'fiber'

class TestBrain
  attr_reader :fiber, :synchronizer

  def initialize(synchronizer)
    @synchronizer = synchronizer
  end
  
  def start
    stop
    @fiber = Fiber.new do
      begin
        yield
      ensure
        @fiber = nil
      end
    end
    nil
  end
  
  # This isn't great because ensure blocks in the fiber probably won't get run
  # in a timely manner, but it is hopefully good enough for tests.
  def stop
    @fiber = nil  
  end
  
  def alive?
    @fiber ? true : false
  end

  def running?
    Fiber.current == @fiber
  end
  
  def require(&proc)
    if running?
      true
    else
      start(&proc)
      false
    end
  end
  
  def run
    if @fiber
      @fiber.resume
    end
  end
end
