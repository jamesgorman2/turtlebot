spawn_robot = function(pos)

  local meta = minetest.get_meta(pos);
  local owner = meta:get_string("owner")
  local robotPos = { x = pos.x, y = pos.y + 1, z = pos.z } -- spawn robot on top of spawner
	local code = meta:get_string("code")

  local createData = function()
    local data = turtlebot.get(pos)
    if data then
      return data
    end
    return {}
  end 

  local createObj = function()
    local name = "Turtlebot " .. tostring(turtlebot.getId())
    local obj = minetest.add_entity(robotPos, "turtlebot:robot");
    obj:set_properties({infotext = name})
    obj:set_properties({
      nametag = 
        "[" .. name .. ", created by " .. owner .. 
        " at " .. tostring(pos.x) .. ", " .. tostring(pos.y) .. ", " .. pos.z .. "]",
      nametag_color = "LawnGreen"
    })
    obj:set_armor_groups({fleshy=0})

    local luaent = obj:get_luaentity()
    luaent.owner = owner
    luaent.name = name
    luaent.code = code
    luaent.spawnpos = pos
    
    return obj
  end

  local data = createData()
 
  if data.obj then 
    minetest.chat_send_player(owner, "#Trying to spawn active turtlebot")
    return 
  end

  data.obj = createObj()
  data.owner = owner;
  data.spawnpos = pos
  
  local self = data.obj:get_luaentity()

	self.env = turtlebot.getSandboxEnv(pos)

	local turtle, err = RunScript(code, self.env, data.obj.name)
	if err then
		minetest.chat_send_player(owner, "#TURTLEBOT CODE COMPILATION ERROR : " .. err) 
		self.running = 0 -- stop execution
		self.object:remove()
		turtlebot.deactivate(pos)
		return
	end

	if not turtle or not turtle.__class or turtle.__class.__name ~= "Turtlebot" then
		minetest.chat_send_player(owner, "#TURTLEBOT ERROR : no Turtlebot returned") 
		self.running = 0 -- stop execution
		self.object:remove()
		turtlebot.deactivate(pos)
		return
	end

	data.turtle = turtle

  self.running = 1

  return data
end

minetest.register_entity("turtlebot:robot", {
	owner = "",
	name = "",
	hp_max = 100,
	itemstring = "robot",
	code = "",
	timer = 0,
	timestep = 0.1, -- run every 1 second
	spawnpos = nil,
	
	visual="cube",
	textures={"topface.png","legs.png","left-hand.png","right-hand.png","face.png","face-back.png"},
	
	visual_size={x=1,y=1},
	running = 0, -- does it run code or is it idle?	
	collisionbox = {-0.5,-0.5,-0.5, 0.5,0.5,0.5},
	physical = true,
    
  ----------
	on_activate = function(self, staticdata)
		
		-- reactivate robot
		if staticdata ~= "" then 
			local data = turtlebot.data[staticdata]
			
			if not data or not data.obj or data.obj ~= self then
				minetest.chat_send_player(self.owner, "#ROBOT INIT:  error. spawn robot again.")
				self.object:remove()
				return;
			end
		end		
	end,
	
	get_staticdata = function(self)
		local d
		if self.spawnpos then
			d = posToString(self.spawnpos)
		else 
			d = self.name
		end
		return d;
	end,
	
	on_punch = function (self, puncher, time_from_last_punch, tool_capabilities, dir)
	end,
	
	on_step = function(self, dtime)
		self.timer = self.timer + dtime
		if self.timer > self.timestep and self.running == 1 then
			self.timer = 0
			local data = turtlebot.get(self.spawnpos)
			local o, nextT = data.turtle:next()

			if o ~= nil then
				local f = function()
					return o:exec(nextT)
				end

				setfenv(f, self.env)
				local success, t =  pcall(f)
				
				if not success then
					if owner then
						minetest.chat_send_player(owner, "#TURTLEBOT ERROR : " .. tostring(t))
					else
						minetest.chat_send_all("#TURTLEBOT ERROR : " .. tostring(t))
					end
				elseif t ~= nil then
					data.turtle = t
				else
					minetest.debug("on_step", "nil next stream")
				end
			end

			if nextT:complete() then
				self.running = 0
				self.object:remove()
				turtlebot.deactivate(self.spawnpos)
			end
		end
	end,

	on_rightclick = function(self, clicker)
		local text = minetest.formspec_escape(self.code);
		local form = update_form(self.spawnpos, 1);
		if not form then
			form = "size[9.5,8]" ..  -- width, height
			"textarea[1.25,-0.25;8.75,9.8;turtlebot_code;;]"..
			"button_exit[-0.2, 1.75;1.25,1;turtlebot_despawn_me;STOP]" ..
			"button_exit[-0.2.25,3.75;1.25,1;turtlebot_cancel;CANCEL]"

		end
		minetest.show_formspec(
			clicker:get_player_name(),
			"robot_worker_" .. posToString(self.spawnpos),
			form
		)
	end,
})

minetest.register_on_player_receive_fields(
	function(player, formname, fields)
		
		local robot_formname = "robot_worker_"
		if string.find(formname,robot_formname) then
			local spos = string.sub(formname, string.len(robot_formname)+1) -- robot name
			local sender = player:get_player_name() --minetest.get_player_by_name(name);
			
			if turtlebot.data[spos] then
				local pos = turtlebot.data[spos].spawnpos
				on_receive_robot_form(pos, formname, fields, player)				
			end
		end
	end
)