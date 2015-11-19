function widget:GetInfo()
  return {
    name      = "Chonsole",
    desc      = "Chili Console",
    author    = "gajop",
    date      = "in the future",
    license   = "GPL-v2",
    layer     = 0,
    enabled   = true,
  }
end

-- constants
local grey = { 0.7, 0.7, 0.7, 1 }
local white = { 1, 1, 1, 1 }
local blue = { 0, 0, 1, 1 }
local teal = { 0, 1, 1, 1 }
local red =  { 1, 0, 0, 1 }
local green = { 0, 1, 0, 1 }
local yellow = { 1, 1, 0, 1 }

-- Config
local consoleX, consoleY = 0.26, 0.25
local consoleWidth = 0.5
local suggestionsHeight = 0.4
local suggesitonFontSize = 16
local suggesitonPadding = 4
local pageUpFactor = 10
local pageDownFactor = 10
local selectedSuggestionColor = { 0, 1, 1, 0.4 }
local subsuggestionColor = { 0, 0, 0, 0 }
local fontFile = "LuaUI/fonts/dejavu-sans-mono/DejaVuSansMono.ttf"

-- Lobby chat
local consoles = {} -- ID -> name mapping

local function explode(div,str)
	if (div=='') then return 
		false 
	end
	local pos,arr = 0,{}
	-- for each divider found
	for st,sp in function() return string.find(str,div,pos,true) end do
		table.insert(arr,string.sub(str,pos,st-1)) -- Attach chars left of current divider
		pos = sp + 1 -- Jump past current divider
	end
	table.insert(arr,string.sub(str,pos)) -- Attach chars right of last divider
	return arr
end

local cmdConfig = {
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
	{ 
		command = "execw",
		description = "Execute Lua command in a widget",
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
		description = "Execute Lua command in a synced gadget",
		cheat = true,
		exec = function(command, cmdParts)
			local commandPart = cmdParts[1]
			local x = command:lower():find(commandPart)
			local luaCommandStr = command:sub(x + #commandPart):trimLeft()
			Spring.Echo("SYNCED!")
			ExecuteCommand(luaCommandStr)
		end,
	},
	{ 
		command = "execu",
		description = "Execute Lua command in an unsynced gadget",
		cheat = false,
		exec = function(command, cmdParts)
			local commandPart = cmdParts[1]
			local x = command:lower():find(commandPart)
			local luaCommandStr = command:sub(x + #commandPart):trimLeft()
			Spring.Echo("UNSYNCED!")
			ExecuteCommand(luaCommandStr)
		end,
	},
	{ 
		command = "execgl",
		description = "Execute Lua command in a widget OpenGL callin",
		cheat = false,
		exec = function(command, cmdParts)
			local commandPart = cmdParts[1]
			local x = command:lower():find(commandPart)
			local luaCommandStr = command:sub(x + #commandPart):trimLeft()
			delayGL = function() ExecuteCommand(luaCommandStr) end
		end,
	},
	{
		command = "autocheat",
		description = "Provides automatic /cheat for commands that need it.",
		exec = function(command, cmdParts)
			autoCheat = not autoCheat
			Spring.Echo("AutoCheat: " .. tostring(autoCheat))
		end,
	},
	{
		command = "luaui",
		suggestions = function(cmd, cmdParts)
			local suggestions = {}
			local param = cmdParts[2]
			for _, name in pairs({"reload", "enable"}) do
				if param == nil or param == "" or name:starts(param) then
					table.insert(suggestions, { command = "/luaui " .. name, text = name, description = value })
				end
			end
			return suggestions
		end,
	},
	{
		command = "luarules",
		suggestions = function(cmd, cmdParts)
			local suggestions = {}
			local param = cmdParts[2]
			for _, name in pairs({"reload", "enable"}) do
				if param == nil or param == "" or name:starts(param) then
					table.insert(suggestions, { command = "/luarules " .. name, text = name, description = value })
				end
			end
			return suggestions
		end,
	},
	{
		command = "give",
		suggestions = function(cmd, cmdParts)
			local suggestions = {}
			local param = cmdParts[2]
			local count
			local teamPart = cmdParts[3]
			if tonumber(param) ~= nil then
				param = cmdParts[3]
				count = tonumber(cmdParts[2])
				if math.floor(count) ~= count or count <= 0 then
					return suggestions
				end
				teamPart = cmdParts[4]
			end
			for id, uDef in pairs(UnitDefs) do
				if param == nil or param == "" or uDef.name:starts(param) then
					local text = uDef.name
					local desc = "Give " .. uDef.name
					if count then
						text = count .. " " .. text
						desc = "Give " .. count .. " " .. uDef.name
					end
					if teamPart then
						for _, teamID in pairs(Spring.GetTeamList()) do
							if teamPart == "" or tostring(teamID):starts(teamPart) then
								local teamText = text .. " " .. teamID
								local teamDesc = desc .. " to team " .. teamID
								if uDef.name ~= uDef.tooltip then
									teamDesc = teamDesc .. uDef.tooltip
								end
								table.insert(suggestions, { command = "/give " .. teamText, text = teamText, description = teamDesc })
							end
						end
					else
						if uDef.name ~= uDef.tooltip then
							desc = desc .. uDef.tooltip
						end
						table.insert(suggestions, { command = "/give " .. text, text = text, description = desc })
					end
				end
			end
			return suggestions
		end,
	},
	{
		command = "w",
		suggestions = function(cmd, cmdParts)
			local suggestions = {}
			local param = cmdParts[2]
			for _, playerID in pairs(Spring.GetPlayerList()) do
				local playerName = Spring.GetPlayerInfo(playerID)
				table.insert(suggestions, { command = "/w " .. playerName, text = playerName})
			end
			return suggestions
		end,
	},
	{
		command = "login",
		exec = function(command, cmdParts)
			WG.LibLobby.lobby:AddListener("OnTASServer", function()
				WG.LibLobby.lobby:Login(cmdParts[2], VFS.CalcMd5(cmdParts[3]), 3)
				WG.LibLobby.lobby:AddListener("OnJoin",
					function(listener, chanName)
						local id = 1
						while true do
							if not consoles[id] then
								consoles[id] = chanName
								break
							end
							id = id + 1
						end
					end
				)
				WG.LibLobby.lobby:AddListener("OnSaid", 
					function(listener, chanName, userName, message)
						for id, name in pairs(consoles) do
							if name == chanName then
								-- print channel message
								local msg = "\255\204\153\1[" .. tostring(id) .. ". " .. chanName .. "] <" .. userName .. "> " .. message .. "\b"
								Spring.Echo(msg)
								break
							end
						end
					end
				)
			end)
			WG.LibLobby.lobby:Connect("springrts.com", 8200)
		end,
	},
	{
		command = "logout",
		exec = function(command, cmdParts)
			Spring.Echo("TODO: LOGOUT")
-- 			WG.LibLobby.lobby:Connect("springrts.com", 8200)
-- 			WG.LibLobby.lobby:AddListener("OnTASServer", function()
-- 				WG.LibLobby.lobby:Login(cmdParts[2], VFS.CalcMd5(cmdParts[3]), 3)
-- 			end)
		end,
	},
	{
		command = "join",
		exec = function(command, cmdParts)
			WG.LibLobby.lobby:Join(cmdParts[2], cmdParts[3])
		end,
	},
	{
		command = "leave",
		exec = function(command, cmdParts)
			WG.LibLobby.lobby:Leave(cmdParts[2])
		end,
	},
	{
		command = "set",
		suggestions = function(cmd, cmdParts)
			local suggestions = {}
			local param = cmdParts[2]
			for _, config in pairs(Spring.GetConfigParams()) do
				if param == nil or param == "" or config.name:starts(param) then
					local desc = config.description
					if desc then
						desc = desc:gsub("\n", " ")
					end
					table.insert(suggestions, { command = "/set " .. config.name, text = config.name, description = desc})
				end
			end
			return suggestions
		end, 
	},
}

-- Chili
local Chili, screen0
local ebConsole
local lblContext
local spSuggestions, scrollSuggestions 

-- history
local historyFilePath = ".console_history"
local historyFile
local history = {}

local currentHistory = 0
local filteredHistory = {}

-- suggestions
local currentSuggestion = 0
local currentSubSuggestion = 0
local suggestions = {}
local suggestionNameMapping = {} -- name -> index in "suggestions" table
local filteredSuggestions = {}
local dynamicSuggestions = {}
local preText -- used to determine if text changed

-- context 
local defaultContext = { display = "Say:", name = "say", persist = true }
local currentContext

-- autocheat
local autoCheat = true
local autoCheatBuffer = {}

function string.trimLeft(str)
  return str:gsub("^%s*(.-)", "%1")
end

function string.trim(str)
  return str:gsub("^%s*(.-)%s*$", "%1")
end

function widget:Initialize()
	if not WG.Chili then
		widgetHandler:RemoveWidget(widget)
	end
	Chili = WG.Chili
	screen0 = Chili.Screen0
	Spring.SendCommands("unbindkeyset enter chat")
	
	local vsx,vsy = Spring.GetViewGeometry()
	ebConsole = Chili.EditBox:New {
		width = consoleWidth * vsx,
		height = 40,
		parent = screen0,
		cursorColor = {0.9,0.9,0.9,0.7},
		font = {
			size = 22,
-- 			shadow = false,
			font = fontFile,
		},
		KeyPress = function(...)
			if not ParseKey(...) then
				return Chili.EditBox.KeyPress(...)
			end
			return true
		end,
		OnKeyPress = { function(...)
			PostParseKey(...)
		end},
		OnTextInput =  { function(...)
			PostParseKey(...)
		end},
		borderColor = { 0, 0, 0, 0 },
		focusColor = { 0, 0, 0, 0 },
	}
	ebConsole:Hide()
	
	scrollSuggestions = Chili.ScrollPanel:New {
		borderColor = { 0, 0, 0, 0 },
		focusColor = { 0, 0, 0, 0 },
		backgroundColor = { 0, 0, 0, 1 },
		parent = screen0,
		scrollbarSize = 4,
	}
	spSuggestions = Chili.Control:New {
		x = 0,
		y = 0,
		autosize = true,
		itemMargin    = {0,0,0,0},
		itemPadding   = {0,0,0,0},
		padding 	  = {0, 0, 0, 0},
		parent = scrollSuggestions,
	}
	scrollSuggestions:Hide()
	
	lblContext = Chili.Label:New {
		width = 90,
		align = "right",
		caption = "",
		parent = screen0,
		font = {
			font = fontFile,
			size = 20,
			shadow = true,
		},
	}
	lblContext:Hide()
	
	-- read history
	pcall(function()
		for line in io.lines(historyFilePath) do 
			table.insert(history, line)
		end
	end)
	
	historyFile = io.open(historyFilePath, "a")
	
	GenerateSuggestions()
	ResizeUI(vsx, vsy)
end

function ResizeUI(vsx, vsy)
	ebConsole:SetPos(consoleX * vsx, consoleY * vsy, consoleWidth * vsx)
	scrollSuggestions:SetPos(consoleX * vsx, consoleY * vsy + ebConsole.height, consoleWidth * vsx, suggestionsHeight * vsy)
	spSuggestions:SetPos(nil, nil, consoleWidth * vsx, suggestionsHeight * vsy)
	lblContext:SetPos(consoleX * vsx - lblContext.width - 6, consoleY * vsy + 7)
end

function widget:ViewResize(vsx, vsy)
	ResizeUI(vsx, vsy)
end

function widget:Shutdown()
	if historyFile then
		historyFile:close()
	end
	Spring.SendCommands("bindkeyset enter chat") --because because.
end

function widget:KeyPress(key, ...)
	if key == Spring.GetKeyCode("enter") or key == Spring.GetKeyCode("numpad_enter") then
		if not ebConsole.visible then
			ebConsole:Show()
		end
		screen0:FocusControl(ebConsole)
		if currentContext == nil or not currentContext.persist then
			currentContext = defaultContext
		end
		ShowContext()
		return true
	end
end

function SuggestionsUp()
	if currentSubSuggestion > 1 then
		currentSubSuggestion = currentSubSuggestion - 1
		local suggestion = dynamicSuggestions[currentSubSuggestion].suggestion
		ebConsole:SetText(suggestion.command)
		ebConsole.cursor = #ebConsole.text + 1
		UpdateSuggestions()
	elseif currentSuggestion > 1 then
		currentSuggestion = currentSuggestion - 1
-- 			if currentSuggestion > 0 then
		local id = filteredSuggestions[currentSuggestion]
		ebConsole:SetText(suggestions[id].text)
		ebConsole.cursor = #ebConsole.text + 1
		UpdateSuggestions()
-- 			end
	end
end

function SuggestionsDown()
	if #filteredSuggestions == 1 and #dynamicSuggestions ~= 0 then
		if #dynamicSuggestions > currentSubSuggestion then
			currentSubSuggestion = currentSubSuggestion + 1
			local suggestion = dynamicSuggestions[currentSubSuggestion].suggestion
			ebConsole:SetText(suggestion.command)
			ebConsole.cursor = #ebConsole.text + 1
			UpdateSuggestions()
		end
	elseif #filteredSuggestions > currentSuggestion then
		currentSuggestion = currentSuggestion + 1
		local id = filteredSuggestions[currentSuggestion]
		ebConsole:SetText(suggestions[id].text)
		ebConsole.cursor = #ebConsole.text + 1
		UpdateSuggestions()
	end
end

function ParseKey(ebConsole, key, mods, ...)
	if key == Spring.GetKeyCode("enter") or 
		key == Spring.GetKeyCode("numpad_enter") then
		ProcessText(ebConsole.text)
		HideConsole()
	elseif key == Spring.GetKeyCode("esc") then
		HideConsole()
	elseif key == Spring.GetKeyCode("up") then
		if currentSuggestion > 0 or currentSubSuggestion > 0 then
			SuggestionsUp()
		else
			if currentHistory == 0 then
				FilterHistory(ebConsole.text)
			end
			if #filteredHistory > currentHistory then
				--and not (currentHistory == 0 and ebConsole.text ~= "") 
				currentHistory = currentHistory + 1
				ShowHistoryItem()
				ShowSuggestions()
			end
		end
	elseif key == Spring.GetKeyCode("down") then
		if currentHistory > 0 then
			currentHistory = currentHistory - 1
			ShowHistoryItem()
			ShowSuggestions()
		elseif #filteredSuggestions > currentSuggestion or #dynamicSuggestions > currentSubSuggestion then
			SuggestionsDown()
		end
	elseif key == Spring.GetKeyCode("tab") then
		if #filteredSuggestions == 0 then
			return true
		end
		local nextSuggestion, nextSubSuggestion
		if #filteredSuggestions > currentSuggestion then
			nextSuggestion = currentSuggestion + 1
		else
			nextSuggestion = 1
		end
		if #dynamicSuggestions > currentSubSuggestion then
			nextSubSuggestion = currentSubSuggestion + 1
		else
			nextSubSuggestion = 1
		end
		if #filteredSuggestions == 1 and #dynamicSuggestions ~= 0 and #suggestions[filteredSuggestions[1]].text <= #ebConsole.text then
			if #dynamicSuggestions[nextSubSuggestion].suggestion.command >= #ebConsole.text or currentSubSuggestion ~= 0 then
				currentSubSuggestion = nextSubSuggestion
				local suggestion = dynamicSuggestions[currentSubSuggestion].suggestion
				if #dynamicSuggestions > 1 then
					ebConsole:SetText(suggestion.command)
				else
					ebConsole:SetText(suggestion.command .. " ")
				end
				ebConsole.cursor = #ebConsole.text + 1
				UpdateSuggestions()
			end
		elseif #suggestions[filteredSuggestions[nextSuggestion]].text >= #ebConsole.text or currentSuggestion ~= 0 then
			currentSuggestion = nextSuggestion
			local id = filteredSuggestions[currentSuggestion]
			if #filteredSuggestions > 1 then
				ebConsole:SetText(suggestions[id].text)
			else
				-- this will also select it if there's only one option
				ebConsole:SetText(suggestions[id].text .. " ")
			end
			ebConsole.cursor = #ebConsole.text + 1
			UpdateSuggestions()
		end
	elseif key == Spring.GetKeyCode("pageup") then
		for i = 1, pageUpFactor do
			if currentSuggestion > 0 then
				SuggestionsUp()
			end
		end
	elseif key == Spring.GetKeyCode("pagedown") then
		for i = 1, pageDownFactor do
			if #filteredSuggestions > currentSuggestion then
				SuggestionsDown()
			end
		end
	else
		preText = ebConsole.text
		return false
	end
	return true
end

function FilterHistory(txt)
	filteredHistory = {}
	for _, historyItem in pairs(history) do
		if historyItem:starts(txt) then
			table.insert(filteredHistory, historyItem)
		end
	end
end

function PostParseKey(...)
	local txt = ebConsole.text
	if txt == "/a " or txt == "a:" then
		ebConsole:SetText("")
		currentContext = { display = "Allies:", name = "allies", persist = true }
	elseif txt == "/s " then
		ebConsole:SetText("")
		currentContext = { display = "Say:", name = "say", persist = true }
	elseif txt == "/spec " or txt == "s:" then
		ebConsole:SetText("")
		currentContext = { display = "Spectators:", name = "spectators", persist = true }
-- 	elseif txt:trim():starts("/") and #txt:trim() > 1 then
-- 		currentContext = { display = "Command:", name = "command", persist = false }
	elseif tonumber(txt:trim():sub(2)) ~= nil and txt:sub(#txt, #txt) == " " then
		local id = tonumber(txt:trim():sub(2))
		if consoles[id] == nil then
			return
		end
		ebConsole:SetText("")
		currentContext = { display = "\255\204\153\1[" .. tostring(id) .. ". " .. consoles[id] .. "]\b", name = "channel", id = id, persist = true }
	elseif not currentContext.persist then
		currentContext = { display = "Say:", name = "say", persist = true }
	end
	if preText ~= txt then -- only update suggestions if text changed
		currentSuggestion = 0
		currentSubSuggestion = 0
		UpdateSuggestions()
		if #txt > 0 then
			ShowSuggestions()
		else
			HideSuggestions()
		end
	end
	ShowContext()
end

function HideConsole()
	ebConsole:Hide()
	screen0:FocusControl(nil)
	ebConsole:SetText("")
	currentHistory = 0
	currentSuggestion = 0
	currentSubSuggestion = 0
	lblContext:Hide()
	HideSuggestions()
end

function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

function ShowContext()
	if not lblContext.visible then
		lblContext:Show()
	end
	lblContext:SetCaption(currentContext.display)
end

function CreateSuggestion(suggestion)
	local ctrlSuggestion = Chili.Button:New {
		x = 0,
		minHeight = suggesitonFontSize + suggesitonPadding,
		autosize = true,
		width = "100%",
		resizable = false,
		draggable = false,
		padding  = {0,0,0,0},
		--focusColor = { 0, 0, 0, 0 },
		id = suggestion.id,
		caption = "",
	}
	local lblSuggestion = Chili.Label:New {
		x = 0,
		caption = suggestion.text,
		autosize = true,
		padding 	  = {0, 0, 0, 0},
		font = {
			size = suggesitonFontSize,
-- 			shadow = false,
			color = white,
			font = fontFile,
		},
		parent = ctrlSuggestion,
	}
	ctrlSuggestion.lblSuggestion = lblSuggestion
	local lblDescription = Chili.Label:New {
		x = 300,
		autosize = true,
		caption = suggestion.description or "",
		padding 	  = {0, 0, 0, 0},
		font = {
			size = suggesitonFontSize,
-- 			shadow = false,
			color = grey,
			font = fontFile,
		},
		parent = ctrlSuggestion,
	}
	ctrlSuggestion.lblDescription = lblDescription
	if suggestion.cheat then 
		local lblCheat = Chili.Label:New {
			width = 100,
			x = 200,
			caption = "(cheat)",
			align = "right",
			padding 	  = {0, 0, 0, 0},
			font = {
				size = suggesitonFontSize,
-- 				shadow = false,
				color = color,
				font = fontFile,
			},
			parent = ctrlSuggestion,
		}
		ctrlSuggestion.lblCheat = lblCheat
	end
	return ctrlSuggestion
end

function GenerateSuggestions()
	suggestions = GetCommandList()
	for i, suggestion in pairs(suggestions) do
		suggestion.text = "/" .. suggestion.command:lower()
		suggestion.visible = false
		suggestion.id = i
		suggestionNameMapping[suggestion.command:lower()] = i
	end
-- 	if txt:lower():starts("/gamerules") then
-- 		local txt = txt:sub(#"/gamerules"+1):trim()
-- 		txt = explode(" ", txt)[1]
-- 		for index, rule in pairs(Spring.GetGameRulesParams()) do
-- 			if type(rule) == "table" then
-- 				for name, value in pairs(rule) do
-- 					if txt == nil or txt == "" or name:starts(txt) then
-- 						table.insert(suggestions, { command = "/gamerules " .. name, text = name, description = value })
-- 					end
-- 				end
-- 			end
-- 		end
-- 	else
-- 		
	spSuggestions.ctrls = {}
	for _, suggestion in pairs(suggestions) do
		local ctrlSuggestion = CreateSuggestion(suggestion)
		spSuggestions.ctrls[suggestion.id] = ctrlSuggestion
		spSuggestions:AddChild(ctrlSuggestion)
	end
	local fakeCtrl = Chili.Button:New {
		x = 0,
		y = (#suggestions - 1) * (suggesitonFontSize + suggesitonPadding),
		height = (suggesitonFontSize + suggesitonPadding),
		autosize = true,
		--width = "100%",
		resizable = false,
		draggable = false,
		padding  = {0,0,0,0},
		focusColor = { 0, 0, 0, 0 },
		backgroundColor = { 0, 0, 0, 0 },
		id = -1,
		caption = "",
	}
	-- FIXME: fake control because chili has bugs
	spSuggestions:AddChild(fakeCtrl)
	spSuggestions.fakeCtrl = fakeCtrl
end

function CleanupSuggestions()
	-- cleanup dynamic suggestions
	for _, dynamicSuggestion in pairs(dynamicSuggestions) do
		spSuggestions:RemoveChild(dynamicSuggestion)
		dynamicSuggestion:Dispose()
	end
	
	dynamicSuggestions = {}
	filteredSuggestions = {}
end

function FilterSuggestions(txt)
	CleanupSuggestions()
	
	local count = 0
	for _, suggestion in pairs(suggestions) do
		suggestion.visible = false
	end
	if txt:sub(1, 1) == "/" then
		local cmdParts = explode(" ", txt:sub(2):trimLeft():gsub("%s+", " "))
		local partialCmd = cmdParts[1]:lower()
		local addedCommands = {}
		for _, suggestion in pairs(suggestions) do
			local cmdName = suggestion.command:lower()
			local matched
			if #cmdParts > 1 then 
				matched = cmdName == partialCmd
			else
				matched = cmdName:starts(partialCmd)
			end
			if matched and not addedCommands[suggestion.id] then
				suggestion.visible = true
				count = count + 1
				table.insert(filteredSuggestions, suggestion.id)
				addedCommands[suggestion.id] = true
			end
		end
-- 		for _, command in pairs(commandList) do
-- 			if command.command:lower():find(partialCmd:lower()) and not addedCommands[command.command] then
-- 				table.insert(suggestions, { command = "/" .. command.command, text = command.command, description = command.description, cheat = command.cheat })
-- 				addedCommands[command.command] = true
-- 			end
-- 		end

		-- only one suggestion is visible
		if count == 1 then
			local suggestion = suggestions[filteredSuggestions[1]]
			if suggestion.suggestions ~= nil then
				local suggestions = suggestion.suggestions(txt, cmdParts)
				for i, suggestion in pairs(suggestions) do
					if suggestion.visible == nil then
						suggestion.visible = true
					end
					local ctrlSuggestion = CreateSuggestion(suggestion)
					ctrlSuggestion.suggestion = suggestion
					ctrlSuggestion.suggestion.dynId = i
					table.insert(dynamicSuggestions, ctrlSuggestion)
					spSuggestions:AddChild(ctrlSuggestion)
				end
			end
		end
	end
end

function ShowSuggestions()
	if not scrollSuggestions.visible then
		scrollSuggestions:Show()
	end
	
	FilterSuggestions(ebConsole.text)
	UpdateSuggestions()	
end

function UpdateSuggestionDisplay(suggestion, ctrlSuggestion, row)
	if suggestion.visible then
		ctrlSuggestion.y = (row - 1) * (suggesitonFontSize + suggesitonPadding)
		
		if not ctrlSuggestion.visible then
			ctrlSuggestion:Show()
		end
		
		if currentSubSuggestion == 0 and suggestion.id ~= nil and suggestion.id == filteredSuggestions[currentSuggestion] then
			ctrlSuggestion.backgroundColor = selectedSuggestionColor
		elseif suggestion.dynId ~= nil and suggestion.dynId == currentSubSuggestion then
			ctrlSuggestion.backgroundColor = selectedSuggestionColor
		elseif suggestion.id == nil then
 			ctrlSuggestion.backgroundColor = subsuggestionColor
		else
			ctrlSuggestion.backgroundColor = { 0, 0, 0, 0 }
		end
		
		if suggestion.cheat then
			local cheatColor
			if Spring.IsCheatingEnabled() then
				cheatColor = green
			elseif autoCheat then
				cheatColor = yellow
			else
				cheatColor = red
			end
			ctrlSuggestion.lblCheat.font.color = cheatColor
			ctrlSuggestion.lblCheat:Invalidate()
		end
		
		ctrlSuggestion:Invalidate()
	elseif ctrlSuggestion.visible then
		ctrlSuggestion:Hide()
	end	
end

function UpdateSuggestions()
	local count = 0
	for _, suggestion in pairs(suggestions) do
		local ctrlSuggestion = spSuggestions.ctrls[suggestion.id]
		if suggestion.visible then
			count = count + 1
		end
		UpdateSuggestionDisplay(suggestion, ctrlSuggestion, count)	
	end
	for _, dynamicSuggestion in pairs(dynamicSuggestions) do
		count = count + 1
		dynamicSuggestion.x = 50
		UpdateSuggestionDisplay(dynamicSuggestion.suggestion, dynamicSuggestion, count)
	end
	
	-- FIXME: magic numbers and fake controls ^_^
	spSuggestions.fakeCtrl.y = (count-1+1) * (suggesitonFontSize + suggesitonPadding)
	
	if currentSuggestion ~= 0 and scrollSuggestions.visible then
		local suggestion = suggestions[filteredSuggestions[currentSuggestion]]
		local selY = spSuggestions.ctrls[suggestion.id].y
		scrollSuggestions:SetScrollPos(0, selY, true, false)
	end
	if count > 0 and not scrollSuggestions.visible then
		scrollSuggestions:RequestUpdate()
		scrollSuggestions:Show()
	elseif count == 0 and scrollSuggestions.visible then
		scrollSuggestions:Hide()
	end
	
	spSuggestions:Invalidate()
end

function HideSuggestions()
	CleanupSuggestions()
	if scrollSuggestions.visible then
		scrollSuggestions:Hide()
	end
end

function ShowHistoryItem()
	if currentHistory == 0 then
		ebConsole:SetText("")
	end
	local historyItem = filteredHistory[#filteredHistory - currentHistory + 1]
	if historyItem ~= nil then
		ebConsole:SetText(historyItem)
		ebConsole.cursor = #ebConsole.text + 1
	end
end

function ExecuteCommand(luaCommandStr)
	Spring.Echo("$ " .. luaCommandStr)
-- 			if not luaCommandStr:gsub("==", "_"):gsub("~=", "_"):gsub(">=", "_"):gsub("<=", "_"):find("=") then
-- 				luaCommandStr = "return " .. luaCommandStr
-- 			end
	local luaCommand, msg = loadstring(luaCommandStr)
	if not luaCommand then
		Spring.Echo(msg)
	else
		setfenv(luaCommand, getfenv())
		local success, msg = pcall(function()
			local msg = {luaCommand()}
			if #msg > 0 then
				Spring.Echo(unpack(msg))
			end
		end)
		if not success then
			Spring.Echo(msg)
		end
	end
end

function ProcessText(str)
	if #str:trim() == 0 then
		return
	end
	AddHistory(str)
	--str = str:trim()
	-- command
	if str:sub(1, 1) == '/' then
		local command = str:sub(2):trimLeft()
		local cmdParts = explode(" ", command:lower():gsub("%s+", " "))
		if #cmdParts == 2 and cmdParts[1] == "luaui" and cmdParts[2] == "reload" then
			-- FIXME: This is awful as it will reload everyones Lua UI
			Spring.SendLuaRulesMsg('luaui_reload')
		else
			for _, cmd in pairs(cmdConfig) do
				if cmd.command == cmdParts[1]:lower() and cmd.exec ~= nil then
					cmd.exec(command, cmdParts)
					return
				end
			end
			
			local index = suggestionNameMapping[cmdParts[1]]
			Spring.Echo(command)
			if index then
				local suggestion = suggestions[index]
				if (suggestion.cheat or cmdParts[1] == "luarules" and cmdParts[2] == "reload") and not Spring.IsCheatingEnabled() then
					if autoCheat then
						Spring.SendCommands("cheat 1")
						table.insert(autoCheatBuffer, command)
					else
						Spring.Echo("Enable cheats with /cheat or /autocheat")
						Spring.SendCommands(command)
					end
				else
					Spring.SendCommands(command)
				end
			else
				Spring.Echo("Unknown command: " .. command)
				Spring.SendCommands(command)
			end
		end
	else
		local command
		if currentContext.name == "say" then
			command = "say "
		elseif currentContext.name == "allies" then
			command = "say a:"
		elseif currentContext.name == "spectators" then
			command = "say s:"
		elseif currentContext.name == "channel" then
			WG.LibLobby.lobby:Say(consoles[currentContext.id], str)
			return
		else
			Spring.Echo("Unexpected context " .. currentContext.name)
			command = "say "
		end
		Spring.SendCommands(command .. str)
		--Spring.SendMessageToTeam(Spring.GetMyTeamID(), str)
	end
end

function widget:DrawWorld()
	if delayGL then
		delayGL()
		delayGL = nil
	end
end

function widget:Update()
	if #autoCheatBuffer > 0 and Spring.IsCheatingEnabled() then
		for _, command in pairs(autoCheatBuffer) do
			Spring.SendCommands(command)
		end
		autoCheatBuffer = {}
		Spring.SendCommands("cheat 0")
	end
end

function AddHistory(str)
	if #history > 0 and history[#history] == str then
		return
	end
	table.insert(history, str)
	if historyFile then
		historyFile:write(str .. "\n")
	end
end

function GetCommandList()
	-- TODO: use the engine provided list instead of a hardcoded one
	local commandList = {
	{ command = "Atm",  mode = "synced", description = "Gives 1000 metal and 1000 energy to the issuing players team"},
	{ command = "Cheat", mode = "synced", description = "Enables/Disables cheating, which is required for a lot of other commands to be usable"},
	{ command = "Destroy",  mode = "synced", description = "Destroys one or multiple units by unit-ID, instantly"}, 
	{ command = "DevLua",  mode = "synced",  description = "Enables/Disables Lua dev-mode (can cause desyncs if enabled)" }, 
	{ command = "EditDefs", mode = "synced", description = "Allows/Disallows editing of unit-, feature- and weapon-defs through Lua", },
	{ command = "CmdColors",  mode = "unsynced", description = "Reloads cmdcolors.txt" },
	{ command = "CommandHelp", mode = "unsynced", description = "Prints info about a specific chat command (so far only synced/unsynced and the description)" },
	{ command = "CommandList", mode = "unsynced", description = "Prints all the available chat commands with description (if available) to the console" },
	{ command = "Console", mode = "unsynced", description = "Enables/Disables the in-game console"},
	{ command = "ControlUnit", mode = "unsynced",  description = "Start to first-person-control a unit"}, 
	{ command = "Crash", mode = "unsynced", description = "Invoke an artificial crash through a NULL-pointer dereference (SIGSEGV)"},
		-- 	{ name = "CreateVideo                     (unsynced)  Start/Stop capturing a video of the game in progress
		-- 	{ name = "Cross                           (unsynced)  Allows one to exchange and modify the appearance of the cross/mouse-pointer in first-person-control view
		-- 	{ name = "CtrlPanel                       (unsynced)  Reloads ctrlpanel.txt
		-- 	{ name = "Debug                           (unsynced)  Enable/Disable debug info rendering mode
		-- 	{ name = "DebugColVol                     (unsynced)  Enable/Disable drawing of collision volumes
		-- 	{ name = "DebugDrawAI                     (unsynced)  Enables/Disables debug drawing for AIs
		-- 	{ name = "DebugInfo                       (unsynced)  Print debug info to the chat/log-file about either: sound, profiling
		-- 	{ name = "DebugPath                       (unsynced)  Enable/Disable drawing of pathfinder debug-data
		-- 	{ name = "DebugTraceRay                   (unsynced)  Enable/Disable drawing of traceray debug-data
		-- 	{ name = "DecGUIOpacity                   (unsynced)  Decreases the the opacity(see-through-ness) of GUI elements
	}
	
	if Spring.GetUICommands then
		commandList = Spring.GetUICommands()
	end
	
	local names = {}
	for _, command in pairs(commandList) do
		if command.synced then
			names[command.command:lower()] = true
		end
	end
	-- removed unsynced commands
	for i = #commandList, 1, -1 do
		local cmd = commandList[i]
		if not cmd.synced and names[cmd.command:lower()] then
			Spring.Echo("Removed duplicate command: ", cmd.command, cmd.description)
			table.remove(commandList, i)
		end
	end
	
	-- create a name mapping and merge any existing commands
	names = {}
	for _, command in pairs(commandList) do
		names[command.command:lower()] = command
	end
	for _, command in pairs(cmdConfig) do
		local cmd = names[command.command:lower()]
		if cmd == nil then
			table.insert(commandList, command)
		else
			table.merge(cmd, command)
		end
	end
	table.sort(commandList, function(cmd1, cmd2) 
		return cmd1.command:lower() < cmd2.command:lower() 
	end)
	return commandList
end