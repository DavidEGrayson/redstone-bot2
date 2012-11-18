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
      bot.brain.run
      bot.body.position.should be_within(0.001).of(RedstoneBot::Coords[0.5, 70, 0])
    end
  end
end