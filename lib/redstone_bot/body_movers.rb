# Module with some functions to help your bot move its body.
# The blocking functions should only be called from inside a Fiber.
# Can be included into your bot as long as you have these things:
# A 'body' method that returns the RedstoneBot::Body.
# A 'chunk_tracker' method that returns a RedstoneBot::ChunkTracker.
#
# NOTE: David is not totally convinced that this should be a module instead
# of a class.  Any class that calls these body-moving functions should be
# built with the assumption that it could be either.
module RedstoneBot
  module BodyMovers
    
    def start_move_to(*args)
      body.start { move_to *args }
    end
    
    def start_jump(*args)
      body.start { jump *args }
    end
    
    def start_miracle_jump(*args)
      body.start { miracle_jump *args }
    end
    
    def miracle_jump(x, z)
      opts = { :update_period => 0.01, :speed => 600 }
      jump_to_height 276, opts
      move_to Coords[x, 257, z], opts
      fall opts
    end
    
    def move_to(coords, opts={})
      tolerance = opts[:tolerance] || 0.2
      speed = opts[:speed] || 10
      axes = [Coords::X, Coords::Y, Coords::Z].cycle
      
      while true
        body.wait_for_next_position_update(opts[:update_period])
        body.look_at coords

        d = coords - body.position
        if d.norm < tolerance
          return # reached it
        end
      
        max_distance = speed*body.last_update_period
        if d.norm > max_distance
          d = d.normalize*max_distance
        end
      
        if body.bumped?
          d = d.project_onto_unit_vector(axes.next)*3
        end
      
        body.position += d
      end
      
    end
    
    def jump(dy=3, opts={})
      jump_to_height body.position.y + dy, opts
    end
    
    def jump_to_height(y, opts={})
      speed = opts[:speed] || 10
    
      while body.position.y <= y
        body.wait_for_next_position_update(opts[:update_period])
        body.position.y += speed*body.last_update_period
        if body.bumped?
          return false   # the head got bumped
        end
      end
      return true
    end
	
    def fall(opts={})
      while true
        body.wait_for_next_position_update(opts[:update_period])
        break if fall_update(opts)
      end
    end
          
    def fall_update(opts={})
      speed = opts[:speed] || 10
      
      ground = find_nearby_ground || -1
      
      max_distance = speed * body.last_update_period
      
      dy = ground - body.position.y
      if dy.abs > max_distance
        dy = dy.to_f/dy.abs*max_distance
      end
      
      body.position.y += dy
      
      return (body.position.y - ground).abs < 0.2
    end
    
    # TODO: clean this up to do proper collision detecting, probably need to check multiple columns
    # and to_i is not the right thing to use
    def find_nearby_ground
      x,y,z = body.position.to_a
      y.ceil.downto(y.ceil-10).each do |test_y|
        block_type = chunk_tracker.block_type([x.to_i, test_y, z.to_i])
        block_type ||= BlockType::Air    # block_type is nil if it is in an unloaded chunk
        if block_type.solid?
          return test_y + 1
        end
      end
      nil
    end
    
    def position
      body.position
    end
    
  end
end