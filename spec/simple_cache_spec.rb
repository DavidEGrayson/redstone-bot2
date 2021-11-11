require_relative 'spec_helper'
require 'redstone_bot/simple_cache'

class TestChangeSource
  def initialize
    @change_listeners = []
  end

  def on_change(&proc)
    @change_listeners << proc
  end

  def <<(*args)
    @change_listeners.each do |l|
      l.call(*args)
    end
  end
end

describe RedstoneBot::SimpleCache do
  before do
    @calc = double("data")
    allow(@calc).to receive(:calc) { |n| n.succ if n }
    @sender = TestChangeSource.new
    @cache = described_class.new(@sender) do |id|
      @calc.calc(id)
    end
  end
  
  it "caches calculation results" do
    expect(@calc).to receive(:calc).once.with(8)
    3.times { @cache[8] }
  end
  
  it "caches nil calculation results" do
    expect(@calc).to receive(:calc).once.with(false)
    3.times { @cache[false] }
  end
  
  it "updates the cache when there is a change" do
    expect(@calc).to receive(:calc).twice.with(3)
    3.times { @cache[3] }
    @sender << 3
    3.times { @cache[3] }    
  end
  
  it "clears the cache" do
    expect(@calc).to receive(:calc).twice.with(3)
    3.times { @cache[3] }
    @cache.clear
    3.times { @cache[3] }    
  end
  
end