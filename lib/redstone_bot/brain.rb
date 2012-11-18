require 'thread'

module RedstoneBot
  class Brain
    def initialize(synchronizer)
      @synchronizer = synchronizer
    end
    
    def start
      stop
      @thread = Thread.new do
        @synchronizer.synchronize do
          begin
            yield
          ensure
            @thread = nil
          end
        end
      end
      nil
    end
    
    def stop
      if @thread
        @thread.terminate
        @thread = nil
      end
    end
    
    def alive?
      (@thread and @thread.alive?) ? true : false
    end

    def running?
      Thread.current == @thread
    end    
    
    def require(&proc)
      if running?
        true
      else
        start(&proc)
        false
      end
    end
    
  end
end