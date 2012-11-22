module RedstoneBot
  class Spot
    attr_accessor :item
    
    def initialize(item=nil)
      @item = item
    end
    
    def empty?
      !@item
    end
  end
end
