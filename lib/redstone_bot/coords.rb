module RedstoneBot
  # Represents x,y,z coordinates in the minecraft world.
  # x, y, and z can be a mixture of integers and floats, for now at least.
  class Coords < Struct.new(:x, :y, :z)
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
    
    def to_s
      "(%7.2f,%7.2f,%7.2f)" % [x, y, z]
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
    
    X = East = Coords[1,0,0]
    Y = Up = Coords[0,1,0]
    Z = South = Coords[0,0,1]
    Down = Coords[0,-1,0]
    North = Coords[0,0,-1]
    West = Coords[-1,0,0]
  end
end