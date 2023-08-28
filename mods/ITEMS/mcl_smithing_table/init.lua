--[[
By EliasFleckenstein03 and Code-Sploit
]]

local S = minetest.get_translator("mcl_smithing_table")
mcl_smithing_table = {}

-- Function to upgrade diamond tool/armor to netherite tool/armor
function mcl_smithing_table.upgrade_item_netherite(itemstack)
	local def = itemstack:get_definition()

	if not def or not def._mcl_upgradable then
		return
	end
	local itemname = itemstack:get_name()
	local upgrade_item = itemname:gsub("diamond", "netherite")

	if def._mcl_upgrade_item and upgrade_item == itemname then
		return
	end

	itemstack:set_name(upgrade_item)
	mcl_armor.reload_trim_inv_image(itemstack)

	-- Reload the ToolTips of the tool

	tt.reload_itemstack_description(itemstack)

	-- Only return itemstack if upgrade was successfull
	return itemstack
end

-- Badly copied over from mcl_anvils
-- ToDo: Make better formspec

local formspec = "size[9,9]" ..
		"background[-0.19,-0.25;9.41,9.49;mcl_smithing_table_inventory.png]"..
		"label[0,4.0;" .. minetest.formspec_escape(minetest.colorize(mcl_colors.DARK_GRAY, S("Inventory"))) .. "]" ..
		"list[current_player;main;0,4.5;9,3;9]" ..
		mcl_formspec.get_itemslot_bg(0,4.5,9,3) ..
		"list[current_player;main;0,7.74;9,1;]" ..
		mcl_formspec.get_itemslot_bg(0,7.74,9,1) ..
		"list[context;upgrade_item;1,2.5;1,1;]" ..
		mcl_formspec.get_itemslot_bg(1,2.5,1,1) ..
		"list[context;mineral;4,2.5;1,1;]" ..
		mcl_formspec.get_itemslot_bg(4,2.5,1,1) ..
		"list[context;template;5,2.5;1,1;]"..
		mcl_formspec.get_itemslot_bg(5,2.5,1,1)..
		"list[context;upgraded_item;8,2.5;1,1;]" ..
		mcl_formspec.get_itemslot_bg(8,2.5,1,1) ..
		"label[3,0.1;" .. minetest.formspec_escape(minetest.colorize(mcl_colors.DARK_GRAY, S("Upgrade Gear"))) .. "]" ..
		"listring[context;output]"..
		"listring[current_player;main]"..
		"listring[context;input]"..
		"listring[current_player;main]"

local smithing_materials = {
	["mcl_nether:netherite_ingot"]	= "netherite",
	["mcl_core:diamond"]			= "diamond",
	["mcl_core:lapis"]				= "lapis",
	["mcl_amethyst:amethyst_shard"]	= "amethyst",
	["mesecons:wire_00000000_off"]	= "redstone",
	["mcl_core:iron_ingot"]			= "iron",
	["mcl_core:gold_ingot"]			= "gold",
	["mcl_copper:copper_ingot"]		= "copper",
	["mcl_core:emerald"]			= "emerald",
	["mcl_nether:quartz"]			= "quartz"
}	

function mcl_smithing_table.upgrade_trimmed(itemstack, color_mineral, template)
	--get information required
	local material_name = color_mineral:get_name()
	material_name = smithing_materials[material_name]

	local overlay = template:get_name():gsub("mcl_armor:","")

	--trimming process
	mcl_armor.trim(itemstack, overlay, material_name)
	--itemstack:set_name(itemstack:get_name() .. "_trimmed_" .. overlay .. "_" .. material_name)
	tt.reload_itemstack_description(itemstack)

	return itemstack
end

function mcl_smithing_table.is_smithing_mineral(itemname) 
	return smithing_materials[itemname] ~= nil
end

local function reset_upgraded_item(pos)
	local inv = minetest.get_meta(pos):get_inventory()
	local upgraded_item
	local original_itemname = inv:get_stack("upgrade_item", 1):get_name()
	local template_present = inv:get_stack("template",1):get_name() ~= ""
	local is_armor = original_itemname:find("mcl_armor:") ~= nil
	local is_trimmed = original_itemname:find("_trimmed") ~= nil

	if inv:get_stack("mineral", 1):get_name() == "mcl_nether:netherite_ingot" and not template_present then
		upgraded_item = mcl_smithing_table.upgrade_item_netherite(inv:get_stack("upgrade_item", 1))
	elseif template_present and is_armor and not is_trimmed and mcl_smithing_table.is_smithing_mineral(inv:get_stack("mineral", 1):get_name()) then
		upgraded_item = mcl_smithing_table.upgrade_trimmed(inv:get_stack("upgrade_item", 1),inv:get_stack("mineral", 1),inv:get_stack("template", 1))
	end

	inv:set_stack("upgraded_item", 1, upgraded_item)
end

minetest.register_node("mcl_smithing_table:table", {
	description = S("Smithing table"),
	-- ToDo: Add _doc_items_longdesc and _doc_items_usagehelp

	stack_max = 64,
	groups = {pickaxey = 2, deco_block = 1},

	tiles = {
		"mcl_smithing_table_top.png",
		"mcl_smithing_table_bottom.png",
		"mcl_smithing_table_side.png",
		"mcl_smithing_table_side.png",
		"mcl_smithing_table_side.png",
		"mcl_smithing_table_front.png",
	},

	sounds = mcl_sounds.node_sound_metal_defaults(),

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", formspec)

		local inv = meta:get_inventory()

		inv:set_size("upgrade_item", 1)
		inv:set_size("mineral", 1)
		inv:set_size("template",1)
		inv:set_size("upgraded_item", 1)
	end,

	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		if 			
					listname == "upgrade_item"  
			and	 	string.find(stack:get_name(),"mcl_armor:") -- allow any armor piece to go in (in case the player wants to trim them)
			and not mcl_armor.trims.blacklisted[stack:get_name()]

			or		listname == "mineral" 
			and		mcl_smithing_table.is_smithing_mineral(stack:get_name())

			or 		listname == "template"
			and		string.find(stack:get_name(),"mcl_armor") 
		then
			return stack:get_count()
		end

		return 0
	end,

	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		return 0
	end,

	on_metadata_inventory_put = reset_upgraded_item,

	on_metadata_inventory_take = function(pos, listname, index, stack, player)
		local inv = minetest.get_meta(pos):get_inventory()

		local function take_item(listname)
			local itemstack = inv:get_stack(listname, 1)
			itemstack:take_item()
			inv:set_stack(listname, 1, itemstack)
		end

		if listname == "upgraded_item" then
			take_item("upgrade_item")
			take_item("mineral")
			take_item("template")

			-- ToDo: make epic sound
			minetest.sound_play("mcl_smithing_table_upgrade", {pos = pos, max_hear_distance = 16})
		end
		if listname == "upgraded_item" then
			if stack:get_name() == "mcl_farming:hoe_netherite" then
				awards.unlock(player:get_player_name(), "mcl:seriousDedication")
			end
		end

		reset_upgraded_item(pos)
	end,

	_mcl_blast_resistance = 2.5,
	_mcl_hardness = 2.5
})


minetest.register_craft({
	output = "mcl_smithing_table:table",
	recipe = {
		{"mcl_core:iron_ingot", "mcl_core:iron_ingot", ""},
		{"group:wood", "group:wood", ""},
		{"group:wood", "group:wood", ""}
	}
})

-- this is the exact same as mcl_smithing_table.upgrade_item_netherite , in case something relies on the old function
function mcl_smithing_table.upgrade_item(itemstack)
	return mcl_smithing_table.upgrade_item_netherite(itemstack)
end