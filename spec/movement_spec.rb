require_relative 'spec_helper'

describe RedstoneBot::Movement do
  let :bot do
    TestBot.new_at_position RedstoneBot::Coords[0, 70, 0]
  end

  describe :move_to do
    it "works" do
      bot.move_to RedstoneBot::Coords[1, 70, 0]
      bot.brain.run
      bot.body.position_update_condition_variable.waiters.should == [bot.brain.fiber]
      
      bot.body.updater.update
      bot.brain.run
      bot.body.position.should be_within(0.001).of(RedstoneBot::Coords[0.5, 70, 0])
      
      Thread.list.should have(1).items   # insist on single-threaded tests
      
      bot.body.updater.update
      bot.brain.run
      bot.body.position.should be_within(0.001).of(RedstoneBot::Coords[1, 70, 0])
      bot.brain.should_not be_alive
    end
  end
  
  describe :jump do
    it "works" do
      bot.jump
      bot.brain.run
      bot.body.position_update_condition_variable.waiters.should == [bot.brain.fiber]
      
      bot.body.updater.update
      bot.brain.run
      bot.body.position.should be_within(0.001).of(RedstoneBot::Coords[0, 70.5, 0])
    end
  end
end