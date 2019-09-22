

function DumpTable(table)
  if type(table) ~= "table" then
    return tostring(table)
  end
  local s = "{"
  for i, v in pairs(table) do
    s = s .. i .. "=" .. DumpTable(v) .. " "
  end
  return s.."}"
end

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
  nextId = 1
}

modPath = minetest.get_modpath("turtlebot")

dofile(modPath.."/script.lua")
RunScript(LoadScript(modPath.."/operations.moon"), nil, "operations.moon")
RunScript(LoadScript(modPath.."/turtlebot.moon"), nil, "turtlebot.moon")

dofile(modPath.."/commands.lua")
dofile(modPath.."/sandbox.lua")
dofile(modPath.."/spawner.lua")
dofile(modPath.."/robot.lua")
