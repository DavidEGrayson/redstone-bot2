describe RedstoneBot::Falling do
  let :bot do
    TestBot.new_at_position RedstoneBot::Coords[0, 70, 0]
  end

  it "falls" do
    # Assumption: default fall speed is 10 m/s, period is 0.05 ms
    
    bot.body.default_updater.run   # should delay
    bot.body.default_updater.run   # should call fall_update and then delay
    expect(bot.body.position).to be_within(0.001).of RedstoneBot::Coords[0, 69.5, 0]

    bot.body.default_updater.run
    expect(bot.body.position).to be_within(0.001).of RedstoneBot::Coords[0, 69.0, 0]
  end
end