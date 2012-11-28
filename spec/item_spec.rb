require 'redstone_bot/protocol/item'

describe RedstoneBot::Item do
  it "matches spots that hold the same item" do
    item = RedstoneBot::ItemType::Wood * 1
    spot = RedstoneBot::Spot.new(RedstoneBot::ItemType::Wood * 1)
    item.should === spot
  end
end