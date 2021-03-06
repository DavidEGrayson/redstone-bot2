require_relative 'spec_helper'

describe RedstoneBot::Movement do
  let :bot do
    TestBot.new_at_position RedstoneBot::Coords[0, 70, 0]
  end

  describe :move_to do
    it "works" do
      bot.move_to RedstoneBot::Coords[1, 70, 0]
      bot.brain.run
      bot.body.should be_busy
      
      bot.brain.run
      bot.body.position.should be_within(0.001).of(RedstoneBot::Coords[0.5, 70, 0])
      
      Thread.list.should have(1).items   # insist on single-threaded tests
      
      bot.brain.run
      bot.body.position.should be_within(0.001).of(RedstoneBot::Coords[1, 70, 0])
      # We don't necessarily want this; it would be OK if the brain shut down now but that's just how
      # things are built and I want the specs to tell me if it changes.
      bot.brain.should be_alive
      bot.body.should be_busy
      
      bot.brain.run
      bot.brain.should_not be_alive
      bot.body.should_not be_busy
    end
    
    it "wait for the position update at least once to ensure we don't accidentally block" do
      bot.move_to bot.body
      bot.brain.run
      bot.body.should be_busy
      bot.brain.run
      bot.brain.should_not be_alive
    end
  end
  
  describe :jump do
    it "works" do
      bot.jump
      bot.brain.run
      bot.body.should be_busy
      
      70.5.step(73, 0.5) do |y|
        bot.body.default_updater.run
        bot.brain.run
        bot.body.position.should be_within(0.001).of(RedstoneBot::Coords[0, y, 0])
      end
      
    end
  end
  
  #describe :miracle_jump do
  #  pending "works" do
  #    bot.miracle_jump 0, 1000
  #    bot.brain.run
  #    bot.body.position_update_condition_variable.waiters.should == [bot.brain.fiber]
  #    
  #    
  #  end
  #end
end