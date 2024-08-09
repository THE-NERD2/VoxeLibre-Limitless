vll_morph = {}

vll_morph.registered_mobs = {}
vll_morph.morphed_players = {}

local function unmorph(player_name, quiet)
	if not vll_morph.morphed_players[player_name] then
		if not quiet then
			minetest.chat_send_player(player_name, "You are not morphed!")
		end
		return true
	end

	local player = minetest.get_player_by_name(player_name)
	mcl_mobs.detach(player)
	vll_morph.morphed_players[player_name].mob:get_luaentity().object:remove()
	vll_morph.morphed_players[player_name] = nil
	if not quiet then
		minetest.chat_send_player(player_name, "Successfully unmorphed!")
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
		entity.driver_attach_at = vector.zero()
		entity.driver_eye_offset = vector.multiply(vector.subtract(vector.new(0, entity.head_eye_height, 0), vector.new(0, 2.2, 0)), 6) -- Why...? It works though.
		minetest.log(vector.to_string(entity.driver_eye_offset))
		entity.driver_scale = {x = 0, y = 0}
		mcl_mobs.attach(entity, player)
		vll_morph.morphed_players[player_name] = {
			mob = mob,
			details = vll_morph.registered_mobs[mob_name].details
		}
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

function vll_morph.register_mob(name, details, morph_details) -- TODO: include control overrides
	local new_details = table.copy(details)
	if not details.do_custom then
		new_details.do_custom = function(self, dtime)
			if self.driver then
				mcl_mobs.control(self, "walk", "stand", dtime)
				return false
			end
		end
	else
		new_details.do_custom = function(self, dtime)
			details.do_custom(self, dtime)
			if self.driver then
				mcl_mobs.control(self, "walk", "stand", dtime)
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
		details = morph_details
	}
end