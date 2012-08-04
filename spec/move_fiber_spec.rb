require_relative "spec_helper"
require "redstone_bot/move_fiber"

describe RedstoneBot::MoveFiber do
  before do
    @habit = double("habit")
  end

  it "is a subclass of fiber" do
    RedstoneBot::MoveFiber.superclass.should == Fiber
  end
  
  it "has a yield method that basically calls Fiber.yield" do
    @mf = RedstoneBot::MoveFiber.new do
      Fiber.current.yield 0
      Fiber.current.yield "hey", false
      "hi"
    end
    
    @mf.resume.should == 0
    @mf.resume.should == ["hey", false]
    @mf.resume.should == "hi"
  end
  
  it "yield method should only be called from inside the fiber" do
    @mf = RedstoneBot::MoveFiber.new {}
    @mf2 = RedstoneBot::MoveFiber.new { @mf.yield }    
    lambda { @mf2.resume }.should raise_error
  end

  it "supports habits as objects with call methods" do
    @mf = RedstoneBot::MoveFiber.new do
      Fiber.current.yield 0
      Fiber.current.add_habit @habit
      Fiber.current.yield 1
    end
    
    @mf.resume.should == 0
    @mf.resume.should == 1
    @habit.should_receive(:call).once
    @mf.resume
  end
  
  it "supports habits as blocks" do
    @mf = RedstoneBot::MoveFiber.new do
      Fiber.current.yield 0
      Fiber.current.add_habit { @habit.call }
      Fiber.current.yield 1
    end
    
    @mf.resume.should == 0
    @mf.resume.should == 1
    @habit.should_receive(:call).once
    @mf.resume
  end
  
  it "supports deleting habits" do
    @mf = RedstoneBot::MoveFiber.new do
      Fiber.current.yield 0
      Fiber.current.add_habit @habit
      Fiber.current.yield 1
      Fiber.current.delete_habit @habit
      Fiber.current.yield 2      
    end
    
    @mf.resume.should == 0
    @mf.resume.should == 1
    @habit.should_receive(:call).once
    @mf.resume.should == 2
    @mf.resume
  end

  it "supports temporary habits inside a block" do
    @mf = RedstoneBot::MoveFiber.new do
      Fiber.current.yield 0

      catch(:hey) do
        Fiber.current.with_habit(@habit) do
          Fiber.current.yield 1
          Fiber.current.yield 2
          throw :hey
          Fiber.current.yield 3
        end
      end
      Fiber.current.yield 4
    end
    
    @mf.resume.should == 0
    @mf.resume.should == 1
    @habit.should_receive(:call).twice
    @mf.resume.should == 2
    @mf.resume.should == 4
    @mf.instance_variable_get(:@habits).should be_empty
    @mf.resume
    
  end
  
  it "supports timeout-like habits" do
    class << @habit
      def call
        @times ||= 0
        @times += 1
        throw :timeout if @times == 5
      end
    end
    
    @mf = RedstoneBot::MoveFiber.new do
      catch(:timeout) do
        Fiber.current.with_habit(@habit) do
          100.times do
            Fiber.current.yield 0
          end
        end
      end
      Fiber.current.yield 1
    end
    
    @mf.resume.should == 0
    @mf.resume.should == 0
    @mf.resume.should == 0
    @mf.resume.should == 0
    @mf.resume.should == 0
    @mf.resume.should == 1
  end
  
  it "has a timeout method" do
    @mf = RedstoneBot::MoveFiber.new do
      Fiber.current.timeout(0.05) do
        loop do
          Fiber.current.yield
        end
      end
      true
    end
    
    end_time = Time.now + 0.07
    while !@mf.resume
      raise "Failed to time out" if Time.now > end_time
    end
  end
  
  it "can do nested timeouts" do
    @mf = RedstoneBot::MoveFiber.new do
      Fiber.current.timeout(0.20) do
        20.times do |n|
          Fiber.current.timeout(0.05) do
            loop do
              Fiber.current.yield n
            end
          end
        end
        nil
      end
    end
    
    responses = []
    loop do
      result = @mf.resume
      break unless result
      responses << result unless responses.include?(result)
    end
    
    responses.should == (0..3).to_a
    
    @mf.instance_variable_get(:@habits).should be_empty
  end
end