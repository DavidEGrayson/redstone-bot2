module RedstoneBot
  # TODO: get more reliable timing by using Time.now to compute how long to sleep
  class RegularUpdater
    attr_accessor :proc
    attr_accessor :default_period
    attr_accessor :next_period
    attr_reader :last_period
    
    def initialize(synchronizer, default_period, &block)
      @synchronizer = synchronizer
      @default_period = default_period
      @proc = block
      start_thread
    end
    
    def start_thread
      Thread.new do
        while true
          update_periods
          sleep @last_period
          
          @synchronizer.synchronize &proc
        end
      end
    end
    
    def update_periods
      @last_period = @next_period || @default_period
      @next_period = nil
    end
    
  end
end