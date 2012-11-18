require_relative 'test_bot'

describe RedstoneBot::Falling do
  let :bot do
    b = TestBot.new(client)
    b.start_bot
    b
  end

  let :client do
    bot.client
  end
  
  before do
    #client << Packet::PlayerPositionAndLook.new(0, 70, 0, 0, 0, false)
    client << RedstoneBot::Packet::PlayerPositionAndLook.new(0, 70, 0, 70+1.62, 0, 0, false)
  end
  
  it "falls" do
    
  end
end