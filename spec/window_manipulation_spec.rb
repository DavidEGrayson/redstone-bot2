require_relative 'spec_helper'

describe RedstoneBot::WindowManipulation do
  include WindowSpecHelper

  let(:chest_coords) { RedstoneBot::Coords[8, 70, 13] }
  let(:client) { @client }
  let(:bot) { @bot }

  before do
    @bot = TestBot.new_at_position RedstoneBot::Coords[8, 70, 8]
    @client = @bot.client

    chunk = @bot.chunk_tracker.get_or_create_chunk [0,0]
    chunk.set_block_type chest_coords, RedstoneBot::ItemType::Chest

    server_load_window 0, [nil]*45
    @bot.inventory.normal_spots[0].item = RedstoneBot::ItemType::CoalItem * 10
    @bot.inventory.normal_spots[20].item = RedstoneBot::ItemType::CoalItem * 64
    @bot.inventory.hotbar_spots[0].item = RedstoneBot::ItemType::SnowBall * 10

    # Put the bot on a platform near a chest.
  end

  describe :dump do
    context "when passed an item type" do
      let(:dump_spec) { RedstoneBot::ItemType::CoalItem }

      it "dumps all spots matching that item type" do
        expect(@client).to receive(:send_packet).exactly(4).times  # 4 clicks
        expect(@bot.dump(dump_spec)).to eq(nil)
        expect(@bot.inventory.general_spots.quantity(RedstoneBot::ItemType::CoalItem)).to eq(0)
      end
    end
  end

  describe :dump do
    it "dumps all non-empty spots" do
      expect(@client).to receive(:send_packet).exactly(6).times  # 6 clicks
      expect(@bot.dump_all).to eq(nil)
    end
  end

  describe :chest_open_start do
    context "when passed the coordinates of a chest" do
      before do
        @bot.chest_open_start chest_coords
      end

      it "sends the animation packet" do
        # almost not worth testing
        packet = @client.sent_packets[-2]
        expect(packet.eid).to eq(@client.eid)
        expect(packet.animation).to eq(1)
      end

      it "sends the right packet to open the chest" do
        packet = @client.sent_packets[-1]
        expect(packet).to be_a RedstoneBot::Packet::PlayerBlockPlacement
        expect(packet.coords).to eq(RedstoneBot::Coords[8, 70, 13])
        expect(packet.direction).to eq(1)  # actually I'm not sure what this is supposed to be, but 1 works
      end
    end

    it "when passed the coordinates of a non-chest block raises an exception" do
      expect { @bot.chest_open_start RedstoneBot::Coords[8, 70, 19] }.to raise_error
    end

  end

  context "after the bot calls chest_open and the brain runs once" do
    before do
      @bot.chest_open(chest_coords) do |chest_spots|
        @block_started = true  # this is an rspec instance variable
      end
      @bot.brain.run
    end

    it "has not yet yielded" do
      expect(@block_started).to be_nil
    end

    context "and the server loads the window" do
      before do
        server_open_chest 55
        server_load_window 55, [nil]*63
      end

      it "yields to the block" do
        expect(@bot.window_tracker.chest_spots).to be
        @bot.brain.run
        expect(@block_started).to eq(true)
      end

      context "and the block returns" do
        it "closes the window" do
          @bot.brain.run
          expect(@bot.brain).not_to be_alive
          expect(@bot.window_tracker.chest_spots).to be_nil
        end
      end
    end
  end

end