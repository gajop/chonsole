if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name 	= "Console handling",
		desc	= "Handles the console",
		author	= "gajop",
		date	= "In the future 2015",
		license	= "GNU GPL, v2 or later",
		layer	= 0,
		enabled = true
	}
end

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

function HandleLuaMessage(msg)
	local msg_table = explode('|', msg)
	if msg_table[1] == 'luaui_reload' then
		Spring.SendCommands("luaui reload")
	elseif msg_table[1] == "set_gamerule" then
		Spring.SetGameRulesParam(msg_table[2], msg_table[3])
	elseif msg_table[1] == "set_teamrule" then
		Spring.SetTeamRulesParam(msg_table[2], msg_table[3], msg_table[4])
	elseif msg_table[1] == "set_unitrule" then
		Spring.SetUnitRulesParam(msg_table[2], msg_table[3])
	end
end

function gadget:RecvLuaMsg(msg)
	HandleLuaMessage(msg)
end

local myGameRules = {}

function gadget:GameFrame()
-- 	for index, rule in pairs(Spring.GetGameRulesParams()) do
-- 		if type(rule) == "table" then
-- 			for name, value in pairs(rule) do
-- 				local myGameVar = "_game_rule" .. type(value) .. name
-- 				if myGameRules[name] == nil then
-- 					myGameRules[name] = myGameVar
-- 					myGameRules[myGameVar] = true
-- 					Spring.SetGameRulesParam(myGameVar, value)
-- 				end
-- 			end
-- 		end
-- 	end
end