module RedstoneBot
  module Falling
    def fall(opts={})
      return unless require_brain { fall opts }

      move_loop(opts[:update_period]) do
        break if fall_update(opts)
      end
    end
  
    def fall_update(opts={})
      speed = opts[:speed] || 10
      update_period = opts[:update_period] || body.default_period
      
      ground = find_nearby_ground || -1
      
      max_distance = speed * update_period
      
      dy = ground - body.position.y
      if dy.abs > max_distance
        dy = dy.to_f/dy.abs*max_distance
      end
      
      body.position.y += dy
      
      return (body.position.y - ground).abs < 0.2
    end
    
    def find_nearby_ground
      x,y,z = body.position.to_a
      # the body is a 0.6 x 0.6 square centered around the body.position
      # need to check all of the columns for a possible solid block we could be standing on
      columns = [[x+0.3,z+0.3],
                 [x-0.3,z+0.3],
                 [x+0.3,z-0.3],
                 [x-0.3,z-0.3]]
      y.ceil.downto(y.ceil-10).each do |test_y|
        columns.each do |column_x,column_z|
          block_type = chunk_tracker.block_type([column_x.floor, test_y, column_z.floor])
          block_type ||= ItemType::Air    # block_type is nil if it is in an unloaded chunk
          if block_type.solid?
            return test_y + 1
          end
        end
      end
      nil
    end
  end
end