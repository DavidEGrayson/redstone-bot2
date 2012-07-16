module RedstoneBot
  class Pathfinder
    attr_reader :chunk_tracker
    
    # triplets of integers representing [x,y,z] coords
    attr_accessor :start, :goal
    
    # [xmin..xmax, ymin..ymax, zmin..zmax]
    attr_accessor :bounds
  
    def initialize(chunk_tracker)
      @chunk_tracker = chunk_tracker
    end
    
    def find_path
      "dunno"
    end
  end
end