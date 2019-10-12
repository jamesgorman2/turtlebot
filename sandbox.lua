
turtlebot.getSandboxEnv = function(spawnPos)

  local commands = turtlebot.commands;
  
	local directions = turtlebot.directions
 
	local env = 
	{
		pcall = pcall,
		
		Turtlebot = Turtlebot,
		Operation = Operation,
		OperationStream = OperationStream,

		turn = {
			left = Operation.of(function() commands.turn(name, math.pi/2) end),
			right = Operation.of(function() commands.turn(name, -math.pi/2) end),
			angle = function(angle) 
				return Operation.of(function() commands.turn(name, angle*math.pi/180) end)
			end,
		},
		
		autoDig = function(b)
			return Operation(
				function(t)
					return t:setAutoDig(b)
				end
			)
		end,

		autoBuild = function(b)
			return Operation(
				function(t)
					return t:setAutoBuild(b)
				end
			)
		end,

		material = function(m)
			return Operation(
				function(t)
					return t:setMaterial(m)
				end
			)
		end,

		direction = {
			North = 0,
			South = 180,
			East = 90,
			West = 270
		},

		self = {
			pos = function() return turtlebot.get(spawnPos).obj:getpos() end,
			spawnpos = spawnPos,
			name = function() return name end,
			operations = function() return turtlebot.get(spawnPos).operations end,
			facing = function() local yaw = turtlebot.get(spawnPos).obj:getyaw(); return {x=math.cos(yaw), y = 0, z=math.sin(yaw)} end,
			
			set_properties = function(properties)
				if not properties then return end; 
				local obj = turtlebot.get(spawnPos).obj;
				obj:set_properties(properties);
			end,
			
			set_animation = function(anim_start,anim_end,anim_speed,anim_stand_start)
				local obj = turtlebot.get(spawnPos).obj;
				obj:set_animation({x=anim_start,y=anim_end}, anim_speed, anim_stand_start)
			end,
			
			remove = function()
				turtlebot.deactivate(spawnPos)
			end,
			
			reset = function()
				local pos = turtlebot.get(spawnPos).spawnpos; 
				local obj = turtlebot.get(spawnPos).obj;
				obj:setpos({x=pos.x,y=pos.y+1,z=pos.z}); obj:setyaw(0);
			end,
			
			label = function(text)
				local obj = turtlebot.get(spawnPos).obj;
				obj:set_properties({nametag = text or ""}); -- "[" .. name .. "] " .. 
			end,
			
			display_text = function(text,linesize,size)
				local obj = turtlebot.get(spawnPos).obj;
				return commands.display_text(obj,text,linesize,size)
			end,
			
		},
		
		find_nodes = 
			function(nodename,r) 
				if r>8 then return false end
				local q = minetest.find_node_near(turtlebot.get(spawnPos).obj:getpos(), r, nodename);
				if q==nil then return false end
				local p = turtlebot.get(spawnPos).obj:getpos()
				return math.sqrt((p.x-q.x)^2+(p.y-q.y)^2+(p.z-q.z)^2)
			end, -- in radius around position
		
		find_player = 
			function(r, pos) 
				pos = pos or turtlebot.get(spawnPos).obj:getpos();
				if r > 10 then return false end
				local objects =  minetest.get_objects_inside_radius(pos, r);
				local plist = {};
				for _,obj in pairs(objects) do
					if obj:is_player() then 
						plist[#plist+1]=obj:get_player_name();
					end
				end
				if not plist[1] then return nil end
				return plist
			end, -- in radius around position
		
		player = {
			getpos = function(name) 
				local player = minetest.get_player_by_name(name); 
				if player then return player:getpos() else return nil end 
			end,
			
			connected = function()
				local players =  minetest.get_connected_players();
				local plist = {}
				for _,player in pairs(players) do
					plist[#plist+1]=player:get_player_name()
				end
				if not plist[1] then return nil else return plist end
			end
		},

    say = function(text, pname)
			if not turtlebot.get(spawnPos).quiet_mode and not pname then
				minetest.chat_send_all("<robot ".. turtlebot.get(spawnPos).name .. "> " .. text)
				if not turtlebot.get(spawnPos).allow_spam then 
					turtlebot.get(spawnPos).quiet_mode=true
				end
			else
				if not pname then pname = turtlebot.get(spawnPos).owner end
				minetest.chat_send_player(pname, "<robot ".. turtlebot.get(spawnPos).name .. "> " .. text) -- send chat only to player pname
			end
		end,
		
		string = {
      byte = string.byte,
      char = string.char,
			find = string.find,
			gsub = string.gsub,
			gmatch = string.gmatch,
      len = string.len, 
      lower = string.lower,
      upper = string.upper, 
      rep = string.rep,
      reverse = string.reverse, 
      sub = string.sub,
			
			format = function(...)
				local out = string.format(...)
				if string.len(out) > 1024 then
					error("result string longer than 1024")
					return
				end
				return out				
			end,
			concat = function(strings, sep)
				local length = 0;
				for i = 1,#strings do
					length = length + string.len(strings[i])
					if length > 1024 then 
						error("result string longer than 1024")
						return
					end
				end
				return table.concat(strings,sep or "") 
			end,
    },
    
		math = {
			abs = math.abs,	acos = math.acos,
			asin = math.asin, atan = math.atan,
			atan2 = math.atan2,	ceil = math.ceil,
			cos = math.cos,	cosh = math.cosh,
			deg = math.deg,	exp = math.exp,
			floor = math.floor,	fmod = math.fmod,
			frexp = math.frexp,	huge = math.huge,
			ldexp = math.ldexp,	log = math.log,
			log10 = math.log10,	max = math.max,
			min = math.min,	modf = math.modf,
			pi = math.pi, pow = math.pow,
			rad = math.rad,	random = math.random,
			sin = math.sin,	sinh = math.sinh,
			sqrt = math.sqrt, tan = math.tan,
			tanh = math.tanh,
		},
		os = {
			clock = os.clock,
			difftime = os.difftime,
			time = os.time,
			date = os.date,			
		},
		
		colorize = core.colorize,
		serialize = minetest.serialize,
		deserialize = minetest.deserialize,
		tonumber = tonumber, pairs = pairs,
		ipairs = ipairs, error = error, type=type,
		tostring = tostring
	};
	
	env.move = {}; -- changes position of robot
	for dir, dir_id in pairs(directions) do
		env.move[dir] = Operation(
			function(t)
				minetest.debug("sndmv", DumpTable(t))
				if t.autoDig then
					commands.dig(spawnPos, dir_id)
				end
				local moved = commands.move(spawnPos, dir_id) 
				if moved and t.autoBuild then
					local opposite_dir = turtlebot.opposite_direction[dir_id]
					commands.place(spawnPos, t.material, nil, opposite_dir)
				end
				return t
			end
		)
	end
	
	env.dig = {};
	for dir, dir_id in pairs(directions) do
		env.dig[dir] = Operation.of(function() commands.dig(spawnPos, dir_id) end)
	end
	
	env.place = {};
	for dir, dir_id in pairs(directions) do
		env.place[dir] = function(nodename, param2) 
			return Operation(
				function(t) 
					if nodename == nil then
						nodename = t.material
					end
					commands.place(spawnPos, nodename, param2, dir_id) 
					return t
				end
			) 
		end
	end
	
	env.read_node = {};
	for dir, dir_id in pairs(directions) do
		env.read_node[dir] = function() return commands.read_node(spawnPos, dir_id) end
	end
	
	env.self.sound = minetest.sound_play
	env.self.sound_stop = minetest.sound_stop

	env.table = {
		concat = table.concat,
		insert = table.insert,
		maxn = table.maxn,
		remove = table.remove,
		sort = table.sort,
	}

	env.minetest = minetest;
	env._G =_G;
	
	return env	
end