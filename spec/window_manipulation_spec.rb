require_relative 'spec_helper'

describe RedstoneBot::WindowManipulation do
  include WindowSpecHelper

  before do
    @bot = TestBot.new_at_position RedstoneBot::Coords[8, 70, 8]
    @client = @bot.client
    
    chunk = @bot.chunk_tracker.get_or_create_chunk [0,0]
    chunk.set_block_type [8, 70, 13], RedstoneBot::ItemType::Chest
    
    # Put the bot on a platform near a chest.
  end
  
  describe :chest_open_start do
    context "when passed the coordinates of a chest" do
      before do
        @bot.chest_open_start RedstoneBot::Coords[8, 70, 13]
      end
    
      it "sends the animation packet" do
        # almost not worth testing
        packet = @client.sent_packets[-2]
        packet.eid.should == @client.eid
        packet.animation.should == 1
      end
    
      it "sends the right packet to open the chest" do
        packet = @client.sent_packets[-1]
        packet.should be_a RedstoneBot::Packet::PlayerBlockPlacement
        packet.coords.should == RedstoneBot::Coords[8, 70, 13]
        packet.direction.should == 1  # actually I'm not sure what this is supposed to be, but 1 works
      end
    end
    
    it "when passed the coordinates of a non-chest block raises an exception" do
      lambda { @bot.chest_open_start RedstoneBot::Coords[8, 70, 19] }.should raise_error
    end
    
  end

  context "after the bot calls chest_open" do
    context "and the server loads the window" do
      before do
        server_open_window 55
        server_load_window 55, [nil]*63
      end      
    end
  end
  
end