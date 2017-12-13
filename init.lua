
local ENGLISH_STYLE = true

math.randomseed(os.time())

local STACK_FORM = "size[2,6]"..
    "button_exit[0,0;2,1;draw_turned;draw turned]"..
    "button_exit[0,1;2,1;shuffle;shuffle]"..
    "button_exit[0,2;2,1;flip;flip]"..
    "button_exit[0,3;2,1;remove;delete stack]"..
    "button_exit[0,4;2,1;quit;quit]"
local CARD_FORM = "size[3,5]"..
    "button_exit[0,0;3,1;flip;flip]"..
    "button_exit[0,1;3,1;shuffle;shuffle]"..
    "button_exit[0,2;3,1;delete;not show again]"..
    "button_exit[0,3;3,1;quit;quit]"
local box_form = "size[10,4]"
local CARDS_PER_BOX = 500


minetest.register_node("cards:turned_card", {
  description = "a turned card",
  inventory_image = "cards_back_2.png",
  wield_image = "cards_back_2.png",
  drawtype = "nodebox",
  node_box = {
    type = "fixed",
    fixed = {{-0.5, -0.5, -0.5, 0.5, -0.4375 , 0.5}}
  },
  tiles = {"cards_back_2.png", "cards_back_2.png",
      "cards_side.png", "cards_side.png",
      "cards_side.png", "cards_side.png"
  },
  paramtype = "light",
  paramtype2 = "facedir",
  after_place_node = function(pos, placer, itemstack, pointed_thing)
    local card = itemstack:get_metadata()
    local deckname = string.sub(card, 12, string.find(card, "_", 12) - 1)
    minetest.swap_node(pos, {name = "cards:stack_"..deckname})
    local meta = minetest.get_meta(pos)
    meta:set_int("count", 0)
    meta:set_string(0, card)
    meta:set_string("infotext", 1)
    meta:set_string("formspec", STACK_FORM)
  end,
  groups = {oddly_breakable_by_hand = 3, card = 3, not_in_creative_inventory = 1},
})

local num_decks = 0

local function register_deck(deckname, data)
  local name = "cards:deck_"..deckname
  local cardname = data.cardname
  local stackname = "cards:stack_"..cardname
  local size = data.number_of_suits * data.number_of_values
  box_form = box_form..
      "item_image_button["..num_decks..",2;1,1;"..name..";"..name.."#"..size..";]"..
      "label["..num_decks..",1;"..deckname.."]"..
      "label["..num_decks..",3;"..size.."]"
  num_decks = num_decks + 1
  minetest.register_craftitem(name, {
    description = "set of playing cards ("..deckname..")",
    inventory_image = data.inventory_image,
    wield_image = data.inventory_image,
    on_place = function(itemstack, placer, pointed_thing)
      if pointed_thing.type ~= "node" then
        return
      end
      local pos = pointed_thing.under
      local node = minetest.get_node(pos)
      if not minetest.registered_nodes[node.name].buildable_to then
        pos = pointed_thing.above
        node = minetest.get_node(pos)
        if not minetest.registered_nodes[node.name].buildable_to then
          return
        end
      end
      if minetest.is_protected(pos, placer:get_player_name())then
        return
      end
      node.name = stackname
      minetest.set_node(pos, node)
      itemstack:take_item()
      -- set cards
      local meta = minetest.get_meta(pos)
      local count = size
      local set = {}
      for s = 1, data.number_of_suits do
        for v = 1, data.number_of_values do
          local r = math.random(1, count)
          local i = -1
          while r > 0 do
            i = i + 1 
            if not set[i] then
              r = r - 1
            end
          end 
          set[i] = true
          meta:set_string(i, "cards:card_"..cardname.."_"..data.suits[s].."_"..data.values[v])
          count = count - 1
        end
      end
      meta:set_int("count", size - 1)
      meta:set_string("infotext", size)
      meta:set_string("formspec", STACK_FORM)
      return itemstack
    end,
  })
  minetest.register_craft({
    output = "cards:card_box "..size,
    recipe = {{name}}, 
  })
  if not minetest.registered_nodes[stackname] then
    minetest.register_node(stackname, {
      description = "set of playing cards ("..cardname..")",
      inventory_image = data.back_texture,
      wield_image = data.back_texture,
      drawtype = "nodebox",
      node_box = {
        type = "fixed",
        fixed = {{-0.5, -0.5, -0.5, 0.5, -0.25 , 0.5}}
      },
      tiles = {data.back_texture, data.back_texture,
          "cards_side.png", "cards_side.png",
          "cards_side.png", "cards_side.png"
      },
      paramtype = "light",
      paramtype2 = "facedir",
      on_dig = function(pos, node, player)
        if minetest.is_protected(pos, player:get_player_name()) then
          return
        end
        local meta  = minetest.get_meta(pos)
        local count = meta:get_int("count")
        local top = meta:get_string(count)
        player:get_inventory():add_item("main", top)
        if count == 0 then
          node.name = "air"
          minetest.set_node(pos, node)
          return
        else
          meta:set_int("count", count - 1)
          meta:set_string("infotext", count)
        end
      end,
      on_receive_fields = function(pos, formname, fields, player)
        if fields.flip then
          local meta = minetest.get_meta(pos)
          local count = meta:get_int("count")
          for i = 0, count / 2 do
            local a = meta:get_string(i)
            local b = meta:get_string(count - i)
            meta:set_string(i, b)
            meta:set_string(count - i, a)
          end
          meta:set_string("formspec", CARD_FORM)
          minetest.swap_node(pos, {name = meta:get_string(count)})
        elseif fields.draw_turned then
          local meta  = minetest.get_meta(pos)
          local count = meta:get_int("count")
          local top = meta:get_string(count)
          player:get_inventory():add_item("main", {name="cards:turned_card", count=1, wear=0, metadata= top})
          if count == 0 then
            minetest.set_node(pos, {name = "air"})
            return
          else
            meta:set_int("count", count - 1)
            meta:set_string("infotext", count)
          end  
        elseif fields.remove then  
          minetest.set_node(pos, {name = "air"})
        elseif fields.shuffle then
          local meta = minetest.get_meta(pos)
          local count = meta:get_int("count")
          for i = 0, count do
            local j = math.random(i, count)
            local a = meta:get_string(i)
            local b = meta:get_string(j)
            meta:set_string(i, b)
            meta:set_string(j, a)
          end
        end
      end,
      groups = {oddly_breakable_by_hand = 3, card = 2},
    })
  end

  for s = 1, data.number_of_suits  do
  for v = 1, data.number_of_values do
  local name = "cards:card_"..cardname.."_"..data.suits[s].."_"..data.values[v]
  if not minetest.registered_nodes[name] then
    local texture = data.value_textures[v].."^"..data.suit_textures[s].."^[colorize:"..data.colors[s].."^[noalpha"
    minetest.register_node(name, {
      description = data.suits[s].." "..data.values[v],
      inventory_image = texture,
      wield_image = data.back_texture,
      drawtype = "nodebox",
      node_box = {
        type = "fixed",
        fixed = {{-0.5, -0.5, -0.5, 0.5, -0.4375 , 0.5}}
      },
      tiles = {texture,     data.back_texture,
          "cards_side.png", "cards_side.png",
          "cards_side.png", "cards_side.png"
      },
      paramtype = "light",
      paramtype2 = "facedir",
      on_place = function(itemstack, placer, pointed_thing)
        if pointed_thing.type ~= "node" then
          return
        end 
        local pos  = pointed_thing.under
        local node = minetest.get_node(pos)
        local stack_type = minetest.get_node_group(node.name, "card")
        if stack_type == 0 then
          return minetest.item_place(itemstack, placer, pointed_thing) -- default
        end
        if minetest.is_protected(pos, placer:get_player_name()) then
          return
        end
        -- add card to stack
        local meta  = minetest.get_meta(pos)
        local count = meta:get_int("count")
        if count == 0 then
          meta:set_string(count, node.name)
          meta:set_string("formspec", CARD_FORM)
        end
        count = count + 1
        meta:set_string(count, name)
        meta:set_int("count", count)
        meta:set_string("infotext", count + 1)
        if stack_type == 1 then 
          node.name = name
          minetest.swap_node(pos, node)
        end
        itemstack:take_item()
        return itemstack
      end,
      on_dig = function(pos, node, player)
        if minetest.is_protected(pos, player:get_player_name()) then
          return
        end
        local meta  = minetest.get_meta(pos)
        local count = meta:get_int("count")
        if count == 0 then
          minetest.node_dig(pos, node, player)
          return
        end
        local top = meta:get_string(count)
        player:get_inventory():add_item("main", top)
        count = count - 1
        node.name = meta:get_string(count)
        meta:set_int("count", count)
        meta:set_string("infotext", count + 1)
        minetest.swap_node(pos, node)
      end,
      on_receive_fields = function(pos, formname, fields, player)
        if fields.collect then 
          local meta = minetest.get_meta(pos)
          if meta:get_int("count") == size then
            player:get_inventory():add_item("main", 
                "cards:stack_"..deckname)
            minetest.set_node(pos, {name = "air"})
          else
            minetest.chat_send_player(player:get_player_name(), 
                "[cards] stack not complete!")
          end
        elseif fields.flip then
          local meta = minetest.get_meta(pos)
          local count = meta:get_int("count")
          for i = 0, count / 2 do
            local a = meta:get_string(i)
            local b = meta:get_string(count - i)
            meta:set_string(i, b)
            meta:set_string(count - i, a)
          end
          meta:set_string("formspec", STACK_FORM)
          minetest.swap_node(pos, {name = "cards:stack_"..deckname})
        elseif fields.shuffle then
          local meta = minetest.get_meta(pos)
          local count = meta:get_int("count")
          for i = 0, count do
            local j = math.random(i, count)
            local a = meta:get_string(i)
            local b = meta:get_string(j)
            meta:set_string(i, b)
            meta:set_string(j, a)
          end
          minetest.swap_node(pos, {name = meta:get_string(count)})
        elseif fields.delete then  
          local meta = minetest.get_meta(pos)
          meta:set_string("formspec", nil)
        end
      end,
      groups = {oddly_breakable_by_hand = 3, card = 1},
    })
  end
  end
  end
end

register_deck("32", {
  cardname = "green",
  number_of_suits = 4,
  number_of_values = 8,
  colors = {"#F00", "#F00", "#000", "#000"},
  suits = {"tiles", "hearts", "pikes", "clovers"},
  suit_textures = {
    "cards_tile.png",
    "cards_heart.png",
    "cards_pike.png",
    "cards_clover.png"
  },
  values = {"7", "8", "9", "10", "B", "D", "K", "A"},
  value_textures = {
    "cards_7.png",
    "cards_8.png",
    "cards_9.png",
    "cards_10.png",
    "cards_B.png",
    "cards_D.png",
    "cards_K.png",
    "cards_A.png"
  },
  back_texture = "cards_back_3.png",
  inventory_image = "cards_deck_32.png",
})

register_deck("52", {
  cardname = "blue",
  number_of_suits = 4,
  number_of_values = 13,
  colors = {"#FA0", "#F00", "#0B0", "#000"},
  suits = {"tiles", "hearts", "pikes", "clovers"},
  suit_textures = {
    "cards_tile.png",
    "cards_heart.png",
    "cards_pike.png",
    "cards_clover.png"
  },
  values = { "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"},
  value_textures = {
    "cards_2.png",
    "cards_3.png",
    "cards_4.png",
    "cards_5.png",
    "cards_6.png",
    "cards_7.png",
    "cards_8.png",
    "cards_9.png",
    "cards_10.png",
    "cards_J.png",
    "cards_Q.png",
    "cards_K.png",
    "cards_A.png"
  },
  back_texture = "cards_back.png",
  inventory_image = "cards_deck_52.png",
})

register_deck("104", {
  cardname = "blue",
  number_of_suits = 8,
  number_of_values = 13,
  colors = {"#FA0", "#F00", "#0B0", "#000"},
  suits = {"tiles", "hearts", "pikes", "clovers", "tiles", "hearts", "pikes", "clovers"},
  suit_textures = {
    "cards_tile.png",
    "cards_heart.png",
    "cards_pike.png",
    "cards_clover.png"
  },
  values = { "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"},
  value_textures = {
    "cards_2.png",
    "cards_3.png",
    "cards_4.png",
    "cards_5.png",
    "cards_6.png",
    "cards_7.png",
    "cards_8.png",
    "cards_9.png",
    "cards_10.png",
    "cards_J.png",
    "cards_Q.png",
    "cards_K.png",
    "cards_A.png"
  },
  back_texture = "cards_back.png",
  inventory_image = "cards_deck_104.png",
})

register_deck("JOKER", {
  cardname = "JOKER",
  number_of_suits = 3,
  number_of_values = 2,
  colors = {"#000", "#F00", "#800"},
  suits = {"black", "red", "dark"},
  suit_textures = {
    "cards_joker.png",
    "cards_joker.png",
    "cards_joker.png"
  },
  values = { "joker", "joker"},
  value_textures = {
    "cards_J.png",
  },
  back_texture = "cards_back.png",
  inventory_image = "cards_deck_joker.png",
})

------
-- Box

local show_box_formspec = function(itemstack, player, pointed_thing, formpart)
  if player:is_player() then
    if not formpart then
      formpart = ""
    end
    minetest.show_formspec(player:get_player_name(), "cards:card_box", 
      box_form..formpart.."button[6,0;4,1;collect;collect from inventory]".."label[0,0;Parts left:"..
      math.floor(itemstack:get_count()).."]")
  end 
end
local show_box_formspec_open = function(itemstack, player, pointed_thing)
  return show_box_formspec(itemstack, player, pointed_thing, "button_exit[4,0;2,1;close;close]")
end
local show_box_formspec_closed = function(itemstack, player, pointed_thing)
  return show_box_formspec(itemstack, player, pointed_thing, "button_exit[4,0;2,1;open;open]")
end


minetest.register_node("cards:card_box_open", {
  description = "Box which spawns card decks",
  drawtype = "nodebox",
  node_box = {
      type = "fixed",
      fixed = {{0.5, -0.5, -0.5, -0.125, 0 , 0.5},
               {-0.125, 0, -0.5, -0.25, 0.625 , 0.5},}
  },
  tiles = {"default_wood.png^cards_card_box_top.png","default_wood.png",
           "default_wood.png", "default_wood.png",
           "default_wood.png", "default_wood.png"
  },
  paramtype = "light",
  stack_max = CARDS_PER_BOX,
  on_place = show_box_formspec_open,
  on_secondary_use = show_box_formspec_open,
  on_use = function(itemstack, player, pointed_thing) --leftclick
    if pointed_thing.type ~= "node" then
      return nil
    end
    local pos = pointed_thing.under
    if minetest.is_protected(pos, player:get_player_name()) then
      return nil
    end
    local node = minetest.get_node(pos)
    if  minetest.get_node_group(node.name, "card")  == 0 and
        minetest.get_node_group(node.name, "jeton") == 0 then
      return nil
    end
    local meta = minetest.get_meta(pos)
    local count = meta:get_int("infotext")
    if count == 0 then
      count = 1
    end
    itemstack:set_count(itemstack:get_count() + count)
    minetest.remove_node(pos)
    return itemstack
  end,
})
minetest.register_node("cards:card_box", {
  description = "Box which spawns card decks",
  drawtype = "nodebox",
  node_box = {
      type = "fixed",
      fixed = {{0.5, -0.5, -0.5, -0.125, 0.125 , 0.5}}
  },
  tiles = {"default_wood.png","default_wood.png",
           "default_wood.png", "default_wood.png",
           "default_wood.png", "default_wood.png"
  },
  paramtype = "light",
  stack_max = CARDS_PER_BOX,
  on_place = show_box_formspec_closed,
  on_secondary_use = show_box_formspec_closed,
  on_use = function(itemstack, player, pointed_thing) --leftclick
    if pointed_thing.type ~= "node" then
      return nil
    end
    local pos = pointed_thing.under
    if minetest.is_protected(pos, player:get_player_name()) then
      return nil
    end
    local node = minetest.get_node(pos)
    if  minetest.get_node_group(node.name, "card")  == 0 and
        minetest.get_node_group(node.name, "jeton") == 0 then
      return nil
    end
    minetest.chat_send_player(player:get_player_name(), "Open in menu to collect pieces")
    return nil
  end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "cards:card_box" then
      return false
    end
    local itemstack = player:get_wielded_item()
    if fields.open then
      itemstack:set_name("cards:card_box_open")
      player:set_wielded_item(itemstack)
      return true
    end
    if fields.close then
      itemstack:set_name("cards:card_box")
      player:set_wielded_item(itemstack)
      return true
    end
    if fields.quit then
      return true
    end
    local inv = player:get_inventory()
    if fields.collect then
      local collected = 0
      local list = inv:get_list("main")
      for i, stack in ipairs(list) do
        local name = stack:get_name()
        if  minetest.get_item_group(name, "card")  > 0 or
            minetest.get_item_group(name, "jeton") > 0 then
          collected = collected + stack:get_count()
          stack:clear()
          list[i]=stack
        end
      end
      inv:set_list("main", list)
      itemstack:set_count(itemstack:get_count() + collected)
      player:set_wielded_item(itemstack)
      show_box_formspec(itemstack, player)
      return true
    end
    for key,value in pairs(fields) do  
      local d = string.find(key,"#")
      local itemname = string.sub(key,1,d-1)
      local cost = tonumber(string.sub(key, d+1))
      local count = itemstack:get_count()
      if cost < count then
        inv:add_item("main", itemname.." "..value)
        itemstack:set_count(count-cost)
      end
    end
    player:set_wielded_item(itemstack)
    show_box_formspec(itemstack, player)
    return true
end)


---------
-- Jetons

local function set_count(pos, placer, itemstack, pointed_thing)
  minetest.chat_send_all("hello")
  local stack_count = itemstack:get_count()
  local meta  = minetest.get_meta(pos)
  local count = meta:get_int("infotext")
  meta:set_int("infotext", count + stack_count)
  itemstack:clear()
  return itemstack
end

local function register_jeton(name, color)

  local texture = "cards_jeton.png^[colorize:"..color.."^[noalpha"
  local node_name = "cards:jeton_"..name
  box_form = box_form..
      "item_image_button["..num_decks..",2;1,1;"..node_name..";"..node_name.."#1;1]"..
      "label["..num_decks..",1;"..name.."]"..
      "button["..(num_decks)..",3;0.5,1;".. node_name.."#10;10]"..
      "button["..(num_decks + 0.5)..",3;0.5,1;".. node_name.."#99;99]"
  num_decks = num_decks + 1
  minetest.register_node(node_name, {
    description = "jeton "..name,
    inventory_image = texture,
    wield_image = texture,
    drawtype = "nodebox",
    node_box = {
      type = "fixed",
      fixed = {{-0.5, -0.5, -0.5, 0.5, -0.4375 , 0.5}}
    },
    tiles = {texture},
    paramtype = "light",
    on_place = function(itemstack, placer, pointed_thing)
      if pointed_thing.type ~= "node" then
        return
      end 
      local pos  = pointed_thing.under
      local node = minetest.get_node(pos)
      if node.name ~= node_name then
        pos = pointed_thing.above
        return minetest.item_place(itemstack, placer, pointed_thing)
      end
      if minetest.is_protected(pos, placer:get_player_name()) then
        return
      end
      itemstack = set_count(pos, placer, itemstack, pointed_thing) -- add jetons to stack
      return itemstack
    end,
    after_place_node = set_count,
    on_dig = function(pos, node, player)
      if minetest.is_protected(pos, player:get_player_name()) then
        return
      end
      local meta  = minetest.get_meta(pos)
      local count = meta:get_int("infotext")
      minetest.node_dig(pos, node, player)
      node = minetest.get_node(pos)
      if node.name == node_name then return end
      player:get_inventory():add_item("main", {
        name = node_name, 
        count = count - 1, -- 1 item is added by minetest.node_dig(...)
        wear = 0, 
        metadata = ""
      })
    end,
    groups = {oddly_breakable_by_hand = 3, jeton = 1},
  })
end

register_jeton("blue",   "#00F:224")
register_jeton("red",    "#F00:224")
register_jeton("black",  "#000:224")
register_jeton("green",  "#0A0:224")
register_jeton("yellow", "#FF0:224")

---------
-- Crafts

minetest.register_craft({
  output = "cards:card_box "..CARDS_PER_BOX,
  recipe = {{"default:chest",    "dye:black",     "dye:green"},
            {"default:clay_lump","dye:red"  ,     "dye:blue"},
            {"default:paper",    "default:paper", "default:paper"},} 
})

minetest.register_craft({
  output = "cards:card_box",
  recipe = {{"group:jeton"}}, 
})

minetest.register_craft({
  output = "cards:card_box",
  recipe = {{"group:card"}}, 
})




