require_relative 'test_bot'

describe RedstoneBot::Falling do
  let :bot do
    b = TestBot.new
    b.start_bot
    b
  end

  before do
    bot.client << RedstoneBot::Packet::PlayerPositionAndLook.new(0, 70, 0, 70+1.62, 0, 0, false)    
  end
  
  it "falls" do
    bot.body.updater.default_period.should == 0.05
    default_fall_speed = 10
    
    bot.fall_update
    bot.body.position.should be_within(0.001).of RedstoneBot::Coords[0, 69.5, 0]

    bot.fall_update
    bot.body.position.should be_within(0.001).of RedstoneBot::Coords[0, 69.0, 0]
  end
end