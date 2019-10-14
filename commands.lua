turtlebot.commands = {};
local commands = turtlebot.commands

turtlebot.directions = {
  left = 1, right = 2, forward = 3, backward = 4, up = 5, down = 6, 
  left_down = 7, right_down = 8, forward_down = 9, backward_down = 10,
  left_up = 11, right_up = 12, forward_up = 13,  backward_up = 14
}
local directions = turtlebot.directions

turtlebot.opposite_direction = {
  [directions.left] = directions.right, [directions.right] = directions.left, 
  [directions.forward] = directions.backward, [directions.backward] = directions.forward, 
  [directions.up] = directions.down, [directions.down] = directions.up, 
  [directions.left_down] = directions.right_up, [directions.right_down] = directions.left_up,
  [directions.forward_down] = directions.backward_up, [directions.backward_down] = directions.forward_up,
  [directions.left_up] = directions.right_down, [directions.right_up] = directions.left_down, 
  [directions.forward_up] = directions.backward_down,  [directions.backward_up] = directions.forward_down
}

turtlebot.plant_table  = {
  ["farming:seed_barley"] = "farming:barley_1",
  ["farming:beans"] = "farming:beanpole_1", -- so it works with farming redo mod
  ["farming:blueberries"] = "farming:blueberry_1",
  ["farming:carrot"] = "farming:carrot_1",
  ["farming:cocoa_beans"] = "farming:cocoa_1",
  ["farming:coffee_beans"] = "farming:coffee_1",
  ["farming:corn"] = "farming:corn_1",
  ["farming:seed_cotton"] = "farming:cotton_1",
  ["farming:cucumber"] = "farming:cucumber_1",
  ["farming:grapes"] = "farming:grapes_1",
  ["farming:melon_slice"] = "farming:melon_1",
  ["farming:potato"] = "farming:potato_1",
  ["farming:pumpkin_slice"] = "farming:pumpkin_1",
  ["farming:raspberries"] = "farming:raspberry_1",
  ["farming:rhubarb"] = "farming:rhubarb_1",
  ["farming:tomato"] = "farming:tomato_1",
  ["farming:seed_wheat"] = "farming:wheat_1"
}

local pi = math.pi;

local function tick(pos) -- needed for plants to start growing: minetest 0.4.14 farming
	minetest.get_node_timer(pos):start(math.random(166, 286))
end

local function pos_in_dir(obj, dir) -- position after we move in specified direction
	local yaw = obj:getyaw();
	local pos = obj:getpos();
	
	if dir == directions.left then
		yaw = yaw + pi/2;
	elseif dir == directions.right then
		yaw = yaw - pi/2;
	elseif dir == directions.forward then
	elseif dir == directions.backward then 
		yaw = yaw+pi;
	elseif dir ==  directions.up then
		pos.y = pos.y + 1
	elseif dir ==  directions.down then
		pos.y = pos.y - 1
	elseif dir ==  directions.left_down then
    yaw = yaw + pi/2;
    pos.y = pos.y - 1
	elseif dir ==  directions.right_down then
    yaw = yaw - pi/2;
    pos.y = pos.y - 1
	elseif dir ==  directions.forward_down then
		pos.y = pos.y - 1
	elseif dir ==  directions.backward_down then
    yaw = yaw + pi;
    pos.y = pos.y - 1
	elseif dir ==  directions.left_up then
    yaw = yaw + pi/2;
    pos.y = pos.y + 1
	elseif dir ==  directions.right_up then
    yaw = yaw - pi/2;
    pos.y = pos.y + 1
	elseif dir ==  directions.forward_up then
		pos.y = pos.y + 1
	elseif dir ==  directions.backward_up then
    yaw = yaw + pi;
    pos.y = pos.y + 1
	end
	
	if dir ~= directions.up and dir ~= directions.down then 
		pos.x = pos.x - math.sin(yaw)
		pos.z = pos.z + math.cos(yaw)
	end
	
	return pos
end

commands.move = function(spawnPos, dir)
	local turtle = turtlebot.get(spawnPos);
	local obj = turtle.obj;
	local pos = pos_in_dir(obj, dir)
		
	-- can move through walkable nodes
  if minetest.registered_nodes[minetest.get_node(pos).name].walkable then return end
	-- up; no levitation!
	if minetest.get_node({x=pos.x,y=pos.y-1,z=pos.z}).name == "air" and
			minetest.get_node({x=pos.x,y=pos.y-2,z=pos.z}).name == "air" then 
		minetest.chat_send_player(turtle.owner, "Turtles can't fly")
		return false
	end

	obj:moveto(pos, true)
	
	return true
end

commands.turn = function (spawnPos, angle)
	local obj = turtlebot.get(spawnPos).obj;
	local yaw;
	-- more precise turns by 1 degree resolution
	local mult = math.pi/180;
	local yaw = obj:getyaw();
	yaw = math.floor((yaw+angle)/mult+0.5)*mult;
	obj:setyaw(yaw);
end

commands.dig = function(spawnPos, dir)
	local obj = turtlebot.get(spawnPos).obj;
	local pos = pos_in_dir(obj, dir)	
	
	local luaent = obj:get_luaentity();
	if minetest.is_protected(pos, luaent.owner) then return false end
	
	local nodename = minetest.get_node(pos).name;
	if nodename == "air" or nodename=="ignore" then return false end
	
	local spos = obj:get_luaentity().spawnpos; 
	local inv = minetest.get_meta(spos):get_inventory();

  minetest.set_node(pos,{name = "air"})
	
	--DS: sounds
	local sounds = minetest.registered_nodes[nodename].sounds
	if sounds then
		local sound = sounds.dug
		if sound then
			minetest.sound_play(sound,{pos=pos, max_hear_distance = 10})
		end
	end
	
	return true
end

commands.read_node = function(spawnPos, dir)
	local obj = turtlebot.get(spawnPos).obj;
	local pos = pos_in_dir(obj, dir)	
	return minetest.get_node(pos).name or ""
end

commands.place = function(spawnPos, nodename, param2, dir)
	local obj = turtlebot.get(spawnPos).obj;
	local pos = pos_in_dir(obj, dir)	
	local luaent = obj:get_luaentity();
	if minetest.is_protected(pos, luaent.owner) then return false end
	if minetest.get_node(pos).name ~= "air" then return false end
	
	local spos = obj:get_luaentity().spawnpos; 
	
	--DS
	local registered_node = minetest.registered_nodes[nodename];
	if registered_node then
		local sounds = registered_node.sounds
		if sounds then
			local sound = sounds.place
			if sound then
				minetest.sound_play(sound,{pos=pos, max_hear_distance = 10})
			end
		end
	end
	
	local plantName = turtlebot.plant_table[nodename];
	if plantName then
		minetest.set_node(pos, {name = plantName})
		tick(pos); -- needed for seeds to grow
	else -- normal place
		if param2 then
			minetest.set_node(pos, {name = nodename, param2 = param2})
		else
			minetest.set_node(pos, {name = nodename})
		end
	end
	
	return true
end