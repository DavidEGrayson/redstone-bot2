require_relative '../packet_printer'
require_relative '../tracks_types'
require_relative '../models/spot'
require_relative '../models/spot_array'
require_relative '../models/windows'

module RedstoneBot
  class WindowTracker
    attr_reader :inventory_window, :windows, :cursor_spot
    
    def initialize(client)
      @windows = []
      register_window @inventory_window = InventoryWindow.new
      @cursor_spot = Spot.new
      
      @client = client
      @client.listen &method(:receive_packet)
    end

    def receive_packet(packet)
      if @packet_ignorer
        if @packet_ignorer.call(packet)
          #$stderr.puts "ignored packet #{packet}"
          return
        else
          @packet_ignorer = nil
        end
      end
    
      receive_packet_filtered(packet)
      @last_packet = packet
    end
    
    def receive_packet_filtered(packet)
      return unless packet.respond_to?(:window_id)
      window_id = packet.window_id
      
      if packet.is_a?(Packet::OpenWindow)
        register_window Window.create(packet.type, packet.window_id, packet.spot_count, inventory_window.inventory)
        return
      end
      
      if packet.is_a?(Packet::SetSlot) && packet.cursor?
        cursor_spot.item = packet.item
        
        if @last_packet.is_a?(Packet::SetWindowItems)
          swi_packet = @last_packet
          ignore_packets_while do |packet|
            packet.is_a?(Packet::SetSlot) && packet.redundant_after?(swi_packet)
          end
        else
          $stderr.puts "Warning: received SetCursor packet but it was not right after a SetWindowItems packet.  @last_packet=#@last_packet"
          #@client.report_last_packets
        end
        
        # The window needs to know when the cursor is changed; it helps keep track of the rejection state.
        windows.last.server_set_cursor
        
        return
      end
      
      window = windows.find { |w| w.id == window_id }
      if !window
        $stderr.puts "#{@client.time_string}: warning: received packet for non-open window: #{packet}"
        return
      end
      
      case packet
      when Packet::SetWindowItems
        window.server_set_items packet.items
      when Packet::SetSlot
        window.server_set_item packet.spot_id, packet.item
      when Packet::CloseWindow
        unregister_window window
      when Packet::ConfirmTransaction
        if packet.accepted
          window.pending_actions.delete packet.action_number        
        else
          window.rejected!
          window.pending_actions.clear
          
          @client.send_packet packet
        end
      end
    end
    
    def <<(packet)  # this is for testing only
      receive_packet(packet)
    end

    def ignore_packets_while(&condition)
      @packet_ignorer = condition
    end
    
    # The Notchian server ignores inventory clicks while another window
    # is open.  This function tells you which window is currently usable.
    def usable_window
      window = @windows.last
      window if window.loaded?
    end
    
    def synced?
      @windows.last.synced?
    end
    
    def rejected?
      @windows.last.rejected?
    end

    def shift_click(spot)
      return if spot.empty?
    
      window, spot_id = ensure_clickable(spot)      
      spots = window.shift_click_destinations(spot)
      original_item = spot.item
      
      spots.non_empty_spots.each do |dest_spot|
        dest_spot.item, spot.item = dest_spot.item.try_stack(spot.item)
      end      
      
      empty_spot = spots.empty_spots.first
      if empty_spot
        empty_spot.item = spot.item
        spot.item = nil
      end

      # If this click will actually have an effect, send it.
      if original_item != spot.item
        @client.send_packet Packet::ClickWindow.new(window.id, spot_id, :left, new_transaction, true, original_item)
      end
    end
    
    def left_click(spot)
      return if cursor_spot.empty? && spot.empty?
    
      window, spot_id = ensure_clickable(spot)
            
      @client.send_packet packet = Packet::ClickWindow.new(window.id, spot_id, :left, new_transaction, false, spot.item)      
      #puts "#{@client.time_string} click: #{packet}"
      cursor_spot.item, spot.item = spot.item, cursor_spot.item
      nil
    end
    
    def swap(spot1, spot2)
      # TODO: expand this to do the right thing if the two spots have the same kind of item
      if !spot1.empty? && spot1.item_type == spot2.item_type
        raise "Not implemented: swapping two spots holding the same type of item."
      end
      
      left_click(spot1)
      left_click(spot2)
      left_click(spot1)      
      nil
    end
    
    # Throws the item in the spot outside the window.
    def dump(spot)
      return if spot.empty?
      
      window, spot_id = ensure_clickable(spot)
      @client.send_packet Packet::ClickWindow.new(window.id, spot_id, :left, new_transaction, false, spot.item)
      @client.send_packet Packet::ClickWindow.outside(new_transaction)
      spot.item = nil
    end
    
    def close_window
      raise "No window except inventory is open; cannot close a window." if @windows.size < 2
      window = @windows.last
      @client.send_packet Packet::CloseWindow.new(window.id)
      unregister_window(window)
      nil
    end
    
    # Pick up methods provided by the Window subclasses.
    Window.types.values.each do |klass|
      klass.provided_methods.each do |method_name|
        if instance_methods.include?(method_name)
          raise "#{klass} cannot provide #{method_name} method: #{self} already has it."
        end
        define_method(method_name) do
          window = windows.find { |w| klass === w }
          window.send(method_name) if window and window.loaded?
        end
      end
    end
    
    private
    def ensure_clickable(spot)
      window = usable_window
      spot_id = window.spot_id(spot)
      if !spot_id
        raise "Cannot left click on #{spot}; it is not in the currently-usable window."
      end
      [window, spot_id]
    end
    
    def new_transaction
      action_number = @client.next_action_number
      @windows.last.pending_actions.push action_number
      action_number
    end
    
    def register_window(window)
      @windows << window
    end
    
    def unregister_window(window)
      @windows.delete window
      # perhaps we should call a window.close function that forces loaded? to return false
      # just in case old copies of the window are lying around somewhere.
    end

  end

end