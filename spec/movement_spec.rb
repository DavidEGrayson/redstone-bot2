require_relative 'spec_helper'

describe RedstoneBot::Movement do
  let :bot do
    TestBot.new_at_position RedstoneBot::Coords[0, 70, 0]
  end

  describe :move_to do
    it "works" do
      bot.move_to RedstoneBot::Coords[1, 70, 0]
      bot.brain.run
      expect(bot.body).to be_busy
      
      bot.brain.run
      expect(bot.body.position).to be_within(0.001).of(RedstoneBot::Coords[0.5, 70, 0])
      
      expect(Thread.list.size).to eq(1)   # insist on single-threaded tests
      
      bot.brain.run
      expect(bot.body.position).to be_within(0.001).of(RedstoneBot::Coords[1, 70, 0])
      # We don't necessarily want this; it would be OK if the brain shut down now but that's just how
      # things are built and I want the specs to tell me if it changes.
      expect(bot.brain).to be_alive
      expect(bot.body).to be_busy
      
      bot.brain.run
      expect(bot.brain).not_to be_alive
      expect(bot.body).not_to be_busy
    end
    
    it "wait for the position update at least once to ensure we don't accidentally block" do
      bot.move_to bot.body
      bot.brain.run
      expect(bot.body).to be_busy
      bot.brain.run
      expect(bot.brain).not_to be_alive
    end
  end
  
  describe :jump do
    it "works" do
      bot.jump
      bot.brain.run
      expect(bot.body).to be_busy
      
      70.5.step(73, 0.5) do |y|
        bot.body.default_updater.run
        bot.brain.run
        expect(bot.body.position).to be_within(0.001).of(RedstoneBot::Coords[0, y, 0])
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