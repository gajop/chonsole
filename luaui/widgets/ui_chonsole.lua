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

VFS.Include(CHONSOLE_FOLDER .. "/luaui/config/globals.lua", nil, VFS.DEF_MODE)

-- constants
local grey = { 0.7, 0.7, 0.7, 1 }
local white = { 1, 1, 1, 1 }
local blue = { 0, 0, 1, 1 }
local teal = { 0, 1, 1, 1 }
local red =  { 1, 0, 0, 1 }
local green = { 0, 1, 0, 1 }
local yellow = { 1, 1, 0, 1 }

-- context 
local currentContext

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

-- autocheat
autoCheat = true
local autoCheatBuffer = {}

-- extensions
local cmdConfig = {}
local contextParser = {}

-- extension API
function GetCurrentContext()
	return currentContext
end
function ResetCurrentContext()
	currentContext = { display = i18n("say_context", {default="Say:"}), name = "say", persist = true }
	ShowContext()
end
-- extension API end

function string.trimLeft(str)
  return str:gsub("^%s*(.-)", "%1")
end

function string.trim(str)
  return str:gsub("^%s*(.-)%s*$", "%1")
end

local function ExtractDir(filepath)
  filepath = filepath:gsub("\\", "/")
  local lastChar = filepath:sub(-1)
  if (lastChar == "/") then
    filepath = filepath:sub(1,-2)
  end
  local pos,b,e,match,init,n = 1,1,1,1,0,0
  repeat
    pos,init,n = b,init+1,n+1
    b,init,match = filepath:find("/",init,true)
  until (not b)
  if (n==1) then
    return filepath
  else
    return filepath:sub(1,pos)
  end
end

local function ExtractFileName(filepath)
  filepath = filepath:gsub("\\", "/")
  local lastChar = filepath:sub(-1)
  if (lastChar == "/") then
    filepath = filepath:sub(1,-2)
  end
  local pos,b,e,match,init,n = 1,1,1,1,0,0
  repeat
    pos,init,n = b,init+1,n+1
    b,init,match = filepath:find("/",init,true)
  until (not b)
  if (n==1) then
    return filepath
  else
    return filepath:sub(pos+1)
  end
end

function widget:Initialize()
	if not WG.Chili then
		widgetHandler:RemoveWidget(widget)
	end
	Chili = WG.Chili
	screen0 = Chili.Screen0
	i18n = WG.i18n
	if not i18n then
		-- add optional support for i18n
		i18n = function(key, data)
			data = data or {}
			return data.default or key
		end
	end
	
	-- Load global translations
	if WG.i18n then
		VFS.Include(CHONSOLE_FOLDER .. "/i18n.lua", nil, VFS.DEF_MODE)
		if translations ~= nil then
			i18n.load(translations)
		end
	end
	-- Load extensions
	for _, f in pairs(VFS.DirList(CHONSOLE_FOLDER .. "/exts", "*", VFS.DEF_MODE)) do
		-- Load translations first
		if WG.i18n then
			local fname = ExtractFileName(f)
			local fdir = ExtractDir(f)
			local i18nFile = fdir .. "i18n/" .. fname
			if VFS.FileExists(i18nFile, nil, VFS.DEF_MODE) then
				local success, err = pcall(function() VFS.Include(i18nFile, nil, VFS.DEF_MODE) end)
				if not success then
					Spring.Log("Chonsole", LOG.ERROR, "Error loading translation file: " .. f)
					Spring.Log("Chonsole", LOG.ERROR, err)
				end
				if translations ~= nil then
					i18n.load(translations)
				end
			end
		end
		-- Load extension
		local success, err = pcall(function() VFS.Include(f, nil, VFS.DEF_MODE) end)
		if not success then
			Spring.Log("Chonsole", LOG.ERROR, "Error loading extension file: " .. f)
			Spring.Log("Chonsole", LOG.ERROR, err)
		else
			if commands ~= nil then
				for _, cmd in pairs(commands) do
					table.insert(cmdConfig, cmd)
				end
	-- 			table.merge(cmdConfig, t.commands)
			end
			if context ~= nil then
				for _, parser in pairs(context) do
					table.insert(contextParser, parser)
				end
			end
		end
	end
	
	Spring.SendCommands("unbindkeyset enter chat")
	
	local vsx,vsy = Spring.GetViewGeometry()
	ebConsole = Chili.EditBox:New {
		width = config.console.w * vsx,
		height = 40,
		parent = screen0,
		cursorColor = {0.9,0.9,0.9,0.7},
		font = {
			size = 22,
-- 			shadow = false,
			font = config.console.fontFile,
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
			font = config.console.fontFile,
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
	ebConsole:SetPos(config.console.x * vsx, config.console.y * vsy, config.console.w * vsx)
	scrollSuggestions:SetPos(config.console.x * vsx, config.console.y * vsy + ebConsole.height, config.console.w * vsx, config.suggestions.h * vsy)
	spSuggestions:SetPos(nil, nil, config.console.w * vsx, config.suggestions.h * vsy)
	lblContext:SetPos(config.console.x * vsx - lblContext.width - 6, config.console.y * vsy + 7)
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
			currentContext = { display = i18n("say_context", {default="Say:"}), name = "say", persist = true }
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
		for i = 1, config.suggestions.pageUpFactor do
			if currentSuggestion > 0 then
				SuggestionsUp()
			end
		end
	elseif key == Spring.GetKeyCode("pagedown") then
		for i = 1, config.suggestions.pageDownFactor do
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
	if txt:lower() == "/a " or txt:lower() == "a:" then
		ebConsole:SetText("")
		currentContext = { display = i18n("allies_context", {default="Allies:"}), name = "allies", persist = true }
	elseif txt:lower() == "/s " or txt:lower() == "/say " then
		ebConsole:SetText("")
		currentContext = { display = i18n("say_context", {default="Say:"}), name = "say", persist = true }
	elseif txt:lower() == "/spec " or txt:lower() == "s:" then
		ebConsole:SetText("")
		currentContext = { display = i18n("spectators_context", {default="Spectators:"}), name = "spectators", persist = true }
-- 	elseif txt:trim():starts("/") and #txt:trim() > 1 then
-- 		currentContext = { display = "Command:", name = "command", persist = false }
	else
		local res, context = false, nil
		for _, parser in pairs(contextParser) do
			local success, err = pcall(function() res, context = parser.parse(txt)end)
			if not success then
				Spring.Log("Chonsole", LOG.ERROR, "Error processing custom context: " .. tostring(cmd.command))
				Spring.Log("Chonsole", LOG.ERROR, err)
			end
			if res then
				ebConsole:SetText("")
				currentContext = context
				break
			end
		end
		
		if not res and not currentContext.persist then
			currentContext = { display = i18n("say_context", {default="Say:"}), name = "say", persist = true }
		end
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
		minHeight = config.suggestions.fontSize + config.suggestions.padding,
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
			size = config.suggestions.fontSize,
-- 			shadow = false,
			color = white,
			font = config.console.fontFile,
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
			size = config.suggestions.fontSize,
-- 			shadow = false,
			color = grey,
			font = config.console.fontFile,
		},
		parent = ctrlSuggestion,
	}
	ctrlSuggestion.lblDescription = lblDescription
	if suggestion.cheat then 
		local lblCheat = Chili.Label:New {
			width = 100,
			x = 200,
			caption = i18n("cheat_command", {default="(cheat)"}),
			align = "right",
			padding 	  = {0, 0, 0, 0},
			font = {
				size = config.suggestions.fontSize,
-- 				shadow = false,
				color = color,
				font = config.console.fontFile,
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
		y = (#suggestions - 1) * (config.suggestions.fontSize + config.suggestions.padding),
		height = (config.suggestions.fontSize + config.suggestions.padding),
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
				local suggestions
				local success, err = pcall(function() 
					suggestions = suggestion.suggestions(txt, cmdParts)
				end)
				if not success then
					Spring.Log("Chonsole", LOG.ERROR, "Error obtaining suggestions for command: " .. tostring(suggestion.command))
					Spring.Log("Chonsole", LOG.ERROR, err)
					return
				end
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
		ctrlSuggestion.y = (row - 1) * (config.suggestions.fontSize + config.suggestions.padding)
		
		if not ctrlSuggestion.visible then
			ctrlSuggestion:Show()
		end
		
		if currentSubSuggestion == 0 and suggestion.id ~= nil and suggestion.id == filteredSuggestions[currentSuggestion] then
			ctrlSuggestion.backgroundColor = config.suggestions.suggestionColor
		elseif suggestion.dynId ~= nil and suggestion.dynId == currentSubSuggestion then
			ctrlSuggestion.backgroundColor = config.suggestions.suggestionColor
		elseif suggestion.id == nil then
 			ctrlSuggestion.backgroundColor = config.suggestions.subsuggestionColor
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
	spSuggestions.fakeCtrl.y = (count-1+1) * (config.suggestions.fontSize + config.suggestions.padding)
	
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
					local success, err = pcall(function() cmd.exec(command, cmdParts) end)
					if not success then
						Spring.Log("Chonsole", LOG.ERROR, "Error executing custom command: " .. tostring(cmd.command))
						Spring.Log("Chonsole", LOG.ERROR, err)
					end
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
				Spring.Log("Chonsole", LOG.WARNING, "Unknown command: " .. command)
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
		else
			local found = false
			for _, parser in pairs(contextParser) do
				if currentContext.name == parser.name then
					local success, err = pcall(function() parser.exec(str, currentContext) end)
					if not success then
						Spring.Log("Chonsole", LOG.ERROR, "Error executing custom context: " .. tostring(cmd.command))
						Spring.Log("Chonsole", LOG.ERROR, err)
					end
					found = true
					break
				end
			end
			
			if not found then
				Spring.Echo(currentContext)
				Spring.Echo("Unexpected context " .. currentContext.name)
				command = "say "
			end
		end
		if command then
			Spring.SendCommands(command .. str)
		end
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
	local commandList = {}
	
	if Spring.GetUICommands then
		commandList = Spring.GetUICommands()
	else
		Spring.Log("Chonsole", LOG.ERROR, "Using unsupported engine: no Spring.GetUICommands function")
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
			Spring.Log("Chonsole", LOG.NOTICE, "Removed duplicate command: ", cmd.command, cmd.description)
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