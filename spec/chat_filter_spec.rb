require_relative 'spec_helper'
require 'redstone_bot/chat_filter'

ChatMessage = RedstoneBot::Packet::ChatMessage

class ChatMessage
  def player_chat(username, chat)
    @data = "<#{username}> #{chat}"
    @username = username
    @chat = chat
  end
end

def player_chat(username, chat)
  p = RedstoneBot::Packet::ChatMessage.allocate
  p.player_chat(username, chat)
  p
end

class TestChatter
  def initialize
    @listeners = []
  end
  
  def listen(&proc)
    @listeners << proc
  end
  
  def <<(packet)
    @listeners.each do |l|
      l.call packet
    end
  end
end

describe RedstoneBot::ChatFilter do
  before do
    @chatter = TestChatter.new
    @filter = RedstoneBot::ChatFilter.new(@chatter)
    @receiver = double("receiver")
    @filter.listen { |p| @receiver.packet p }
  end

  it "should let through all Packet::ChatMessages by default" do
    @receiver.should_receive :packet
    @chatter << player_chat("Elavid", "wazzup")
  end
  
  it "should not let through objects other than Packet::ChatMessage" do
    @chatter << "mehehe"
    @receiver.should_not_receive :packet
  end

end