
module RedstoneBot
  # An action that is composed of other actions
  class MultiAction
  
    def initialize(*actions)
      @enum = actions.to_enum
    end
  
    def started?
      @started
    end

    def next_action
      @current_action = begin
        @enum.next
      rescue StopIteration
        nil
      end
    end
    
    def start(body)
      @started = true
      next_action
    end
    
    def update_position(body)
      return if !started? || done?
      
      if !@current_action
        @done = true         # success
        return
      end
      
      if @current_action.done?
        next_action        
      else
        @current_action.start(body) unless @current_action.started?
        @current_action.update_position(body)
      end
    end
    
    def done?
      @done
    end
  end
end