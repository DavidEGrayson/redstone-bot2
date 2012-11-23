require_relative '../packet_printer'
require_relative '../tracks_types'
require_relative 'spot'
require_relative 'spot_array'

module RedstoneBot
  class WindowTracker
    attr_reader :inventory_window, :open_windows
    
    def initialize(client)
      @inventory_window = InventoryWindow.new
      @open_windows = { 0 => @inventory_window }
      
      @client = client
      @client.listen { |p| receive_packet p }
    end
    
    def receive_packet(packet)
      return unless packet.respond_to?(:window_id)
      
      if packet.is_a?(Packet::OpenWindow)
        window = Window.create(packet.type, packet.spot_count, inventory_window.inventory)
        @open_windows[packet.window_id] = window
        return
      end
      
      window = @open_windows[packet.window_id]
      if !window
        $stderr.puts "#{@client.time_string}: warning: received packet for non-open window: #{packet}"
        return
      end
      
      case packet
      when Packet::SetWindowItems
        window.server_set_items packet.slots
      when Packet::SetSlot
        window.server_set_item packet.slot_id, packet.slot
      end
    end
    
    def inventory
      inventory_window.inventory if inventory_window.loaded?
    end
    
    def <<(packet)
      receive_packet packet
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
    
      attr_reader :spots
       
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
      attr_reader :inventory, :crafting
      
      def initialize
        super
        @inventory = Inventory.new
        @crafting = InventoryCrafting.new
        spot_array @spots = crafting.spots + inventory.spots
      end
    end
    
    class ChestWindow < Window
      type_is 0
    
      attr_reader :chest_spots, :inventory_spots
    
      def initialize(chest_spot_count, inventory)
        super()
        spot_array @chest_spots = chest_spot_count.times.collect { Spot.new }        
        @inventory_spots = inventory.regular_spots
        
        # This array defines the relationship between spot ID and spots.
        spot_array @spots = @chest_spots + @inventory_spots        
      end
    end
  end
  
end