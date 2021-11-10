require_relative "spec_helper"

require "redstone_bot/protocol/item_types"
require "redstone_bot/abilities/pathfinder"
require "set"

class TestMap
  def block_type(coords)
    if coords[1] <= 70
      return RedstoneBot::ItemType::Stone
    else
      return RedstoneBot::ItemType::Air
    end
  end
end

describe RedstoneBot::Pathfinder do
  let(:pathfinder) do
    p = RedstoneBot::Pathfinder.new(TestMap.new)
    p.start = RedstoneBot::Coords[1,71,1]
    #p.bounds = [0..16, 68..78, 0..16]
    p.goal = RedstoneBot::Coords[5, 71, 8]
    p
 end

  it "is a class" do
    expect(RedstoneBot::Pathfinder).to be_a_kind_of Class
  end
  
  it "knows the start point" do
    expect(pathfinder.start).to eq(RedstoneBot::Coords[1,71,1])
  end
  
  it "can tell if a node is a goal" do
    expect(pathfinder.is_goal?(RedstoneBot::Coords[1, 71, 1])).to be false
    expect(pathfinder.is_goal?(RedstoneBot::Coords[5, 71, 8])).to be true
  end
  
  it "can calculate costs between neighboring points" do
    expect(pathfinder.cost(RedstoneBot::Coords[1,71,1], RedstoneBot::Coords[1,71,2])).to eq(1)
  end
  
  it "can estimate costs between any points" do
    expect(pathfinder.heuristic_cost_estimate(RedstoneBot::Coords[4,71,7])).to eq(2)
  end
  
  it "can find the neighbors of a point on a flat plane" do
    expect(Set.new(pathfinder.neighbors(RedstoneBot::Coords[1,71,1]))).to eq(
      Set.new([
                  [1, 71, 2], 
      [0, 71, 1], [1, 72, 1], [2, 71, 1],
                  [1, 71, 0],
      ].collect { |a| RedstoneBot::Coords[*a] })
    )
  end
  
  it "can find paths" do
    path = pathfinder.find_path
    expect(path.first).to eq(pathfinder.start)
    path.each_cons(2) do |a, b|
      expect(pathfinder.distance(a, b)).to be < 2
    end
    expect(path.last).to eq(pathfinder.goal)
    expect(path.size).to eq(12)
    # path.each { |n| n.inspect }
  end
  
end