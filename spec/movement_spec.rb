require_relative 'spec_helper'

describe RedstoneBot::Movement do
  let :bot do
    TestBot.new_at_position RedstoneBot::Coords[0, 70, 0]
  end

  describe :move_to do
    before do
      bot.move_to RedstoneBot::Coords[1, 70, 0]
    end
  
    it "works" do
      bot.brain.run
      bot.body.updater.update
      bot.body.position.should == :something
    end
  end
end