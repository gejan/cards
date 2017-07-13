

local NUMBER_OF_SUITS  = 4
local NUMBER_OF_VALUES = 13
local ENGLISH_STYLE = true

local colors  = {"#FA0", "#F00", "#0B0", "#000"} -- four color skat deck
-- local colors = {"#F00", "#F00", "#000", "#000"} -- default: red, black
local suits = {"tiles", "hearts", "pikes", "clovers"}
local suit_textures = {
  "cards_tile.png",
  "cards_heart.png",
  "cards_pike.png",
  "cards_clover.png"
}
local values = {"7", "8", "9", "10", "B", "D", "K", "A", "2", "3", "4", "5", "6"}
local value_textures = {
  "cards_7.png",
  "cards_8.png",
  "cards_9.png",
  "cards_10.png",
  "cards_B.png",
  "cards_D.png",
  "cards_K.png",
  "cards_A.png",
  "cards_2.png",
  "cards_3.png",
  "cards_4.png",
  "cards_5.png",
  "cards_6.png"
}
if ENGLISH_STYLE then
  value_textures[5] = "cards_J.png"
  value_textures[6] = "cards_Q.png"
end


math.randomseed(os.time())

local function register_stack(size)
  minetest.register_node("cards:stack_"..size, {
    description = "set of playing cards ("..size..")",
    inventory_image = "cards_back.png",
    wield_image = "cards_back.png",
    drawtype = "nodebox",
    node_box = {
      type = "fixed",
      fixed = {{-0.5, -0.5, -0.5, 0.5, -0.25 , 0.5}}
    },
    tiles = {"cards_back.png",     "cards_back.png",
        "cards_side.png", "cards_side.png",
        "cards_side.png", "cards_side.png"
    },
    paramtype = "light",
    paramtype2 = "facedir",
    on_dig = function(pos, node, player)
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
    after_place_node = function(pos, placer, itemstack, pointed_thing)
      local meta = minetest.get_meta(pos)
      local count = size
      local set = {}
      for s = 1, NUMBER_OF_SUITS do
        for v = 1, size / NUMBER_OF_SUITS do
          local r = math.random(1, count)
          local i = -1
          while r > 0 do
            i = i + 1 
            if not set[i] then
              r = r - 1
            end
          end 
          set[i] = true
          meta:set_string(i, "cards:card_"..suits[s].."_"..values[v])
          count = count - 1
        end
      end
      meta:set_int("count", size - 1)
      meta:set_string("infotext", size)
      meta:set_string("formspec",
        "size[2,4]"..
        "button_exit[0,0;2,1;flip;flip]"..
        "button_exit[0,1;2,1;collect;collect]"..
        "button_exit[0,2;2,1;shuffle;shuffle]"..
        "button_exit[0,3;2,1;quit;quit]")
    end,
    on_receive_fields = function(pos, formname, fields, player)
      if fields.collect then 
        local meta = minetest.get_meta(pos)
        if meta:get_int("count") == 31 then
          player:get_inventory():add_item("main", 
              "cards:stack_"..size)
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
        minetest.swap_node(pos, {name = meta:get_string(count)})
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
    groups = {oddly_breakable_by_hand = 1, card = 2},
  })
end
register_stack(32)
register_stack(52)


for s = 1, NUMBER_OF_SUITS do
  for v = 1, NUMBER_OF_VALUES do
    local name = "cards:card_"..suits[s].."_"..values[v]
    local texture = value_textures[v].."^"..suit_textures[s].."^[colorize:"..colors[s].."^[noalpha"
    minetest.register_node(name, {
      description = suits[s].." "..values[v],
      inventory_image = texture,
      wield_image = "cards_back.png",
      drawtype = "nodebox",
      node_box = {
        type = "fixed",
        fixed = {{-0.5, -0.5, -0.5, 0.5, -0.4375 , 0.5}}
      },
      tiles = {texture,     "cards_back.png",
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
        -- add card to stack
        local meta  = minetest.get_meta(pos)
        local count = meta:get_int("count")
        if count == 0 then
          meta:set_string(count, node.name)
          meta:set_string("formspec",
              "size[3,5]"..
              "button_exit[0,0;3,1;flip;flip]"..
              "button_exit[0,1;3,1;collect;collect]"..
              "button_exit[0,2;3,1;shuffle;shuffle]"..
              "button_exit[0,3;3,1;delete;not show again]"..
              "button_exit[0,4;3,1;quit;quit]")
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
          if meta:get_int("count") == 31 then
            player:get_inventory():add_item("main", 
                "cards:stack_32")
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
          minetest.swap_node(pos, {name = "cards:stack_32"}) -- TODO support both stacks
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
      groups = {oddly_breakable_by_hand = 1, card = 1},
    })
  end
end

local function register_jeton(name, color)
  local texture = "cards_jeton.png^[colorize:"..color.."^[noalpha"
  local node_name = "cards:jeton_"..name
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
        minetest.item_place(itemstack, placer, pointed_thing)
        local node = minetest.get_node(pos)
        if node.name ~= node_name then
          return itemstack
        end
      end
      -- add jetons to stack
      local meta  = minetest.get_meta(pos)
      local count = meta:get_int("infotext")
      meta:set_int("infotext", count + itemstack:get_count())
      itemstack:clear()
      return itemstack
    end,
    on_dig = function(pos, node, player)
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
    groups = {oddly_breakable_by_hand = 1},
  })
end

register_jeton("blue",   "#00F:224")
register_jeton("red",    "#F00:224")
register_jeton("black",  "#000:224")
register_jeton("green",  "#0A0:224")
register_jeton("yellow", "#FF0:224")

