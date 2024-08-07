vll_better_combat = {}

vll_better_combat.default_attack_table = {}
vll_better_combat.default_attack_table.directional_offensive = function(vbc_details, pos1, pos2)
	-- TODO
end
vll_better_combat.default_attack_table.inward_offensive = function(vbc_details, dir)
	-- TODO
end
vll_better_combat.default_attack_table.directional_defensive = function(vbc_details, pos1, pos2)
	-- TODO
end
vll_better_combat.default_attack_table.inward_defensive = function(vbc_details, dir)
	-- Not really a thing; not default implementation
end

local weapon_details = {}
function vll_better_combat.register_melee(name, details, vbc_details, attack_table)
	if attack_table == nil then attack_table = vll_better_combat.default_attack_table
	minetest.register_tool(name, details)
	weapon_details[name] = {
		details = vbc_details,
		attacks = attack_table
	}
end

local first_directions = {}
controls.register_on_press(function(player, key)
	if not weapon_details[player:get_wielded_item():get_name()] then return end
	if key == "LMB" or key == "RMB" then
		first_directions[player:get_player_name()] = player:get_look_dir()
	end
end
controls.register_on_release(function(player, key)
	if not weapon_details[player:get_wielded_item():get_name()] then
		if key ~= "LMB" and key ~= "RMB" then
			first_directions[player:get_player_name()] = nil
		end
		return
	end
	if key == "LMB" or key == "RMB" then
		local dir1 = first_directions[player:get_player_name()]
		local dir2 = player:get_look_dir()
		local details = weapon_details[player:get_wielded_item():get_name()]
		first_directions[player:get_player_name()] = nil
		if vector.distance(dir1, dir2) < 0.1 then
			local dir = vector.divide(vector.add(dir1, dir2), 2) -- Between
			if key == "LMB" then
				details.attacks.inward_offensive(details.details, dir)
			else
				details.attacks.inward_defensive(details.details, dir)
			end
		else
			if key == "LMB" then
				details.attacks.directional_offensive(details.details, dir1, dir2)
			else
				details.attacks.directional_defensive(details.details, dir1, dri2)
			end
		end
	end
end