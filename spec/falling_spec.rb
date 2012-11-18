describe RedstoneBot::Falling do
  let :bot do
    TestBot.new_at_position RedstoneBot::Coords[0, 70, 0]
  end

  it "falls" do
    bot.body.updater.default_period.should == 0.05
    # Assumption: default fall speed is 10 m/s
    
    bot.body.updater.update   # should call fall_update
    bot.body.position.should be_within(0.001).of RedstoneBot::Coords[0, 69.5, 0]

    bot.body.updater.update
    bot.body.position.should be_within(0.001).of RedstoneBot::Coords[0, 69.0, 0]
  end
end