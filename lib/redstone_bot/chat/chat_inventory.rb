module RedstoneBot
  module ChatInventory
    def chat_inventory(p)
      case p.chat
      when "drop"
        wielded_item_drop
      when /\Adump all\Z/
        dump_all
      when /\Adump [ ]*(.*)\Z/
        name = $1
        type = ItemType.from(name)
        if type
          dump type
        else
          chat "da understood #{name}"
        end
      when /\Awield (.+)\Z/  
        name = $1
        type = ItemType.from(name)
        if type
          wield type
        else
          chat "da understood #{name}"
        end
      when "i"
        puts inventory.report
      end
    end
  end
end