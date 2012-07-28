module RedstoneBot
  module DataReader
    def read_bool
      read_byte != 0
    end
  
    def read_byte
      read(1).unpack('C')[0]   # TODO: just do read(1).ord
    end
    
    def read_signed_byte
      read(1).unpack('c')[0]
    end

    def read_byte_array
      read(read_unsigned_short)
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
      len = read_short
      if len < 0
        nil
      else
        read(len * 2).force_encoding("UCS-2BE")
      end
    end

    def read_string
      str = read_string_raw
      str && str.encode("UTF-8")
    end
    
    ENCHANTABLE = [0x103, 0x105, 0x15A, 0x167,
								 0x10C, 0x10D, 0x10E, 0x10F, 0x122,
								 0x110, 0x111, 0x112, 0x113, 0x123,
								 0x10B, 0x100, 0x101, 0x102, 0x124,
								 0x114, 0x115, 0x116, 0x117, 0x125,
								 0x11B, 0x11C, 0x11D, 0x11E, 0x126,
								 0x12A, 0x12B, 0x12C, 0x12D,
								 0x12E, 0x12F, 0x130, 0x131,
								 0x132, 0x133, 0x134, 0x135,
								 0x136, 0x137, 0x138, 0x139,
								 0x13A, 0x13B, 0x13C, 0x13D]

    def read_slot
      h = {}
      h[:item_id] = read_short
      return nil if h[:item_id] == -1
      h[:count] = read_byte
      h[:damage] = read_unsigned_short
      if ENCHANTABLE.include?(h[:item_id])
        enchant_data_len = read_unsigned_short
        if enchant_data_len > 0
          h[:enchant_data] = read(enchant_data_len)
        end
      end
      h
      
      # TODO: move this InventoryItem.receive_data
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
          when 5 then read_slot
          when 6 then [read_int, read_int, read_int]
          end
      end
      buf
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
  end
end