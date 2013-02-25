require_relative 'spec_helper'

class Graph1
  include RedstoneBot::AStar
  
  def start
    :start
  end

  def is_goal?(node)
    node == :goal
  end 
  
  Heuristic = {start: 3, a: 3, b: 3, c: 1, d: 2, goal: 0}
  
  EdgeCosts = {
    %i[start a] => 2,
    %i[start, b] => 1,
    %i[a b]     => 1,
    %i[a c]     => 3,
    %i[a d]     => 1,
    %i[b d]     => 5,
    %i[b goal]  => 10,
    %i[c goal]  => 7,
    %i[d goal]  => 4
  }

  def cost(n1, n2)
    EdgeCosts[[n1, n2]]
  end
  
  def heuristic_cost_estimate(node)
    Heuristic[node]
  end
  
  def neighbors(node)
    EdgeCosts.keys.select { |e| e.first == node }.map(&:last)
  end
  
  def timeout
    60
  end
end

describe Graph1 do
  it "finds the optimal path" do
    subject.run_a_star.should == [:start, :a, :d, :goal]
  end
end