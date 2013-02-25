# coding: ASCII-8BIT

require 'zlib'
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
        nbt_hash = nbt_stream.read_nbt
        
        if nbt_hash["tag"] && nbt_hash["tag"]["ench"]
          # This is the normal case.
          ench_list = nbt_hash["tag"]["ench"]
        elsif nbt_hash[""] && nbt_hash[""]["ench"]
          # The Notchian server sends {""=>{"ench"=>[{"id"=>48, "lvl"=>1}]}} sometimes.
          # I think it's a skeleton with an enchanted bow.
          # If we try to re-encode this and send it to the server we'll probably get in trouble
          # because we are not remembering that the name of the root compound is "".
          ench_list = nbt_hash[""]["ench"]
        else
          $stderr.puts "warning: Got strange enchantment data #{nbt_hash.inspect} with #{item_type},#{damage}"
        end
        
        if ench_list
          enchantments = ench_list.each_with_object({}) do |c, h|
            enchantment = Enchantments[c["id"]]
            level = c["lvl"]
            h[enchantment] = level
          end
        end
      end
      
      Item.new(item_type, count, damage, enchantments)
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
      
      binary_data += if item.enchantments
        ench = item.enchantments.collect do |enchantment, level|
          { "id" => Enchantments.key(enchantment), "lvl" => level }
        end
        nbt_hash = { "tag" => { "ench" => ench } }
      
        nbt_str = NbtEncoderForEnchantData.nbt(nbt_hash)
        compressed_data = gzip(nbt_str)
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