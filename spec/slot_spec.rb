require 'redstone_bot/trackers/spot'
require 'redstone_bot/protocol/item_types'

describe RedstoneBot::Slot do
  it "matches spots that hold the same item" do
    item = RedstoneBot::ItemType::Wood * 1
    spot = RedstoneBot::Spot.new(RedstoneBot::ItemType::Wood * 1)
    item.should === spot
  end
end