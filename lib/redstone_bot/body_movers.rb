# Module with some functions to help your bot move its body.
# The blocking functions should only be called from inside a Fiber.
# Can be included into your bot as long as you have these things:
# A 'body' method that returns the RedstoneBot::Body.
# A 'chunk_tracker' method that returns a RedstoneBot::ChunkTracker.
module RedstoneBot
  module BodyMovers
      
    def miracle_jump(x, z)
      opts = { :update_period => 0.01, :speed => 600 }
      jump_to_height 276, opts
      move_to Coords[x, 257, z], opts
      fall opts
    end
    
  end
end