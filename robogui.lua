local turtlegui = turtlebot.gui;

-- GUI

-- turtlegui GUI START ==================================================
-- a simple table of entries: [guiName] =  {getForm = ... , show = ... , response = ... , guidata = ...}
turtlegui.register = function(def)
	turtlegui[def.guiName] = {
		getForm = def.getForm, 
		show = def.show, 
		response = def.response, 
		guidata = def.guidata or {}
  }
end
minetest.register_on_player_receive_fields(
	function(player, formname, fields)
		local gui = turtlegui[formname];
		if gui then gui.response(player,formname,fields) end
	end
)
-- turtlegui GUI END ====================================================


local help_address = {}; -- array containing current page name for player
local help_pages = {
	["main"] = { 
		"     === ROBOT HELP - MAIN SCREEN === ","",
		"[Commands reference] display list of robot commands",
		"[Lua basics] short introduction to lua","",
		"INSTRUCTIONS: double click links marked with []",
		"------------------------------------------","",
		"basic_robot version " .. basic_robot.version,
		"(c) 2016 rnd",
	},
}

for k,v in pairs(help_pages) do
	local pages = help_pages[k]; for i = 1,#pages do pages[i] = minetest.formspec_escape(pages[i]) end
end


local show_help = function(pname) --formname: help
	local address = help_address[pname] or "main";	
	
	--minetest.chat_send_all("D DISPLAY HELP for ".. address )
	local pages = help_pages[address];

	local content = table.concat(pages,",")
	local size = 9; local vsize = 8.75;

	local form = "size[" .. size .. "," .. size .. "] textlist[-0.25,-0.25;" .. (size+1) .. "," .. (vsize+1) .. ";wiki;".. content .. ";1]";
	--minetest.chat_send_all("D " .. form)
	minetest.show_formspec(pname, "help", form)
	return
end


turtlegui["help"] = {
	response = function(player,formname,fields)
		local name = player:get_player_name()

		local fsel = fields.wiki;
		if fsel and string.sub(fsel,1,3) == "DCL" then
			local sel = tonumber(string.sub(fsel,5)) or 1; -- selected line
			local address = help_address[name] or "main";
			local pages = help_pages[address];
						
			local link = string.match(pages[sel] or "", "\\%[([%w%s]+)\\%]")
			if help_pages[link] then 
				help_address[name] = link;
				show_help(name)
			end
		end
	end,
	
	getForm = function(player_name) end,
	
	show = show_help,
};
