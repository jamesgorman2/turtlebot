
local spawn_robot

function posToString(pos)
  return tostring(pos.x) .. " " .. tostring(pos.y) .. " " .. tostring(pos.z)
end

function stringToPos(s)
  local words = {}; for word in string.gmatch(s,"%S+") do words[#words+1]=word end
  return {
    x = tonumber(words[1] or spos.x),
    y = tonumber(words[2] or spos.y),
    z = tonumber(words[3] or spos.z)
  };
end
 
turtlebot = {
  data = {},
  get = function(pos)
    local spos = posToString(pos)
    return turtlebot.data[spos]
  end,
  isActive = function(pos) 
    local spos = posToString(pos)
    return turtlebot.data[spos] and turtlebot.data[spos].obj
  end,
  activate = function(pos)
    local spos = posToString(pos)
    turtlebot.data[spos] = spawn_robot(pos) 
  end,
  deactivate = function(pos)
    local spos = posToString(pos)
    local data = turtlebot.data[spos]
		if data and data.obj then
			data.obj:remove();
      data.obj = nil;
		end 
  end,
  getId = function()
    local id = turtlebot.nextId
    turtlebot.nextId = id + 1
    return id
  end,
  maxoperations = 50,
  gui = {},
  nextId = 1
}

-- dofile(minetest.get_modpath("turtlebot").."/robogui.lua") -- gui stuff
-- dofile(minetest.get_modpath("turtlebot").."/commands.lua")

package.path = minetest.get_modpath("turtlebot") .. "/?.lua;" .. package.path
package.loaded.moonscript = require("moon-bundle")

local moonscript = require("moonscript.base")
local parseMoonscript = require("moonscript.parse")
local compileMoonscript = require("moonscript.compile")

local CompileMoonscriptToLua, check_code, preprocess_code, is_inside_string;

function CompileMoonscriptToLua(script)
	tree, err, pos = parseMoonscript.string(script)
	if not tree then return nil, '[moonscript parser] '..err end
	lua_code, err, lineNo, lineStr = compileMoonscript.tree(tree)
	if not lua_code then return nil, '[moonscript compiler] '..err end
	f, err = loadstring("local tostring = _G.tostring; "..lua_code)
	if err then return nil, '[lua parser] '..err end
	return f, nil
end

local function CompileCode (script)
	local ScriptFunc, CompileError = CompileMoonscriptToLua(script)
	if CompileError then
    return nil, CompileError
  end
	return ScriptFunc, nil
end


dofile(minetest.get_modpath("turtlebot").."/spawner.lua")
dofile(minetest.get_modpath("turtlebot").."/robot.lua")

spawn_robot = function(pos)

  local meta = minetest.get_meta(pos);
  local owner = meta:get_string("owner")
  local robotPos = { x = pos.x, y = pos.y + 1, z = pos.z } -- spawn robot on top of spawner

  local createData = function()
    minetest.debug("createData ")
    local data = turtlebot.get(pos)
    if data then
      return data
    end
    return {}
  end 

  local createObj = function()
    minetest.debug("createObj ")
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
    luaent.code = meta:get_string("code")
    luaent.spawnpos = pos
    
    return obj
  end

  local compileBytecode = function()
    local script = meta:get_string("code")
    -- script = preprocess_code(script)
    return CompileCode(script)
  end

  local data = createData()
 
  if data.obj then 
    minetest.chat_send_player(owner, "#Trying to spawn active turtlebot")
    return 
  end

  data.obj = createObj()
  data.owner = owner;
  data.spawnpos = pos
  
  if not data.sandbox then
    --data.sandbox = getSandboxEnv(pos)
  end

  local self = data.obj:get_luaentity()
  --local bytecode, err = setCode(pos, self.code) -- compile code
	if err then
		minetest.chat_send_player(owner, "#ROBOT CODE COMPILATION ERROR : " .. err) 
		self.running = 0 -- stop execution
		turtlebot.deactivate(pos)
		return
  end

  data.bytecode = bytecode
  self.running = 1

  return data
end