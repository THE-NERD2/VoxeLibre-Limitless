local current_modpath = minetest.get_modpath(minetest.get_current_modname())

vll_morph = {}

vll_morph.registered_mobs = {}
vll_morph.morphed_players = {}

dofile(current_modpath .. "/control.lua") -- Import control and set_animation functions

local function unmorph(player_name, quiet)
	if not vll_morph.morphed_players[player_name] then
		if not quiet then
			minetest.chat_send_player(player_name, "You are not morphed!")
		end
		return true
	end

	local player = minetest.get_player_by_name(player_name)
	local entity = vll_morph.morphed_players[player_name].mob:get_luaentity()
	if entity then
		mcl_mobs.detach(player)
		player:set_pos(entity.object:get_pos())
		entity.object:remove()
		player:set_properties(vll_morph.morphed_players[player_name].previous_properties)
		vll_morph.morphed_players[player_name] = nil
		if not quiet then
			minetest.chat_send_player(player_name, "Successfully unmorphed!")
		end
	end
	return true
end
minetest.register_chatcommand("unmorph", {
	description = "Morph back into player",
	func = unmorph
})
local function morph(player_name, mob_name)
	unmorph(player_name, true)
	
	if not vll_morph.registered_mobs[mob_name] then
		minetest.chat_send_player(player_name, "Mob " .. mob_name .. " does not exist!")
		return true
	end
	
	local player = minetest.get_player_by_name(player_name)
	local mob = minetest.add_entity(player:get_pos(), mob_name)
	if mob then
		local entity = mob:get_luaentity()
		entity.player_rotation = vector.zero()
		local required_offset = vll_morph.registered_mobs[mob_name].morph_details.required_offset or 0
		entity.driver_attach_at = vector.new(0, required_offset, 0)
		entity.driver_eye_offset = vector.new(0, (entity.head_eye_height - 2.2) * 16 - required_offset, -entity.horizontal_head_height * 16)
		entity.object:set_properties({
			collisionbox = {-.005, -.005, -.005, .005, .005, .005},
			visual_size = {x = 0.01, y = 0.01} -- Should be not only invisible but nonexistent (cannot be zero because then player is invisible too)
		})
		mcl_mobs.attach(entity, player, false)
		local previous_properties = player:get_properties()
		player:set_properties({
			visual = "mesh",
			mesh = vll_morph.registered_mobs[mob_name].details.mesh,
			textures = vll_morph.registered_mobs[mob_name].details.textures[1]
		})
		if not vll_morph.registered_mobs[mob_name].details.visual_size then
			player:set_properties({
				visual_size = {x = 100, y = 100}
			})
		else
			player:set_properties({
				visual_size = {
					x = vll_morph.registered_mobs[mob_name].details.visual_size.x * 100,
					y = vll_morph.registered_mobs[mob_name].details.visual_size.y * 100
				}
			})
		end
		vll_morph.morphed_players[player_name] = {
			previous_properties = previous_properties,
			mob = mob,
			details = vll_morph.registered_mobs[mob_name].details,
			morph_details = vll_morph.registered_mobs[mob_name].morph_details
		}
		-- TODO: set standing animation (just doing it doesn't work)
		minetest.chat_send_player(player_name, "Successfully morphed into a " .. mob_name .. "!")
	else
		minetest.chat_send_player(player_name, "Failed to morph into a " .. mob_name .. "!")
	end
	return true
end
minetest.register_chatcommand("morph", {
	params = "<mob_name>",
	description = "Morph into a mob",
	func = morph
})

function vll_morph.register_mob(name, details, morph_details)
	local new_details = table.copy(details)
	if not details.do_custom then
		new_details.do_custom = function(self, dtime)
			if self.driver then
				vll_morph.control(self, "walk", "stand", dtime)
				return false
			end
		end
	else
		new_details.do_custom = function(self, dtime)
			details.do_custom(self, dtime)
			if self.driver then
				vll_morph.control(self, "walk", "stand", dtime)
				return false
			end
		end
	end
	if not details.on_die then
		new_details.on_die = function(self)
			if self.driver then
				local driver = self.driver
				unmorph(driver:get_player_name(), true)
				driver:set_hp(0)
			end
		end
	else
		new_details.on_die = function(self)
			details.on_die(self)
			if self.driver then
				local driver = self.driver
				unmorph(driver:get_player_name(), true)
				driver:set_hp(0)
			end
		end
	end
	mcl_mobs.register_mob(name, new_details)
	vll_morph.registered_mobs[name] = {
		details = details,
		morph_details = morph_details or {}
	}
end