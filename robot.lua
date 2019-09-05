
minetest.register_entity("turtlebot:robot",{
	operations = turtlebot.maxoperations, 
	owner = "",
	name = "",
	hp_max = 100,
	itemstring = "robot",
	code = "",
	timer = 0,
	timestep = 1, -- run every 1 second
	spawnpos = nil,
	
	visual="cube",
	textures={"topface.png","legs.png","left-hand.png","right-hand.png","face.png","face-back.png"},
	
	visual_size={x=1,y=1},
	running = 0, -- does it run code or is it idle?	
	collisionbox = {-0.5,-0.5,-0.5, 0.5,0.5,0.5},
	physical=true,
    
  ----------
	on_activate = function(self, staticdata)
		
		-- reactivate robot
		if staticdata ~= "" then 
			local data = turtlebot.data[staticdata];
			
			if not data or not data.obj or data.obj ~= self then
				minetest.chat_send_all("#ROBOT INIT:  error. spawn robot again.")
				self.object:remove(); 
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
	
	-- on_step = function(self, dtime)
		
	-- 	self.timer=self.timer+dtime
	-- 	if self.timer>self.timestep and self.running == 1 then 
	-- 		self.timer = 0;
	-- 		local err = runSandbox(self.name);
	-- 		if err and type(err) == "string" then 
	-- 			local i = string.find(err,":");
	-- 			if i then err = string.sub(err,i+1) end
	-- 			-- recreate dead coroutine, does this have some side effects like memory leak?
	-- 			if err == "cannot resume dead coroutine" then 
	-- 				local data = basic_robot.data[self.name]
	-- 				data.cor = coroutine.create(data.bytecode)
	-- 				err = runSandbox(self.name)
	-- 				if not err then return end
	-- 			end
				
	-- 			if string.sub(err,-5)~="abort" and not cor then
	-- 				minetest.chat_send_player(self.owner,"#ROBOT ERROR : " .. err) 
	-- 			end
				
	-- 			self.running = 0; -- stop execution
				
	-- 			if string.find(err,"stack overflow") then
	-- 				local name = self.name;
	-- 				local pos = basic_robot.data[name].spawnpos;
	-- 				minetest.set_node(pos, {name = "air"});
	-- 				--local privs = core.get_player_privs(self.owner);privs.interact = false; 
	-- 				--core.set_player_privs(self.owner, privs); minetest.auth_reload()
	-- 				minetest.kick_player(self.owner, "#basic_robot: stack overflow")
	-- 			end
				
	-- 			local name = self.name;
	-- 			local pos = basic_robot.data[name].spawnpos;
			
	-- 			if not basic_robot.data[name] then return end
	-- 			if basic_robot.data[name].obj then
	-- 				basic_robot.data[name].obj = nil;
	-- 			end
				
	-- 			self.object:remove();
	-- 		end
	-- 		return 
	-- 	end
		
	-- 	return
	-- end,

	on_rightclick = function(self, clicker)
		local text = minetest.formspec_escape(self.code);
		local form = update_form(self.spawnpos, 1);
		if not form then
			form = "size[9.5,8]" ..  -- width, height
			"textarea[1.25,-0.25;8.75,9.8;turtlebot_code;;]"..
			"button_exit[-0.2, 1.75;1.25,1;turtlebot_despawn_me;STOP]" ..
			"button_exit[-0.2.25,3.75;1.25,1;turtlebot_cancel;CANCEL]";

		end
		minetest.show_formspec(
			clicker:get_player_name(),
			"robot_worker_" .. posToString(self.spawnpos),
			form
		);
	end,
})

minetest.register_on_player_receive_fields(
	function(player, formname, fields)
		
		local robot_formname = "robot_worker_";
		if string.find(formname,robot_formname) then
			local spos = string.sub(formname, string.len(robot_formname)+1); -- robot name
			local sender = player:get_player_name(); --minetest.get_player_by_name(name);
			
			if turtlebot.data[spos] then
				local pos = turtlebot.data[spos].spawnpos;				
				on_receive_robot_form(pos, formname, fields, player)				
			end
		end
	end
)