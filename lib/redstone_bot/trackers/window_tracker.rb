require_relative '../packet_printer'

module RedstoneBot
  class WindowTracker
    class Spot
      attr_accessor :item
      
      def initialize(item=nil)
        @item = item
      end
      
      def empty?
        !@item
      end
    end
    
    class Inventory
      attr_reader :regular_spots, :hotbar_spots, :spots
      attr_reader :armor_spots, :helmet_spot, :chestplate_spot, :leggings_spot, :boots_spot
    
      def initialize
        @hotbar_spots = 9.times.collect { Spot.new }
        @regular_spots = 27.times.collect { Spot.new } + @hotbar_spots

        @helmet_spot = Spot.new
        @chestplate_spot = Spot.new
        @leggings_spot = Spot.new
        @boots_spot = Spot.new
        @armor_spots = [@helmet_spot, @chestplate_spot, @leggings_spot, @boots_spot]
                
        @spots = @regular_spots + @armor_spots
      end
    end

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
end