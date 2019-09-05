
function getSandboxEnv(name)

  local commands = turtlebot.commands;
  
	local directions = {
    left = 1, right = 2, forward = 3, backward = 4, up = 5, down = 6, 
		left_down = 7, right_down = 8, forward_down = 9, backward_down = 10,
		left_up = 11, right_up = 12, forward_up = 13,  backward_up = 14
	}
	
  if not turtlebot.data[name].rom then turtlebot.data[name].rom = {} end -- create rom if not yet existing
  
	local env = 
	{
		pcall = pcall,
		robot_version = function() return turtlebot.version end,
		
		turn = {
			left = function() commands.turn(name, math.pi/2) end,
			right = function() commands.turn(name, -math.pi/2) end,
			angle = function(angle) commands.turn(name, angle*math.pi/180) end,
		},
		
		pickup = function(r) -- pick up items around robot
			return commands.pickup(r, name);
		end,
		
		self = {
			pos = function() return turtlebot.data[name].obj:getpos() end,
			spawnpos = function() local pos = turtlebot.data[name].spawnpos; return {x=pos.x,y=pos.y,z=pos.z} end,
			name = function() return name end,
			operations = function() return turtlebot.data[name].operations end,
			viewdir = function() local yaw = turtlebot.data[name].obj:getyaw(); return {x=math.cos(yaw), y = 0, z=math.sin(yaw)} end,
			
			set_properties = function(properties)
				if not properties then return end; local obj = turtlebot.data[name].obj;
				obj:set_properties(properties);
			end,
			
			set_animation = function(anim_start,anim_end,anim_speed,anim_stand_start)
				local obj = turtlebot.data[name].obj;
				obj:set_animation({x=anim_start,y=anim_end}, anim_speed, anim_stand_start)
			end,
			
			remove = function()
				error("abort")
				turtlebot.data[name].obj:remove();
				turtlebot.data[name].obj=nil;
			end,
			
			reset = function()
				local pos = turtlebot.data[name].spawnpos; 
				local obj = turtlebot.data[name].obj;
				obj:setpos({x=pos.x,y=pos.y+1,z=pos.z}); obj:setyaw(0);
			end,
			
			label = function(text)
				local obj = turtlebot.data[name].obj;
				obj:set_properties({nametag = text or ""}); -- "[" .. name .. "] " .. 
			end,
			
			display_text = function(text,linesize,size)
				local obj = turtlebot.data[name].obj;
				return commands.display_text(obj,text,linesize,size)
			end,
			
		},
		
		find_nodes = 
			function(nodename,r) 
				if r>8 then return false end
				local q = minetest.find_node_near(turtlebot.data[name].obj:getpos(), r, nodename);
				if q==nil then return false end
				local p = turtlebot.data[name].obj:getpos()
				return math.sqrt((p.x-q.x)^2+(p.y-q.y)^2+(p.z-q.z)^2)
			end, -- in radius around position
		
		find_player = 
			function(r,pos) 
				pos = pos or turtlebot.data[name].obj:getpos();
				if r>10 then return false end
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
			if not turtlebot.data[name].quiet_mode and not pname then
				minetest.chat_send_all("<robot ".. name .. "> " .. text)
				if not turtlebot.data[name].allow_spam then 
					turtlebot.data[name].quiet_mode=true
				end
			else
				if not pname then pname = turtlebot.data[name].owner end
				minetest.chat_send_player(pname,"<robot ".. name .. "> " .. text) -- send chat only to player pname
			end
		end,
			
		rom = turtlebot.data[name].rom,
		
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
	};
	
	-- ROBOT FUNCTIONS: move,dig, place,insert,take,check_inventory,activate,read_node,read_text,write_text
	
	env.move = {}; -- changes position of robot
	for dir, dir_id in pairs(directions) do
		env.move[dir]  =  function() return commands.move(name,dir_id) end
	end
	
	env.dig = {};
	for dir, dir_id in pairs(directions) do
		env.dig[dir]  =  function() return commands.dig(name,dir_id) end
	end
	
	env.place = {};
	for dir, dir_id in pairs(directions) do
		env.place[dir] = function(nodename, param2) return commands.place(name,nodename, param2, dir_id) end
	end
	
	env.insert = {}; -- insert item from robot inventory into another inventory
	for dir, dir_id in pairs(directions) do
		env.insert[dir] = function(item, inventory) return commands.insert_item(name,item, inventory,dir_id) end
	end

	env.take = {}; -- takes item from inventory and puts it in robot inventory
	for dir, dir_id in pairs(directions) do
		env.take[dir] = function(item, inventory) return commands.take_item(name,item, inventory,dir_id) end
	end
	
	env.check_inventory = {};
	for dir, dir_id in pairs(directions) do
		env.check_inventory[dir] = function(itemname, inventory,i) return commands.check_inventory(name,itemname, inventory,i,dir_id) end
	end
	env.check_inventory.self = function(itemname, inventory,i) return commands.check_inventory(name,itemname, inventory,i,0) end;
	
	env.activate = {};
	for dir, dir_id in pairs(directions) do
		env.activate[dir] = function(mode) return commands.activate(name,mode, dir_id) end
	end
	
	env.read_node = {};
	for dir, dir_id in pairs(directions) do
		env.read_node[dir] = function() return commands.read_node(name,dir_id) end
	end
	
	env.read_text = {} -- returns text
	for dir, dir_id in pairs(directions) do
		env.read_text[dir] = function(stringname,mode) return commands.read_text(name,mode,dir_id,stringname) end
	end
	
	env.write_text = {} -- returns text
	for dir, dir_id in pairs(directions) do
		env.write_text[dir] = function(text) return commands.write_text(name, dir_id,text) end
	end
			
	if authlevel>=1 then -- robot privs
	
		env.self.sound = minetest.sound_play
		env.self.sound_stop = minetest.sound_stop
	
		env.table = {
			concat = table.concat,
			insert = table.insert,
			maxn = table.maxn,
			remove = table.remove,
			sort = table.sort,
		}
		
		env.code.run = function(script)
			if turtlebot.data[name].authlevel < 3 then
				local err = check_code(script);
				script = preprocess_code(script, turtlebot.call_limit[turtlebot.data[name].authlevel+1]);
				if err then 
					minetest.chat_send_player(name,"#ROBOT CODE CHECK ERROR : " .. err) 
					return 
				end
			end
			
			local ScriptFunc, CompileError = CompileMoonscriptToLua( script )
			if CompileError then
				minetest.chat_send_player(name, "#code.run: compile error " .. CompileError )
				return false
			end
		
			setfenv( ScriptFunc, turtlebot.data[name].sandbox )
		
			local Result, RuntimeError = pcall( ScriptFunc );
			if RuntimeError then
				minetest.chat_send_player(name, "#code.run: run error " .. RuntimeError )
				return false
			end
			return true
		end
		
		env.self.read_form = function()
			local fields = turtlebot.data[name].read_form;
			local sender = turtlebot.data[name].form_sender;
			turtlebot.data[name].read_form = nil; 
			turtlebot.data[name].form_sender = nil; 
			return sender,fields
		end
			
		env.self.show_form = function(playername, form)
			commands.show_form(name, playername, form)
		end
	end
	
	-- set up sandbox for puzzle
		
	if authlevel>=2 then -- puzzle privs
		turtlebot.data[name].puzzle = {};
		local data = turtlebot.data[name];
		local pdata = data.puzzle;
		pdata.triggerdata = {};
		pdata.gamedata = {};
		pdata.block_ids = {}
		pdata.triggers = {};
		env.puzzle = { -- puzzle functionality
			set_node = function(pos,node) commands.puzzle.set_node(data,pos,node) end,
			get_node = function(pos) return minetest.get_node(pos) end,
			activate = function(mode,pos) commands.puzzle.activate(data,mode,pos) end,
			get_meta = function(pos) return commands.puzzle.get_meta(data,pos) end,
			get_gametime = function() return minetest.get_gametime() end,
			get_node_inv = function(pos) return commands.puzzle.get_node_inv(data,pos) end,
			get_player = function(pname) return commands.puzzle.get_player(data,pname) end,
			chat_send_player = function(pname, text)	minetest.chat_send_player(pname or "", text)	end,
			get_player_inv = function(pname) return commands.puzzle.get_player_inv(data,pname) end,
			set_triggers = function(triggers) commands.puzzle.set_triggers(pdata,triggers) end, -- FIX THIS!
			check_triggers = function(pname) 
				local player = minetest.get_player_by_name(pname); if not player then return end
				commands.puzzle.checkpos(pdata,player:getpos(),pname) 
			end,
			add_particle = function(def) minetest.add_particle(def) end,
			count_objects = function(pos,radius) return #minetest.get_objects_inside_radius(pos, math.min(radius,5)) end,
			pdata = pdata,
			ItemStack = ItemStack,
		}
		
	end

	--special sandbox for admin
	if authlevel<3 then -- is admin?
		env._G = env;
	else
		env.minetest = minetest;
		env._G =_G;
		debug = debug;
	end
	
	return env	
end