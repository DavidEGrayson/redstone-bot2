require_relative 'item_types'
require_relative '../models/item'

module RedstoneBot
  module ItemReader
    def read_item
      item_id = read_short
      return nil if item_id == -1
      item_type = ItemType.from_id(item_id)
      raise "Unknown item type #{item_id}." if !item_type      
      count = read_byte
      damage = read_unsigned_short
      enchant_data_len = read_short
      if enchant_data_len > 0
        gzipped_data = read(enchant_data_len)
        nbt_stream = gunzip_stream(gzipped_data)
        enchant_data = nbt_stream.read_nbt
      end
      
      Item.new(item_type, count, damage, enchant_data)
    end
    
    def gunzip_stream(str)
      Zlib::GzipReader.new(StringIO.new str).extend DataReader
    end
  end
  
  module ItemEncoder
    # Can't name this just 'item' because this is mixed into packets and it
    # would cause confusion with a lot of packets that have an 'item' member.
    def encode_item(item)
      return "\xFF\xFF" if !item
    
      binary_data = unsigned_short(item.item_type) + byte(item.count) + unsigned_short(item.damage)
      
      binary_data += if item.enchant_data
        nbt = NbtEncoderForEnchantData.nbt(item.enchant_data)
        compressed_data = gzip(nbt)
        unsigned_short(compressed_data.size) + compressed_data
      else
        "\xFF\xFF"  # length is short(-1)
      end
      
      binary_data
    end
    
    def gzip(str)
      sio = StringIO.new
      writer = Zlib::GzipWriter.new(sio)
      writer.write str
      writer.close
      compressed_data = sio.string.force_encoding('BINARY')
      
      # Set some metadata so that our comrpessed data will be the same as the data sent
      # by the server.  The Notchian server doesn't seem to mind if mtime and os_code
      # are different, but it makes it easier to test the gzipping.
      compressed_data[4..7] = "\x00\x00\x00\x00"  # set the mtime to 0
      compressed_data[9] = "\x00"  # set os_code to 0
      
      compressed_data
    end
    
  end
end