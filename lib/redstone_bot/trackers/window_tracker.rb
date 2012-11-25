require_relative '../packet_printer'
require_relative '../tracks_types'
require_relative 'spot'
require_relative 'spot_array'

# Rejection experiments, trying to figure out exactly 
#
# cursor = nil
# hotbar spot 8 = WheatItem*64
# tmphax set hotbar spot 8 to a Diamond Axe
# left click on hotbar spot 8:
#   SetWindowItems
#   SetSlot for the cursor: Wheat * 64
#   SetSlot for the item you clicked on: nil
#
# cursor = nil
# hotbar spot 1 = nil
# tmphax set hotbar spot 1 to a Diamond Axe
# left click on hotbar spot 1:
#   SetWindowItems
#   SetSlot for cursor: nil
#
# cursor = nil
# hotbar spot 6 = WheatItem * 64
# tmphax set hotbar spot 6 to nil and pretend we have something on the cursor
# left click on hotbar spot 6:
#   SetWindowItems
#   SetSlot for cursor: WheatItem*64
#   SetSlot for the clicked spot: nil
#
# cursor = WheatItem*64
# hotbar spot 8 = nil
# tmphax set hotbar spot 8 to Diamond Axe
# left click on hotbar spot 8
#   SetWindowItems
#   SetSlot for cursor: nil
#   SetSlot for clicked spot: WheatItem*64


module RedstoneBot
  class WindowTracker
    attr_reader :inventory_window, :windows, :cursor_spot
    
    def initialize(client)
      @windows = []
      register_window @inventory_window = InventoryWindow.new
      @cursor_spot = Spot.new
      
      @client = client
      @client.listen { |p| receive_packet p }
    end

    def receive_packet(packet)
      return unless packet.respond_to?(:window_id)
      window_id = packet.window_id
      
      if packet.is_a?(Packet::OpenWindow)
        register_window Window.create(packet.type, packet.window_id, packet.spot_count, inventory_window.inventory)
        return
      end
      
      if packet.is_a?(Packet::SetSlot) && packet.cursor?
        cursor_spot.item = packet.slot
        
        #if client.last_packets[-2].is_a?(Packet::SetWindowItems)
        #  swi_packet = client.last_packets[-2]
        #  ignore_packets_while do |packet|
        #    packet.redundant_after?(swi_packet)
        #  end
        #end
        
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
        window.server_set_items packet.slots
      when Packet::SetSlot
        window.server_set_item packet.slot_id, packet.slot
      when Packet::CloseWindow
        unregister_window window
      when Packet::ConfirmTransaction
        if packet.accepted
          window.pending_actions.delete packet.action_number        
        else
          window.rejected!
          window.pending_actions.clear
        end
      end
    end
    
    def <<(packet)
      receive_packet packet
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
      packet = Packet::ClickWindow.new(window.id, spot_id, :left, new_transaction, true, spot.item)
      
      # TODO: handle stackable items and partial transfer stuff here
      
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
        @client.send_packet packet
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
    
    def close_window
      raise "No window except inventory is open; cannot close a window." if @windows.size < 2
      window = @windows.last
      @client.send_packet Packet::CloseWindow.new(window.id)
      unregister_window(window)
      nil
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


  class WindowTracker
   
    class Window
      extend TracksTypes
    
      attr_reader :spots, :shift_region_top, :shift_region_bottom
      attr_reader :id, :pending_actions
      attr_writer :rejected
      
      def initialize(id, spot_count, inventory)
        @id = id
        @pending_actions = []
        @rejected = false
        @loading = :awaiting_items
      end
      
      # Call this in a subclass in order to provide methods to the WindowTracker.
      # The methods will always return nil unless this window is loaded.
      def self.provide(*method_names)
        method_names.each do |method_name|
          if WindowTracker.instance_methods.include?(method_name)
            raise "#{self} cannot provide #{method_name} method: WindowTracker already has it."
          end
          klass = self
          WindowTracker.send(:define_method, method_name) do
            window = windows.find { |w| klass === w }
            window.send(method_name) if window and window.loaded?
          end
        end
      end
      
      def spot_id(spot)
        @spots.index(spot)
      end
      
      def spot_array(a)
        a.extend SpotArray
      end

      # The Notchian server always sends several SetSlot packets after SetWindowItems,
      # one for each non-empty spot.      
      # To avoid annoying issues caused by those redundant packets, we just wait until
      # we receive all of those SetSpot packets before we consider the window to be
      # fully loaded.
      def loaded?
        !@loading
      end
      
      def synced?
        loaded? && @pending_actions.empty? && !rejected?
      end

      # NOTE: The logic for computing 'rejected?' this is rather brittle; it ASSUMES that after a
      # transaction is rejected the server will send exactly three packets and in this order:
      #   SetWindowItems
      #   SetSlot for the cursor
      #   SetSlot for the item you clicked on.
      # It is quite possible that under more complicated circumstances (e.g. a shift click rejection
      # or a crafting rejection) it might send other packets.  TODO: investigate this!
      def rejected?
        @rejected ? true : false
      end
      
      def rejected!
        @rejected = :awaiting_items
      end
      
      def server_set_items(items)
        spots.items = items
        if @loading == :awaiting_items
          @loading = :awaiting_cursor
        end
        if @rejected == :awaiting_items
          @rejected = :awaiting_cursor
        end
      end
      
      def server_set_cursor
        if @loading == :awaiting_cursor
          @loading = nil
        end
        if @rejected == :awaiting_cursor
          @rejected = nil
        end
      end
      
      def server_set_item(spot_id, item)
        spot = spots[spot_id]
        spot.item = item        
      end
      
      # spots is an array of possible destinations to send the item to,
      # with the highest priority spot first.
      def shift_click_destinations(spot)
        # TODO: in the InventoryWindow subclass, handle the special cases for armor and crafting.
        case
        when shift_region_top.include?(spot)
          shift_region_bottom.reverse.extend(SpotArray)
        when shift_region_bottom.include?(spot)
          shift_region_top
        else
          raise "Cannot shift click spot #{spot_id(spot)} in #{self.class}."
        end      
      end
    end
    
    class Inventory
      attr_reader :normal_spots, :general_spots, :hotbar_spots, :non_hotbar_spots, :spots
      attr_reader :armor_spots, :helmet_spot, :chestplate_spot, :leggings_spot, :boots_spot
    
      def initialize
        @hotbar_spots = 9.times.collect { Spot.new }
        @normal_spots = 27.times.collect { Spot.new }
        @general_spots = @normal_spots + @hotbar_spots

        @helmet_spot = Spot.new
        @chestplate_spot = Spot.new
        @leggings_spot = Spot.new
        @boots_spot = Spot.new
        @armor_spots = [@helmet_spot, @chestplate_spot, @leggings_spot, @boots_spot]
        
        @spots = @armor_spots + @general_spots
        
        [@hotbar_spots, @normal_spots, @general_spots, @armor_spots, @spots, @non_hotbar_spots].each do |array|
          array.extend SpotArray
        end
      end
    end
    
    class InventoryCrafting
      attr_reader :output_spot, :input_spots, :spots
      attr_reader :upper_left, :upper_right, :lower_left, :lower_right
    
      def initialize
        @upper_left = Spot.new
        @upper_right = Spot.new
        @lower_left = Spot.new
        @lower_right = Spot.new
        @input_spots = [@upper_left, @upper_right, @lower_left, @lower_right]
        
        @output_spot = Spot.new
        
        @spots = [@output_spot] + @input_spots
        
        [@spots, @input_spots].each do |array|
          array.extend SpotArray
        end
      end
      
      def input_spot(row, column)
        @input_spots[row*2 + column]
      end
    end
    
    class InventoryWindow < Window
      provide :inventory, :inventory_crafting

      attr_reader :inventory, :inventory_crafting
            
      def initialize
        @inventory = Inventory.new
        super(0, nil, inventory)
        @inventory_crafting = InventoryCrafting.new
        spot_array @spots = inventory_crafting.spots + inventory.spots
        @shift_region_top = inventory.normal_spots
        @shift_region_bottom = inventory.hotbar_spots
      end
      
      alias :crafting :inventory_crafting
    end
    
    class ChestWindow < Window
      type_is 0
      provide :chest_spots
    
      attr_reader :chest_spots, :inventory_spots
    
      def initialize(id, chest_spot_count, inventory)
        super(id, inventory, chest_spot_count)
        spot_array @chest_spots = chest_spot_count.times.collect { Spot.new }        
        @inventory_spots = inventory.general_spots
        
        # This array defines the relationship between spot ID and spots.
        spot_array @spots = @chest_spots + @inventory_spots
        
        @shift_region_top = @chest_spots
        @shift_region_bottom = @inventory_spots
      end
      
    end
  end
  
end