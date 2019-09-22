local isActive = turtlebot.isActive
local activate = turtlebot.activate
local deactivate = turtlebot.deactivate

local function getSpawnerpos(meta)
	return stringToPos(meta:get_string("libpos"))
end


update_form = function (pos, mode)
	if not pos then return end
	local meta = minetest.get_meta(pos);
	if not meta then return end
	local code = minetest.formspec_escape(meta:get_string("code"));
	local form;

	if mode ~= 1 then -- when placed
		local startStop = function()
			if isActive(pos) then
				return "button[-0.2, 1.75;1.25,1;turtlebot_despawn;STOP]"
			else
				return "button_exit[-0.2, 1.75;1.25,1;turtlebot_spawn;START]"
			end
		end

		form  = 
			"size[9.5,8]" ..  -- width, height
			"textarea[1.25,-0.2;8.75,9.8;turtlebot_code;;".. code.."]"..
			"button_exit[-0.2,-0.25;1.25,1;turtlebot_save;SAVE]".. 
			startStop() ..
			"button_exit[-0.2,3.75;1.25,1;turtlebot_cancel;CANCEL]";
	else -- when robot clicked
		form  = 
			"size[9.5,8]" ..  -- width, height
			"textarea[1.25,-0.25;8.75,9.8;turtlebot_code;;".. code.."]"..
			"button_exit[-0.2,-0.25;1.25,1;turtlebot_save;SAVE]"..
			"button_exit[-0.2, 1.75;1.25,1;turtlebot_despawn;STOP]" ..
			"button_exit[-0.2.25,3.75;1.25,1;turtlebot_cancel;CANCEL]";
	end

	meta:set_string("formspec",form)
	return form
end

on_receive_robot_form = function(pos, formname, fields, sender)
	
	local name = sender:get_player_name();
	if minetest.is_protected(pos, name) then return end
	
	local save = function ()
		local meta = minetest.get_meta(pos);
		
		if fields.turtlebot_code then 
			local code = fields.turtlebot_code or "";
			if string.len(code) > 64000 then 
				minetest.chat_send_all("#ROBOT: " .. name .. " is spamming with long text.") return 
			end
			meta:set_string("code", code)
		end
	end

	if fields.turtlebot_save then
		save()
	elseif fields.turtlebot_spawn then
		save()
		activate(pos);
	elseif fields.turtlebot_despawn then
		save()
		deactivate(pos)
	end

	update_form(pos);
end

minetest.register_node("turtlebot:spawner", {
	description = "Spawns turtlebot",
	tiles = {"cpu.png"},
	groups = {cracky=3, mesecon_effector_on = 1},
	drawtype = "allfaces",
	paramtype = "light",
	param1 = 1,
	walkable = true,
	alpha = 150,

	after_place_node = function(pos, placer)
		local meta = minetest.env:get_meta(pos)

    local owner = placer:get_player_name();
		meta:set_string("owner", owner); 
		meta:set_string("code","");
		meta:set_string("infotext", "robot spawner (owned by ".. placer:get_player_name() .. ")")
		meta:set_string("libpos", posToString(pos))
		
		update_form(pos);
	end,

	mesecons = {
    effector = {
      action_on = activate, 
      action_off = deactivate
		}
	},
	
	on_receive_fields = on_receive_robot_form,
	
  can_dig = function(pos, player)
		return not isActive(pos)
	end
	
})

minetest.register_craft({
	output = "turtlebot:spawner",
	recipe = {
		{"default:mese_crystal", "default:mese_crystal","default:mese_crystal"},
		{"default:mese_crystal", "default:mese_crystal","default:mese_crystal"},
		{"default:stone", "default:steel_ingot", "default:stone"}
	}
})
