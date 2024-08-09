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
	local entity = vll_morph.morphed_players[player_name].mob:get_luaentity()
	if entity then
		mcl_mobs.detach(player)
		player:set_pos(entity.object:get_pos())
		entity.object:remove()
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
		local required_offset = vll_morph.registered_mobs[mob_name].details.required_offset or 0
		entity.driver_attach_at = vector.new(0, required_offset, 0)
		entity.driver_eye_offset = vector.new(0, (entity.head_eye_height - 2.2) * 16 - required_offset, -entity.horizontal_head_height * 16)
		entity.driver_scale = {x = 0, y = 0}
		entity.do_punch = function(self, hitter, time_from_last_punch, tool_capabilities, dir)
			if hitter:is_player() then
				if hitter:get_player_name() == player_name then
					local pos1 = vector.multiply(minetest.yaw_to_dir(self.object:get_yaw()), -self.horizontal_head_height * 16)
					pos1.y = (entity.head_eye_height - 2.2) * 16
					pos1 = vector.add(pos1, self.object:get_pos())
					local pos2 = vector.multiply(dir, self.reach)
					pos2 = vector.add(pos2, self.object:get_pos())
					local raycast = minetest.raycast(pos1, pos2)
					for pointed_thing in raycast do
						if pointed_thing.type == "object" then
							local obj = pointed_thing.ref
							if obj:is_player() or obj:get_luaentity() then
								if obj.driver then
									if obj.driver:get_player_name() == self.driver:get_player_name() then
										goto continue
									end
								end
								if tool_capabilities.damage_groups.fleshy == 1 then -- TODO: detect if this is a fist
									self.object:punch(obj, 1, {
										full_punch_interval = 0,
										damage_groups = {fleshy = self.damage}
									}, dir)
								else
									-- Add tool damage to punch damage, then subtract human punch damage
									self.object:punch(obj, time_from_last_punch, {
										full_punch_interval = tool_capabilities.full_punch_interval,
										damage_groups = {fleshy = tool_capabilities.damage_groups.fleshy + self.damage - 1}
									}, dir)
								end
								break
							end
						end
						::continue::
					end
				end
			else
				hitter:punch(self.driver, time_from_last_punch, {
					full_punch_interval = tool_capabilities.full_punch_interval,
					damage_groups = tool_capabilities.damage_groups
				})
			end
			return false
		end
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

function vll_morph.register_mob(name, details, morph_details)
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
		details = morph_details or {}
	}
end