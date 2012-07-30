require 'matrix'
require "redstone_bot/a_star"

module RedstoneBot
  class Pathfinder
    include AStar
  
    attr_reader :chunk_tracker
    
    attr_accessor :tolerance
        
    # triplets of integers representing [x,y,z] coords
    attr_accessor :start, :goal
    
    # [xmin..xmax, ymin..ymax, zmin..zmax]
    attr_accessor :bounds
  
    def initialize(chunk_tracker, tolerance = 0.1)
      @chunk_tracker = chunk_tracker
      @tolerance = tolerance
    end
    
    def find_path
      run_a_star
    end
    
    def is_goal?(coords)
      distance(coords, goal) <= tolerance and on_ground?(coords)
    end
    
    def cost(from_coords, to_coords)
      # TODO: add a little something here to discourage flying and jumping and going through 1-tall holes
      cost = distance(from_coords, to_coords)
      cost += 10 if !on_ground?(from_coords) && !on_ground?(to_coords)
      cost
    end
    
    def heuristic_cost_estimate(from_coords)
      distance from_coords, goal
    end
    
    def distance(a, b)
      (Vector[*a] - Vector[*b]).magnitude
    end
    
    def neighbors(coords)
      x,y,z = coords
      candidates = [[x-1, y, z], [x+1, y, z], [x, y-1, z], [x, y+1, z], [x, y, z-1], [x, y, z+1]]
      candidates.select do |n|
        # TODO: reject points that are out of bounds

        #puts "#{n} #{@chunk_tracker.block_type(n)}"
        one_up = [n[0],n[1]+1,n[2]]
        !@chunk_tracker.block_type(n).solid? && !@chunk_tracker.block_type(one_up).solid?
      end
    end    
    
    def timeout
      2
    end
    
    def on_ground?(coords)
      below = [coords[0],coords[1]-1,coords[2]]
      @chunk_tracker.block_type(below).solid?
    end
  end
end