require 'set'

module AStar
  def run_a_star
    closed_set = Set[]
    open_set = Set[start]
    
    came_from = {}
    g_score = {}
    g_score[start] = 0
    f_score = {}
    f_score[start] = g_score[start] + heuristic_cost_estimate(start)
    
    while !open_set.empty?
      current = open_set.min_by { |n| f_score[n] }
      
      puts "current = #{current.inspect}"
      sleep 1
      
      if is_goal?(current)
        return reconstruct_path(came_from, current)
      end
      
      open_set.delete current
      closed_set.add current
      
      neighbors(current).each do |neighbor|
        next if closed_set.include?(neighbor)
        
        tentative_g_score = g_score[current] + distance(current, neighbor)
        
        old_g_score = g_score[neighbor]
        
        if old_g_score.nil? or old_g_score > tentative_g_score
          open_set.add neighbor
          came_from[neighbor] = current
          g_score[neighbor] = tentative_g_score
          f_score[neighbor] = tentative_g_score + heuristic_cost_estimate(neighbor)
        end
      end
    end
    
    return nil
  end
  
  def reconstruct_path(came_from, node)
    path = [node]
    while came_from.has_key?(node)
      node = came_from[node]
      path << node
    end
    path.reverse
  end
  
end