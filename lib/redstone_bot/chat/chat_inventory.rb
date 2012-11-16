module RedstoneBot
  module ChatInventory
    def chat_inventory(p)
      case p.chat
      when /drop[ ]*(.*)/
        name = $1
        inventory.drop 
      when /\Adump all\Z/
        inventory.dump_all
      when /\Adump all[ ]*(.*)\Z/
        name = $1
        type = ItemType.from(name)
        if type
          inventory.dump_all(type)
        else
          chat "da understood #{name}"
        end  
      when /\Adump[ ]*(.*)\Z/
        name = $1
        type = ItemType.from(name)
        if type
          inventory.dump(type)
        else
          chat "da understood #{name}"
        end
      when /\Ahold (.+)\Z/  
        name = $1
        type = ItemType.from(name)
        if type
          inventory.hold(type)
        else
          chat "da understood #{name}"
        end
      when "i"
        puts @inventory
      end
    end
  end
end