vll_better_combat = {}

vll_better_combat.default_attack_table = {}
vll_better_combat.default_attack_table.directional_offensive = function(pos1, pos2)
	-- TODO
end
vll_better_combat.default_attack_table.inward_offensive = function(dir)
	-- TODO
end
vll_better_combat.default_attack_table.directional_defensive = function(pos1, pos2)
	-- TODO
end
vll_better_combat.default_attack_table.inward_defensive = function(dir)
	-- TODO
end

function vll_better_combat.register_melee(name, details, attack_table)
	if attack_table == nil then attack_table = vll_better_combat.default_attack_table
	minetest.register_tool(name, details)
end