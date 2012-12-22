# Module with some functions to help your bot move its body.
# Can be included into your bot as long as you have these things:
# A 'body' method that returns the RedstoneBot::Body.
# A 'chunk_tracker' method that returns a RedstoneBot::ChunkTracker.
#
# NOTE: David is not totally convinced that this should be a module instead
# of a class.  Any class that calls these body-moving functions should be
# built with the assumption that it could be either.

require_relative 'pathfinder'

module RedstoneBot
  module Movement
    
    def miracle_jump(x, z)
      return unless require_brain { miracle_jump x, z }

      opts = { :update_period => 0.01, :speed => 600 }
      jump_to_height 276, opts
      move_to Coords[x, 257, z], opts
      fall opts
      
      #chat "I be at #{body.position} after #{Time.now - @start_fly} seconds."
    end
    
    def follow(opts={}, &block)
      return unless require_brain { follow opts, &block }

      opts = opts.dup
      opts[:pathfinder] ||= Pathfinder.new(chunk_tracker, tolerance: 3, flying_aversion: 2)
      while true
        target = yield
        break if target.nil?
        target = target.to_coords
        if (body.position - target).abs <= 1
          delay 0.05
        else
          case path_to target, opts
          when :solid, nil
            delay 0.05
          when :no_path
            chat "cant get to U"
            body.delay 10
          end
        end
      end
      chat "lost U"
    end
    
    def path_to(target, opts={})
      return unless require_brain { path_to target, opts }

      target = target.to_coords.to_int_coords
      pathfinder = opts[:pathfinder] || Pathfinder.new(chunk_tracker)
      
      return :solid if chunk_tracker.block_type(target).solid?
      
      pathfinder.start = body.position.to_int_coords
      pathfinder.goal = target
      path = pathfinder.find_path
      return :no_path unless path
      
      path.each do |waypoint|
        center = waypoint + Coords[0.5,0,0.5]
        move_to center, opts
      end
      
      return nil
    end
    
    def move_to(target, opts={})
      return unless require_brain { move_to target, opts }

      target = target.to_coords
    
      tolerance = opts[:tolerance] || 0.2
      speed = opts[:speed] || 10
      axes = [Coords::X, Coords::Y, Coords::Z].cycle
      
      move_loop(opts[:update_period]) do |period|
        d = target - body.position
        if d.norm < tolerance
          return # reached it
        end

        body.look_at target
                
        if body.bumped?
          d = d.project_onto_unit_vector(axes.next)
        end
        
        max_distance = speed * period
        if d.norm > max_distance
          d = d.normalize*max_distance
        end
        
        body.position += d
      end
      
    end
    
    def jump(dy=3, opts={})
      jump_to_height body.position.y + dy, opts
    end
    
    def jump_to_height(y, opts={})
      return unless require_brain { jump_to_height y, opts }
    
      speed = opts[:speed] || 10
    
      move_loop(opts[:update_period]) do |period|
        if body.position.y >= y
          return
        end
        
        if body.bumped?
          chat "I bumped my head!"
          return :bumped
        end
        
        body.position += Coords::Y * (speed * period)
      end
    end
	
  end
end