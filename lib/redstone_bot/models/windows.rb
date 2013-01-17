require_relative '../has_tids'
require_relative 'spot'
require_relative 'spot_array'

module RedstoneBot
  class Window
    extend HasTids
  
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
      self.provided_methods.concat method_names
    end
    
    def self.provided_methods
      @provided_methods ||= []
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
    
    def report
      s = "== Inventory ==\n"
      s += "Armor: " + @armor_spots.inspect + "\n"
      s += "Normal: " + @normal_spots.inspect + "\n"
      s += "Hotbar: " + @hotbar_spots.inspect + "\n"
      s += "===="
      s
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
    tid_is nil
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
    tid_is 0
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