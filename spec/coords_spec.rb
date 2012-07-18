require_relative 'spec_helper'
require 'matrix'
require 'redstone_bot/coords'

describe RedstoneBot::Coords do
  it "holds x, y, and z values" do
    c = described_class[3, 4.0, 5]
    c.x.should == 3
    c.y.should == 4.0
    c.z.should == 5
  end
    
  it "can be compared to others" do
    described_class[3, 4, 5].should == described_class.new(3, 4, 5)
    described_class[3, 6, 7].should_not == described_class.new(3, 4, 5)
  end
  
  it "can be added to others" do
    (described_class[8.0,9.0,10.0] + described_class[0.1, -0.1, -0.9]).should be_within(0.01).of(described_class[8.1,8.9,9.1])
  end
 
  it "can be subtracted from others" do
    (described_class[8,9,10] - described_class[1,2,3]).should == described_class[7,7,7]
    c = described_class[0,0,0]
    c -= described_class[0.0,7.0,0.0]
    c.should be_within(0.01).of(described_class[0,-7,0])
  end
  
  it "can be negated" do
    (-described_class[1,2,3]).should == described_class[-1, -2, -3]
  end
  
  it "has a magnitude/abs/norm" do
    described_class[1,2,3].magnitude.should be_within(0.01).of(Math.sqrt(14))
    described_class[1,2,3].abs.should be_within(0.01).of(Math.sqrt(14))
    described_class[1,2,3].norm.should be_within(0.01).of(Math.sqrt(14))
  end
  
  it "can be multiplied by a scalar" do
    (described_class[1, 3, 9]*2).should == described_class[2,6,18]
    (described_class[1.0, 3, 9]*3.0).should be_within(0.01).of(described_class[3.0,9.0,27.0])
  end
  
  it "can be divided by a scalar" do
    (described_class[3.0, 6.0, 10]/3).should be_within(0.01).of(described_class[1,2,3.3333])
  end
  
  it "can be normalized" do
    (described_class[2.0, 2.0, 2.0]).normalize.should be_within(0.01).of(described_class[0.57735, 0.57735, 0.57735])
  end
  
  it "is component-wise mutable" do
    c = described_class[100, 40, 200]
    c[0] += 1
    c[0].should == 101
    c[1] += 4
    c[1].should == 44
    c.z -= 1
    c.z.should == 199
  end
  
  it "can calculate inner products" do
    (described_class[2.0, 3.0, 4.0].inner_product described_class[0,1,0]).should be_within(0.01).of(3)
  end
  
  it "can project a vector onto a unit vector" do
    described_class[2, 3, 4].project_onto_unit_vector(described_class::Z).should == described_class[0,0,4]
  end
  
  it "can project a vector onto a vector" do
    described_class[2, 3, 4].project_onto_vector(described_class::Z*-3).should == described_class[0,0,4]
  end

end
