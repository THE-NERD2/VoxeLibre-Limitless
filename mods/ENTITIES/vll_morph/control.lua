local node_ok = function(pos, fallback)

	fallback = fallback or mcl_mobs.fallback_node

	local node = minetest.get_node_or_nil(pos)

	if node and minetest.registered_nodes[node.name] then
		return node
	end

	return {name = fallback}
end

local function node_is(pos)

	local node = node_ok(pos)

	if node.name == "air" then
		return "air"
	end

	if minetest.get_item_group(node.name, "lava") ~= 0 then
		return "lava"
	end

	if minetest.get_item_group(node.name, "liquid") ~= 0 then
		return "liquid"
	end

	if minetest.registered_nodes[node.name].walkable == true then
		return "walkable"
	end

	return "other"
end

local current_animations = {}
function vll_morph.set_animation(player, anim, fixed_frame) -- For players
	local player_name = player:get_player_name()
	local morph_details = vll_morph.morphed_players[player_name]

	if not morph_details.details.animation or not anim then
		return
	end
	
	if player.state == "die" and anim ~= "die" and anim ~= "stand" then
		return
	end



	--if player.fly and player:flight_check() and anim == "walk" then anim = "fly" end

	current_animations[player_name] = current_animations[player_name] or ""

	if (anim == current_animations[player_name]
	or not morph_details.details.animation[anim .. "_start"]
	or not morph_details.details.animation[anim .. "_end"]) and player.state ~= "die" then
		return
	end

	current_animations[player_name] = anim

	local a_start = morph_details.details.animation[anim .. "_start"]
	local a_end
	if fixed_frame then
		a_end = a_start
	else
		a_end = morph_details.details.animation[anim .. "_end"]
	end
	if a_start and a_end then
		player:set_animation({
			x = a_start,
			y = a_end},
			morph_details.details.animation[anim .. "_speed"] or morph_details.details.animation.speed_normal or 15,
			0, morph_details.details.animation[anim .. "_loop"] ~= false)
		end
end

function vll_morph.control(entity, moving_anim, stand_anim, dtime) -- TODO: add run animation
	entity.object:set_yaw(entity.driver:get_look_horizontal() - entity.rotate)
	
	local yaw = entity.object:get_yaw()
	local forward = minetest.yaw_to_dir(yaw)
	yaw = yaw + (math.pi / 2) % (2 * math.pi)
	local left = minetest.yaw_to_dir(yaw)
	local current_v = entity.object:get_velocity()

	local control = entity.driver:get_player_control()

	local v = vector.zero()
	v.y = current_v.y
	if control.up then
		v = vector.add(v, forward)
	end
	if control.down then
		v = vector.add(v, vector.multiply(forward, -1))
	end
	if control.left then
		v = vector.add(v, left)
	end
	if control.right then
		v = vector.add(v, vector.multiply(left, -1))
	end
	local y_accel = 0
	if control.jump then
		if current_v.y == 0 then
			v.y = entity.jump_height
			y_accel = 1
		end
	end
	
	-- Stop!
	if vector.distance(v, vector.zero()) == 0 and vector.distance(current_v, vector.zero()) == 0 then
		entity.object:set_velocity(vector.zero())
		if stand_anim then
			vll_morph.set_animation(entity.driver, stand_anim)
		end
		return
	end

	-- set moving animation
	if moving_anim then
		vll_morph.set_animation(entity.driver, moving_anim)
	end
	
	-- Set position, velocity and acceleration
	local p = entity.object:get_pos()
	local new_velo
	local new_acce = vector.new(0, -9.8, 0)

	p.y = p.y - 0.5

	local ni = node_is(p)
	local speed
	if control.up and control.aux1 then
		speed = entity.run_velocity
	else
		speed = entity.walk_velocity
	end

	if ni == "liquid" or ni == "lava" then

		if ni == "lava" and entity.lava_damage ~= 0 then

			entity.lava_counter = (entity.lava_counter or 0) + dtime

			if entity.lava_counter > 1 then

				minetest.sound_play("default_punch", {
					object = entity.object,
					max_hear_distance = 5
				}, true)

				entity.object:punch(entity.object, 1.0, {
					full_punch_interval = 1.0,
					damage_groups = {fleshy = entity.lava_damage}
				}, nil)

				entity.lava_counter = 0
			end
		end

		if entity.terrain_type == 2
		or entity.terrain_type == 3 then

			new_acce.y = 0
			p.y = p.y + 1

			if node_is(p) == "liquid" then

				if v.y >= 5 then
					v.y = 5
				elseif v.y < 0 then
					new_acce.y = 20
				else
					new_acce.y = 5
				end
			else
				if math.abs(v.y) < 1 then
					local pos = entity.object:get_pos()
					pos.y = math.floor(pos.y) + 0.5
					entity.object:set_pos(pos)
					v.y = 0
				end
			end
		else
			speed = speed * 0.25
		end
	end
	
	local vy = v.y
	v.y = 0
	new_velo = vector.multiply(vector.normalize(v), speed)
	new_velo.y = vy
	new_acce.y = new_acce.y + y_accel

	entity.object:set_velocity(new_velo)
	entity.object:set_acceleration(new_acce)
end