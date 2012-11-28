module RedstoneBot
  # Represents an abstract place that can hold an item or be empty.
  # Spots are part of the inventory, chests, inventory windows, chest
  # windows, etc.
  class Spot
    attr_accessor :item
    
    def initialize(item=nil)
      @item = item
    end
    
    def empty?
      !@item
    end
    
    def item_type
      @item.item_type if @item
    end
    
    def to_s
      "(" + @item.to_s + ")"
    end
  end
end
