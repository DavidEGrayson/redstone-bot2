require_relative "spec_helper"

require "redstone_bot/block_types"
require "redstone_bot/pathfinder"

class TestMap
  def block_type(coords)
    if coords[1] <= 70
      return RedstoneBot::BlockType::Stone
    else
      return RedstoneBot::BlockType::Air
    end
  end
end

describe RedstoneBot::Pathfinder do
  let(:pathfinder) do
    p = RedstoneBot::Pathfinder.new($test_map)
    p.start = [1,71,1]
    p.bounds = [0..16, 68..78, 0..16]
    p.goal = [5, 71, 8]
    p
 end

  it "is a class" do
    RedstoneBot::Pathfinder.should be_a_kind_of Class
  end
  
  it "can find paths" do
    result = pathfinder.find_path
    # TODO: check the result
  end
  
  it "knows the start point" do
    pathfinder.start.should == [1,71,1]
  end
  
  it "can tell if a node is a goal" do
    pathfinder.is_goal?([1, 71, 1]).should be false
    pathfinder.is_goal?([5, 71, 8]).should be true
  end
  
  it "can calculate costs" do
    pathfinder.cost([1,71,1], [1,71,2]).should be_within(0.1).of(1)
    pathfinder.heuristic_cost_estimate([1,17,1], [2,17,2]).should be_within(0.1).of(1.41421356)
  end
  
end