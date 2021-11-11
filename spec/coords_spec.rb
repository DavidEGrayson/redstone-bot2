require_relative 'spec_helper'
require 'redstone_bot/models/coords'

describe RedstoneBot::Coords do
  it "holds x, y, and z values" do
    c = described_class[3, 4.0, 5]
    expect(c.x).to eq(3)
    expect(c.y).to eq(4.0)
    expect(c.z).to eq(5)
  end
    
  it "can be compared to others" do
    expect(described_class[3, 4, 5]).to eq(described_class.new(3, 4, 5))
    expect(described_class[3, 6, 7]).not_to eq(described_class.new(3, 4, 5))
  end
  
  it "can be added to others" do
    expect(described_class[8.0,9.0,10.0] + described_class[0.1, -0.1, -0.9]).to be_within(0.01).of(described_class[8.1,8.9,9.1])
  end
 
  it "can be subtracted from others" do
    expect(described_class[8,9,10] - described_class[1,2,3]).to eq(described_class[7,7,7])
    c = described_class[0,0,0]
    c -= described_class[0.0,7.0,0.0]
    expect(c).to be_within(0.01).of(described_class[0,-7,0])
  end
  
  it "can be negated" do
    expect(-described_class[1,2,3]).to eq(described_class[-1, -2, -3])
  end
  
  it "has a magnitude/abs/norm" do
    expect(described_class[1,2,3].magnitude).to be_within(0.01).of(Math.sqrt(14))
    expect(described_class[1,2,3].abs).to be_within(0.01).of(Math.sqrt(14))
    expect(described_class[1,2,3].norm).to be_within(0.01).of(Math.sqrt(14))
  end
  
  it "can be multiplied by a scalar" do
    expect(described_class[1, 3, 9]*2).to eq(described_class[2,6,18])
    expect(described_class[1.0, 3, 9]*3.0).to be_within(0.01).of(described_class[3.0,9.0,27.0])
  end
  
  it "can be divided by a scalar" do
    expect(described_class[3.0, 6.0, 10]/3).to be_within(0.01).of(described_class[1,2,3.3333])
  end
  
  it "can be normalized" do
    expect((described_class[2.0, 2.0, 2.0]).normalize).to be_within(0.01).of(described_class[0.57735, 0.57735, 0.57735])
  end
  
  it "is component-wise mutable" do
    c = described_class[100, 40, 200]
    c[0] += 1
    expect(c[0]).to eq(101)
    c[1] += 4
    expect(c[1]).to eq(44)
    c.z -= 1
    expect(c.z).to eq(199)
  end
  
  it "can calculate inner products" do
    expect(described_class[2.0, 3.0, 4.0].inner_product described_class[0,1,0]).to be_within(0.01).of(3)
  end
  
  it "can project a vector onto a unit vector" do
    expect(described_class[2, 3, 4].project_onto_unit_vector(described_class::Z)).to eq(described_class[0,0,4])
  end
  
  it "can project a vector onto a vector" do
    expect(described_class[2, 3, 4].project_onto_vector(described_class::Z*-3)).to eq(described_class[0,0,4])
  end

  it "can change individual components" do
    expect(described_class[2, 3, 4].change_x(89)).to eq(described_class[89,  3,  4])
    expect(described_class[2, 3, 4].change_y(89)).to eq(described_class[ 2, 89,  4])
    expect(described_class[2, 3, 4].change_z(89)).to eq(described_class[ 2,  3, 89])
  end

  it "can iterate over grid points" do
    bounds =  [(-294..-156), (63..64), (682..797)]
    enum = described_class.each_in_bounds bounds
    expect(enum.count).to eq(bounds[0].count * bounds[1].count * bounds[2].count)
  end
  
  it "can iterate over chunk ids" do
    bounds =  [(-294..-156), (63..64), (682..797)]
    enum = described_class.each_chunk_id_in_bounds bounds
    expect(enum.count).to eq(80)
  end
  
  it "can tell if it has only integers" do
    expect(described_class[1,2,3]).to be_int_coords
    expect(described_class[1.1,2,3]).not_to be_int_coords
    expect(described_class[1,2.2,3]).not_to be_int_coords
    expect(described_class[1,2,3.3]).not_to be_int_coords
  end
  
  it "can convert itself to integers using floor" do
    expect(described_class[-0.4, 1.1, 3.9].to_int_coords).to eq(described_class[-1, 1, 3])
  end
  
  it "can enumerate spirals" do
    start = described_class[100, 64, 200]
    s = start.spiral
    expect(s.next).to eq(start)
    
    # Distance 1
    expect(s.next - start).to eq(described_class[ 1, 0,  0])
    expect(s.next - start).to eq(described_class[ 1, 0,  1])
    expect(s.next - start).to eq(described_class[ 0, 0,  1])
    expect(s.next - start).to eq(described_class[-1, 0,  1])
    expect(s.next - start).to eq(described_class[-1, 0,  0])
    expect(s.next - start).to eq(described_class[-1, 0, -1])
    expect(s.next - start).to eq(described_class[ 0, 0, -1])
    expect(s.next - start).to eq(described_class[ 1, 0, -1])
    
    # Distance 2
    expect(s.next - start).to eq(described_class[ 2, 0, -1])
    expect(s.next - start).to eq(described_class[ 2, 0,  0])
    expect(s.next - start).to eq(described_class[ 2, 0,  1])
    expect(s.next - start).to eq(described_class[ 2, 0,  2])
    expect(s.next - start).to eq(described_class[ 1, 0,  2])
    expect(s.next - start).to eq(described_class[ 0, 0,  2])
    expect(s.next - start).to eq(described_class[-1, 0,  2])
    expect(s.next - start).to eq(described_class[-2, 0,  2])
    expect(s.next - start).to eq(described_class[-2, 0,  1])
    expect(s.next - start).to eq(described_class[-2, 0,  0])
    expect(s.next - start).to eq(described_class[-2, 0, -1])
    expect(s.next - start).to eq(described_class[-2, 0, -2])
    expect(s.next - start).to eq(described_class[-1, 0, -2])
    expect(s.next - start).to eq(described_class[ 0, 0, -2])
    expect(s.next - start).to eq(described_class[ 1, 0, -2])
    expect(s.next - start).to eq(described_class[ 2, 0, -2])

    # Distance 3
    expect(s.next - start).to eq(described_class[ 3, 0, -2])
  end
  
end
