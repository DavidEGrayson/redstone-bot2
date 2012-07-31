require_relative "spec_helper"

require "redstone_bot/item_types"
require "redstone_bot/pathfinder"
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
    RedstoneBot::Pathfinder.should be_a_kind_of Class
  end
  
  it "knows the start point" do
    pathfinder.start.should == RedstoneBot::Coords[1,71,1]
  end
  
  it "can tell if a node is a goal" do
    pathfinder.is_goal?(RedstoneBot::Coords[1, 71, 1]).should be false
    pathfinder.is_goal?(RedstoneBot::Coords[5, 71, 8]).should be true
  end
  
  it "can calculate costs between neighboring points" do
    pathfinder.cost(RedstoneBot::Coords[1,71,1], RedstoneBot::Coords[1,71,2]).should == 1
  end
  
  it "can estimate costs between any points" do
    pathfinder.heuristic_cost_estimate(RedstoneBot::Coords[4,71,7]).should == 2
  end
  
  it "can find the neighbors of a point on a flat plane" do
    Set.new(pathfinder.neighbors(RedstoneBot::Coords[1,71,1])).should ==
      Set.new([
                  [1, 71, 2], 
      [0, 71, 1], [1, 72, 1], [2, 71, 1],
                  [1, 71, 0],
      ].collect { |a| RedstoneBot::Coords[*a] })
  end
  
  it "can find paths" do
    path = pathfinder.find_path
    path.first.should == pathfinder.start
    path.each_cons(2) do |a, b|
      pathfinder.distance(a, b).should < 2
    end
    path.last.should == pathfinder.goal
    path.size.should == 12
    # path.each { |n| n.inspect }
  end
  
end