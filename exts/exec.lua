commands = {
	{ 
		command = "execw",
		description = i18n("execw_desc", {default = "Execute Lua command in a widget"}),
		cheat = false,
		exec = function(command, cmdParts)
			local commandPart = cmdParts[1]
			local x = command:lower():find(commandPart)
			local luaCommandStr = command:sub(x + #commandPart):trimLeft()
			ExecuteCommand(luaCommandStr)
		end
-- 		suggestions = function(cmd, cmdParts)
-- 			local suggestions = {}
-- 			local param = cmdParts[2]
-- 			for index, rule in pairs(Spring.GetGameRulesParams()) do
-- 				if type(rule) == "table" then
-- 					for name, value in pairs(rule) do
-- 						if param == nil or param == "" or name:starts(param) then
-- 							table.insert(suggestions, { command = "/gamerules " .. name, text = name, description = value })
-- 						end
-- 					end
-- 				end
-- 			end
-- 			return suggestions
-- 		end,
	},
	{ 
		command = "execs",
		description = i18n("execs_desc", {default = "Execute Lua command in a synced gadget"}),
		cheat = true,
		exec = function(command, cmdParts)
			local commandPart = cmdParts[1]
			local x = command:lower():find(commandPart)
			local luaCommandStr = command:sub(x + #commandPart):trimLeft()
			Spring.Echo("TODO: SYNCED!")
			ExecuteCommand(luaCommandStr)
		end,
	},
	{ 
		command = "execu",
		description = i18n("execu_desc", {default = "Execute Lua command in an unsynced gadget"}),
		cheat = false,
		exec = function(command, cmdParts)
			local commandPart = cmdParts[1]
			local x = command:lower():find(commandPart)
			local luaCommandStr = command:sub(x + #commandPart):trimLeft()
			Spring.Echo("TODO: UNSYNCED!")
			ExecuteCommand(luaCommandStr)
		end,
	},
	{ 
		command = "execgl",
		description = i18n("execgl_desc", {default = "Execute Lua command in a widget OpenGL callin"}),
		cheat = false,
		exec = function(command, cmdParts)
			local commandPart = cmdParts[1]
			local x = command:lower():find(commandPart)
			local luaCommandStr = command:sub(x + #commandPart):trimLeft()
			delayGL = function() ExecuteCommand(luaCommandStr) end
		end,
	},
}