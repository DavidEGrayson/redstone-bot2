require_relative 'spec_helper'

describe TestBot do
  before do
    @bot = TestBot.new_at_position(RedstoneBot::Coords[0, 64, 0])
  end

  it "does not use any real threads" do
    expect(Thread.list.size).to eq(1)
  end
  
  it "has an awesome wait_until method" do
    # NOTE: wait_until actually waits for packets to be received before
    # checking the condition again, so this test isn't very accurate.
    # Calling brain.run shouldn't be allowed, the way we are doing it here;
    # we should be required to feed some packet to the client to make the brain
    # get activated.
   
    @bot.require_brain do
      @bot.wait_until { @foo }
    end

    3.times do
      @bot.brain.run
      expect(@bot.brain).to be_alive
    end
    
    @foo = true
    @bot.brain.run
    expect(@bot.brain).not_to be_alive
  end
end