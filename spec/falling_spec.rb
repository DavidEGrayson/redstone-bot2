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
    bot.fall_update
    bot.body.position.should == nil
  end
end