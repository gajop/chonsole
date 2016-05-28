-- Do not load this in gadgets
if not WG then
	return
end

local allyContext = { display = i18n("ally_context", {default="Ally:"}), name = "ally", persist = true }
local sayContext = { display = i18n("say_context", {default="Say:"}), name = "say", persist = true }
local specContext = { display = i18n("spec_context", {default="Spec:"}), name = "spec", persist = true }

SetDefaultContext(sayContext)

local function KeyPress(key, mods, ...)
	if key == Spring.GetKeyCode("enter") or key == Spring.GetKeyCode("numpad_enter") then
		if mods.alt then
			SetContext(allyContext)
		elseif mods.shift then
			SetContext(specContext)
		elseif mods.ctrl or (GetCurrentContext() == nil or not GetCurrentContext().persist) then
			SetContext(sayContext)
		else
			return false
		end
		return true
	end
end

local function ParseKey(key, mods, isRepeat)
	if mods.alt then
		if GetCurrentContext().name == "ally" then
			SetContext(sayContext)
		else
			SetContext(allyContext)
		end
	elseif mods.ctrl then
		SetContext(sayContext)
	elseif mods.shift then
		if GetCurrentContext().name == "spec" then
			SetContext(sayContext)
		else
			SetContext(specContext)
		end
	else
		return false
	end
	ShowContext()
	return true
end

local function CleanPrefix(txt)
	local prefix = txt:lower():sub(1, 2)
	if prefix == "a:" or prefix == "s:" then
		txt = txt:sub(3)
	end
	return txt
end

local function SetConsoleText(txt)
	ebConsole:SetText(txt)
	ebConsole.cursor = #ebConsole.text + 1
end

context = {
	{
		name = "ally",
		parse = function(txt)
			if config.chat.showPrefix then
				if txt:lower():sub(1, 2) == "a:" then
					return allyContext
				end
				txt = CleanPrefix(txt)
			end
			if txt:lower() == "/a " then
				return allyContext
			end
		end,
		enter = function(txt)
			if config.chat.showPrefix then
				SetConsoleText("a:" .. CleanPrefix(txt))
			end
		end,
		exec = function(txt)
			if config.chat.showPrefix then
				Spring.SendCommands("say " .. txt)
			else
				Spring.SendCommands("say a:" .. txt)
			end
		end,
		keyPress = function(...)
			return KeyPress(...)
		end,
		parseKey = function(...)
			return ParseKey(...)
		end,
	},
	{
		name = "say",
		parse = function(txt)
			if txt:lower() == "/say " then
				SetConsoleText("")
				return sayContext
			end
			if config.chat.showPrefix then
				if txt:lower():sub(1, 2) ~= "a:" and txt:lower():sub(1, 2) ~= "s:" then
					return sayContext
				end
			end
		end,
		enter = function(txt)
			if config.chat.showPrefix then
				SetConsoleText(CleanPrefix(txt))
			end
		end,
		exec = function(txt)
			Spring.SendCommands("say " .. txt)
		end,
		keyPress = function(...)
			return KeyPress(...)
		end,
		parseKey = function(...)
			return ParseKey(...)
		end,
	},
	{
		name = "spec",
		parse = function(txt)
			if config.chat.showPrefix then
				if txt:lower():sub(1, 2) == "s:" then
					return specContext
				end
				txt = CleanPrefix(txt)
			end
			if txt:lower() == "/spec " then
				return specContext
			end
-- 			if txt:lower() == "/spec " or txt:lower() == "s:" then
-- -- 				ebConsole:SetText("")
-- 				return specContext
-- 			end
		end,
		enter = function(txt)
			if config.chat.showPrefix then
				SetConsoleText("s:" .. CleanPrefix(txt))
			end
		end,
		exec = function(txt)
			if config.chat.showPrefix then
				Spring.SendCommands("say " .. txt)
			else
				Spring.SendCommands("say s:" .. txt)
			end
		end,
		keyPress = function(...)
			return KeyPress(...)
		end,
		parseKey = function(...)
			return ParseKey(...)
		end,
	},
}
