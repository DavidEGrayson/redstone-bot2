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
  p = ChatMessage.allocate
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
  
  def username
    "testbot"
  end
end

describe RedstoneBot::ChatFilter do
  before do
    @chatter = TestChatter.new
    @filter = RedstoneBot::ChatFilter.new(@chatter)
    @receiver = double("receiver")
    @filter.listen { |p| @receiver.packet p }
  end

  it "should pass all Packet::ChatMessages by default" do
    @receiver.should_receive :packet
    @chatter << player_chat("Elavid", "wazzup")
  end
  
  it "should reject objects other than Packet::ChatMessage" do
    @receiver.should_not_receive :packet
    @chatter << RedstoneBot::Packet::KeepAlive.new
  end
  
  context "when rejecting messages from self" do
    before do
      @filter.reject_from_self
    end
  
    it "rejects messages from self" do
      @receiver.should_not_receive :packet
      @chatter << player_chat(@chatter.username, "hey")
    end

    it "passes messages from others" do
      @receiver.should_receive :packet
      @chatter << player_chat("Elavid", "hey")
    end
  end
  
end