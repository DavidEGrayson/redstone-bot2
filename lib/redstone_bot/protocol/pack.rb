module RedstoneBot
  module DataReader
    def read_bool
      read_byte != 0
    end
  
    def read_byte
      read(1).ord
    end
    
    def read_signed_byte
      read(1).unpack('c')[0]
    end

    def read_byte_array
      len = read_short      
      if len < 0
        nil
      else
        read(len)
      end
    end
    
    def read_short
      read(2).unpack('s>')[0]
    end

    def read_unsigned_short
      read(2).unpack('S>')[0]
    end
    
    def read_int
      read(4).unpack('l>')[0]
    end

    def read_unsigned_int
      read(4).unpack('L>')[0]
    end
    
    def read_long
      read(8).unpack('q>')[0]
    end

    def read_float
      read(4).unpack('g')[0]
    end

    def read_double
      read(8).unpack('G')[0]
    end

    def read_string_raw
      read(read_short * 2).force_encoding("UCS-2BE")
    end

    def read_string
      read_string_raw.encode("UTF-8")
    end
    
    def read_utf8_string
      read(read_short).force_encoding("UTF-8")
    end

    def read_metadata
      buf = {}
      while (b = read(1).ord) != 0x7F
        buf[b & 0x1F] = case b >> 5
          when 0 then read_byte
          when 1 then read_short
          when 2 then read_int
          when 3 then read_float
          when 4 then read_string
          when 5 then read_item
          when 6 then [read_int, read_int, read_int]
          end
      end
      buf
    end
  
    def read_item
      Item.receive_data(self)
    end
    
    def read_nbt
      tags = []
      while b = read(1)
      
        case b.ord
        when 0 then return tags
        when 1 then tags << [:byte, read_utf8_string, read_signed_byte]
        when 2 then tags << [:short, read_utf8_string, read_short]
        when 3 then tags << [:int, read_utf8_string, read_int]
        when 4 then tags << [:long, read_utf8_string, read_long]
        when 5 then tags << [:float, read_utf8_string, read_float]    # TODO: is this correct endianness?
        when 6 then tags << [:double, read_utf8_string, read_double]  # TODO: is this correct endianness?
        when 7 then tags << [:bytes, read_utf8_string, read_unsigned_int.times.collect { read_signed_byte }]
        when 8 then tags << [:string, read_utf8_string, read_utf8_string]
        when 9
          raise "NBT list not implemented"
          tags << [:list, read_utf8_string, read_byte, read_unsigned_int.times.collect { }]
        when 10 then tags << [:compound, read_utf8_string, read_nbt]
        when 11 then tags << [:ints, read_utf8_string, read_unsigned_int.times.collect { read_int }]          
        end
      end
      tags
    end
  end
  
  module DataEncoder
    def signed_byte(b)
      [b].pack('c')
    end

    def byte(b)
      [b].pack('C')
    end
    
    def byte_array(b)
      unsigned_short(b.size) + b
    end

    def short(s)
       [s].pack('s>')
    end
    
    def unsigned_short(s)
      [s].pack('S>')
    end

    def bool(b)
      # we frequently switch back and forth between bytes and bools, and this will help us catch bugs
      raise "Expected true or false but got #{b.inspect}" if b != true && b != false
      byte(b ? 1 : 0)
    end

    def int(i)
      [i].pack('l>')
    end
    
    def unsigned_int(i)
      [i].pack('L>')
    end

    def long(l)
      [l].pack('q>')
    end

    def float(f)
      [f].pack('g')
    end

    def double(d)
      [d].pack('G')
    end

    def string(s)
      short(s.length) + s.encode('UCS-2BE').force_encoding('ASCII-8BIT')
    end
    
    # Can't name this just 'item' because this is mixed into packets and it
    # would cause confusion with a lot of packets that have an 'item' member.
    def encode_item(item)
      Item.encode_data item
    end
  end
end