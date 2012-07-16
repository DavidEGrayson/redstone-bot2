require_relative "spec_helper"

require "redstone_bot/block_types"
require "redstone_bot/pathfinder"

describe RedstoneBot::Pathfinder do
  it "is a class" do
    RedstoneBot::Pathfinder.should be_a_kind_of Class
  end
end