
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

local modPath = minetest.get_modpath("turtlebot")

package.path = modPath .. "/?.lua;".. package.path

package.loaded.moonscript = require("moon-bundle")

local moonscript = require("moonscript.base")
local parseMoonscript = require("moonscript.parse")
local compileMoonscript = require("moonscript.compile")

local CompileMoonscriptToLua, check_code, preprocess_code, is_inside_string;

function CompileMoonscriptToLua(script, debugname)
	local tree, err, pos = parseMoonscript.string(script)
	if not tree then return nil, '[moonscript parser] '..err end
	local lua_code, err, lineNo, lineStr = compileMoonscript.tree(tree)
  if not lua_code then return nil, '[moonscript compiler] '..err end
	local f, err = loadstring(lua_code, debugname)
	if err then return nil, '[lua parser] '..err end
	return f, nil
end

local function CompileCode(script, debugname)
	local scriptFunc, compileError = CompileMoonscriptToLua(script, debugname)
	if compileError then
    return nil, compileError
  end
	return scriptFunc, nil
end

local function RunScript(script, environment, debugname)
  local scriptFunc, compileError = CompileCode(script, debugname)
  if compileError then
    return nil, compileError
  end
  if environment ~= nil then
    setfenv(scriptFunc, environment)
  end
  local success, rValue = pcall(scriptFunc)
  minetest.debug("pcall", tostring(success), type(rValue), tostring(rValue))
  if type(rValue) == "table" then
    minetest.debug(#rValue)
  end
  if success then
    return rValue, nil
  else
    return nil, rValue
  end
end

local function LoadScript(path)
  local file, err = io.open(path)
  if not file then return nil, err end
  local code = assert(file:read("*a"))
  file:close()
  return code
end

RunScript(LoadScript(modPath.."/operations.moon"), nil, "operations.moon")
RunScript(LoadScript(modPath.."/turtlebot.moon"), nil, "turtlebot.moon")
dofile(modPath.."/spawner.lua")
dofile(modPath.."/robot.lua")

spawn_robot = function(pos)

  local meta = minetest.get_meta(pos);
  local owner = meta:get_string("owner")
  local robotPos = { x = pos.x, y = pos.y + 1, z = pos.z } -- spawn robot on top of spawner

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
  local bytecode, err = setCode(pos, self.code) -- compile code
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