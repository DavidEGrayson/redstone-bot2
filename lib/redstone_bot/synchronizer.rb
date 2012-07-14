module RedstoneBot
  module Synchronizer
    def synchronize(&block)
      @mutex.synchronize(&block)
    end
    
    def regularly(time, &block)
      Thread.new do
        while true
          sleep time
          synchronize &block
        end
      end
    end

    def later(time, &block)
      Thread.new do
        sleep time
        synchronize &block
      end
    end
  end
end