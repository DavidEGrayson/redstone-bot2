require_relative '../packet_printer'
require_relative 'spot'
require_relative 'spot_array'

module RedstoneBot
  class WindowTracker
    attr_reader :inventory, :open_window
    
    def initialize(client)
      @client = client
      @client.listen { |p| receive_packet p }
    end
    
    def receive_packet(packet)
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
      attr_reader :spots
      
      def spot_id(spot)
        @spots.index(spot)
      end
      
      def spot_array(a)
        a.extend SpotArray
      end
    end
    
    class InventoryWindow < Window
      attr_reader :inventory, :crafting
      
      def initialize
        @inventory = Inventory.new
        @crafting = InventoryCrafting.new
        spot_array @spots = crafting.spots + inventory.spots
      end
    end
    
    class ChestWindow < Window
      attr_reader :chest_spots, :inventory_spots
    
      def initialize(chest_spot_count, inventory)
        spot_array @chest_spots = chest_spot_count.times.collect { Spot.new }        
        @inventory_spots = inventory.regular_spots
        
        # This array defines the relationship between spot ID and spots.
        spot_array @spots = @chest_spots + @inventory_spots        
      end
    end
  end
  
end