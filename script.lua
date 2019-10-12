package.path = modPath .. "/?.lua;".. package.path

package.loaded.moonscript = require("moon-bundle")

local moonscript = require("moonscript.base")
local parseMoonscript = require("moonscript.parse")
local compileMoonscript = require("moonscript.compile")

local CompileMoonscriptToLua, check_code, preprocess_code, is_inside_string;

local pcall = pcall

function CompileMoonscriptToLua(script, debugname)
	-- local tree, err = parseMoonscript.string(script)
	-- if not tree then return nil, '[moonscript parser] '..err end
	-- local lua_code, err, lineNo, lineStr = compileMoonscript.tree(tree)
  -- if not lua_code then return nil, '[moonscript compiler at '..tostring(lineNo)'] '..err end
	local f, err = moonscript.loadstring(string.gsub(script, "[\n\r]+", "\n")) -- load(lua_code, debugname)
	if err then return nil, '[lua parser] '..err end
	return f, nil
end

function CompileCode(script, debugname)
	local scriptFunc, compileError = CompileMoonscriptToLua(script, debugname)
	if compileError then
    return nil, compileError
  end
	return scriptFunc, nil
end

function RunScript(script, environment, debugname)
  local scriptFunc, compileError = CompileCode(script, debugname)
  if compileError then
    return nil, compileError
  end
  if environment ~= nil then
    setfenv(scriptFunc, environment)
  end
  local success, rValue = pcall(scriptFunc)
  if success then
    return rValue, nil
  else
    return nil, rValue
  end
end

function LoadScript(path)
  local file, err = io.open(path)
  if not file then return nil, err end
  local code = assert(file:read("*a"))
  file:close()
  return code
end
