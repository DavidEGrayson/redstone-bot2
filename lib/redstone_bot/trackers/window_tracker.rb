require_relative '../packet_printer'
require_relative '../tracks_types'
require_relative 'spot'
require_relative 'spot_array'

module RedstoneBot
  class WindowTracker
    attr_reader :inventory_window, :windows, :cursor_spot
    
    def initialize(client)
      @windows = []
      @pending_actions = []
      register_window @inventory_window = InventoryWindow.new
      @cursor_spot = Spot.new
      
      @client = client
      @client.listen { |p| receive_packet p }
    end

    def synced?
      usable_window && @pending_actions.empty?
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
        @pending_actions.delete packet.action_number
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
    
    def left_click(spot)
      return if cursor_spot.empty? && spot.empty?
    
      window_id, spot_id = ensure_clickable(spot)
      @client.send_packet Packet::ClickWindow.new(window_id, spot_id, :left, new_transaction, false, spot.item)
      
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
    end
    
    private
    def ensure_clickable(spot)
      window = usable_window
      spot_id = window.spot_id(spot)
      if !spot_id
        raise "Cannot left click on #{spot}; it is not in the currently-usable window."
      end
      [window.id, spot_id]
    end
    
    def new_transaction
      action_number = @client.next_action_number
      @pending_actions.push action_number
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
   
    class Inventory
      attr_reader :regular_spots, :hotbar_spots, :non_hotbar_spots, :spots
      attr_reader :armor_spots, :helmet_spot, :chestplate_spot, :leggings_spot, :boots_spot
    
      def initialize
        @hotbar_spots = 9.times.collect { Spot.new }
        @regular_spots = 27.times.collect { Spot.new } + @hotbar_spots

        @helmet_spot = Spot.new
        @chestplate_spot = Spot.new
        @leggings_spot = Spot.new
        @boots_spot = Spot.new
        @armor_spots = [@helmet_spot, @chestplate_spot, @leggings_spot, @boots_spot]
        
        @spots = @armor_spots + @regular_spots
        
        [@hotbar_spots, @regular_spots, @armor_spots, @spots, @non_hotbar_spots].each do |array|
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
    
    class Window
      extend TracksTypes
    
      attr_reader :id, :spots
      
      def initialize(id, spot_count, inventory)
        @id = id
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
        @awaiting_set_spots && @awaiting_set_spots.empty?
      end      
      
      def server_set_items(items)
        spots.items = items
        @awaiting_set_spots = spots.grep(NonEmpty)
      end
      
      def server_set_item(spot_id, item)
        spot = spots[spot_id]
        spot.item = item
        @awaiting_set_spots.delete(spot)
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
        @inventory_spots = inventory.regular_spots
        
        # This array defines the relationship between spot ID and spots.
        spot_array @spots = @chest_spots + @inventory_spots        
      end
      
    end
  end
  
end