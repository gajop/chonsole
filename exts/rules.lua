commands = {
	{ 
		command = "gamerules",
		description = "Sets values of specific gamerules variables",
		cheat = true,
		suggestions = function(cmd, cmdParts)
			local suggestions = {}
			local param = cmdParts[2]
			for index, rule in pairs(Spring.GetGameRulesParams()) do
				if type(rule) == "table" then
					for name, value in pairs(rule) do
						if param == nil or param == "" or name:starts(param) then
							table.insert(suggestions, { command = "/gamerules " .. name, text = name, description = value })
						end
					end
				end
			end
			return suggestions
		end,
		exec = function(command, cmdParts)
			if #cmdParts >= 3 then
				Spring.SendLuaRulesMsg('set_gamerule|' .. cmdParts[2] .. "|" .. cmdParts[3])
			end
		end
	},
	{ 
		command = "teamrules",
		description = "Sets values of specific teamrules variables",
		cheat = true,
		suggestions = function(cmd, cmdParts)
			local suggestions = {}
			local teamID = tonumber(cmdParts[2] or "")
			if teamID == nil then
				return suggestions
			end

			local param = cmdParts[3]
			for index, rule in pairs(Spring.GetTeamRulesParams(teamID)) do
				if type(rule) == "table" then
					for name, value in pairs(rule) do
						if param == nil or param == "" or name:starts(param) then
							table.insert(suggestions, { command = "/teamrules " .. name, text = name, description = value })
						end
					end
				end
			end
			return suggestions
		end,
		exec = function(command, cmdParts)
			if #cmdParts >= 4 then
				Spring.SendLuaRulesMsg('set_teamrule|' .. cmdParts[2] .. "|" .. cmdParts[3] .. "|" .. cmdParts[4])
			end
		end
	},
	{ 
		command = "unitrules",
		description = "Sets unitrules for the selected units",
		cheat = true,
		suggestions = function(cmd, cmdParts)
			local suggestions = {}
			local units = Spring.GetSelectedUnits()
			if #units == 0 then
				return suggestions
			end
			
			local unitrules = {}
			local different = {} -- mapping of unit rules that differ
			for i, unitID in pairs(units) do
				local rules = Spring.GetUnitRulesParams(unitID)
				for rule, value in pairs(rules) do
					if i == 0 then
						unitrules[rule] = value
					elseif unitrules[rule] ~= value then
						unitrules[rule] = value
						different[rule] = true
					end
				end
			end
			
			local param = cmdParts[3]
			for index, rule in pairs(Spring.GetUnitRulesParams(unitID)) do
				if type(rule) == "table" then
					for name, value in pairs(rule) do
						if param == nil or param == "" or name:starts(param) then
							table.insert(suggestions, { command = "/unitrules " .. name, text = name, description = value })
						end
					end
				end
			end
			return suggestions
		end,
		exec = function(command, cmdParts)
			if #cmdParts >= 3 then
				Spring.SendLuaRulesMsg('set_unitrule|' .. cmdParts[2] .. "|" .. cmdParts[3] .. "|" .. cmdParts[4])
			end
		end
	},
}