module RedstoneBot
  # Represents x,y,z coordinates in the minecraft world.
  # x, y, and z can be a mixture of integers and floats, for now at least.
  class Coords < Struct.new(:x, :y, :z)
    X = East = Coords[1,0,0]
    Y = Up = Coords[0,1,0]
    Z = South = Coords[0,0,1]
    Down = Coords[0,-1,0]
    North = Coords[0,0,-1]
    West = Coords[-1,0,0]
  
    def inspect
      self.class.name + to_s
    end
    
    def +(coords)
      Coords[x + coords.x, y + coords.y, z + coords.z]    
    end
    
    def -(coords)
      Coords[x - coords.x, y - coords.y, z - coords.z]
    end
    
    def -@
      Coords[-x, -y, -z]
    end
    
    def *(scalar)
      Coords[x*scalar, y*scalar, z*scalar]
    end

    def /(scalar)
      Coords[x.to_f/scalar, y.to_f/scalar, z.to_f/scalar]
    end
    
    def abs
      Math.sqrt(x*x + y*y + z*z)
    end
    
    alias :magnitude :abs
    alias :norm :abs
    
    def normalize
      self/norm
    end
    
    def inner_product(coords)
      x*coords.x + y*coords.y + z*coords.z
    end
    
    def project_onto_unit_vector(coords)
      coords * inner_product(coords)
    end
    
    def project_onto_vector(coords)
      project_onto_unit_vector coords.normalize
    end
    
    def change_x(x)
      Coords[x, y, z]
    end

    def change_y(y)
      Coords[x, y, z]
    end

    def change_z(z)
      Coords[x, y, z]
    end
    
    def to_s
      if int_coords?
        "(%7d,%7d,%7d)" % [x, y, z]
      else
        "(%7.2f,%7.2f,%7.2f)" % [x, y, z]
      end
    end
    
    def int_coords?
      Integer === x && Integer === y && Integer === z
    end
    
    def to_int_coords
      Coords[x.floor, y.floor, z.floor]
    end
    
    def to_int_array
      int_coords = to_int_coords
      [int_coords.x,int_coords.y,int_coords.z]
    end
    
    def to_coords
      self
    end
    
    def spiral
      return enum_for(:spiral) unless block_given?
      # if z points up, x points to the left
    
      start = to_int_coords
      x, y, z = start.to_a
      yield start
      d = 0
      while true
        d += 1
        r = (1-d)..d
        r.each { |i| yield Coords[x+d, y, z+i] }
        r.each { |i| yield Coords[x-i, y, z+d] }
        r.each { |i| yield Coords[x-d, y, z-i] }
        r.each { |i| yield Coords[x+i, y, z-d] }
      end
    end
    
    # TODO: see if block-searching algorithms get faster if these
    # enumerators just give int arrays instead of Coord objects
    def self.each_in_bounds(bounds)
      return enum_for(:each_in_bounds, bounds) unless block_given?
      xrange, yrange, zrange = bounds
      xrange.each do |x|
        yrange.each do |y|
          zrange.each do |z|
            yield Coords[x, y, z]
          end
        end
      end
    end
    
    def self.each_chunk_id_in_bounds(bounds)
      return enum_for(:each_chunk_id_in_bounds, bounds) unless block_given?
      xrange, _, zrange = bounds
      cxrange = (xrange.min.to_i/16)..(xrange.max.to_i/16)
      czrange = (zrange.min.to_i/16)..(zrange.max.to_i/16)
      cxrange.each do |cx|
        czrange.each do |cz|
          yield [cx*16, cz*16]
        end        
      end
    end
    
  end
end