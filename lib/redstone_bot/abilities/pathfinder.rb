require_relative "a_star"
require_relative "coords"

module RedstoneBot
  class Pathfinder
    include AStar
  
    attr_reader :chunk_tracker
    
    attr_accessor :tolerance
    attr_accessor :flying_aversion
    
    # start and goald should be Coords object with integers in them
    attr_accessor :start, :goal
  
    def initialize(chunk_tracker, opts={})
      @chunk_tracker = chunk_tracker
      @tolerance = opts[:tolerance] || 0.1
      @flying_aversion = opts[:flying_aversion] || 2
    end
    
    def find_path
      raise "Pathfinder: Invalid start: #{start}" unless start.int_coords?
      raise "Pathfinder: Invalid goal: #{start}" unless goal.int_coords?    
      run_a_star
    end
    
    def is_goal?(coords)
      distance(coords, goal) <= tolerance and on_ground?(coords)
    end
    
    def cost(from_coords, to_coords)
      # TODO: add a little something here to discourage flying and jumping and going through 1-tall holes
      cost = distance(from_coords, to_coords)
      cost += flying_aversion if !on_ground?(from_coords) && !on_ground?(to_coords)
      cost
    end
    
    def heuristic_cost_estimate(from_coords)
      distance from_coords, goal
    end
    
    def distance(a, b)
      # Manhattan distance
      (a.x - b.x).abs + (a.y - b.y).abs + (a.z - b.z).abs
    end
    
    def neighbors(coords)
      candidates = [coords - Coords::X, coords + Coords::X,
                    coords - Coords::Y, coords + Coords::Y,
                    coords - Coords::Z, coords + Coords::Z]
      candidates.select do |c|
        !@chunk_tracker.block_type(c).solid? && !@chunk_tracker.block_type(c + Coords::Y).solid?
      end
    end    
    
    def timeout
      2
    end
    
    def on_ground?(coords)
      @chunk_tracker.block_type(coords - Coords::Y).solid?
    end
  end
end