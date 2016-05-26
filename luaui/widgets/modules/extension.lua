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

-- this is used to identify the current command used in Sync
local currentCmd = ""
function Sync(...)
	local x = {...}
	local msg = "chonsole|" .. currentCmd
	for _, v in pairs(x) do
		msg = msg .. "|" .. v
	end
	Spring.SendLuaRulesMsg(msg)
end
-- extension API end


function InitializeExtensions()
	i18n = WG.i18n
	if not i18n then
		-- optional support for i18n
		i18n = function(key, data)
			data = data or {}
			return data.default or key
		end
	end
end

function LoadTranslations()
	-- Load global translations
	if WG.i18n then
		VFS.Include(CHONSOLE_FOLDER .. "/i18n.lua", nil, VFS.DEF_MODE)
		if translations ~= nil then
			i18n.load(translations)
		end
	end
end

function LoadExtensions()
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
		commands = nil
		local success, err = pcall(function() VFS.Include(f, nil, VFS.DEF_MODE) end)
		if not success then
			Spring.Log("Chonsole", LOG.ERROR, "Error loading extension file: " .. f)
			Spring.Log("Chonsole", LOG.ERROR, err)
		else
			if commands ~= nil then
				for _, cmd in pairs(commands) do
					table.insert(cmdConfig, cmd)
				end
			end
			if context ~= nil then
				for _, parser in pairs(context) do
					table.insert(contextParser, parser)
				end
			end
		end
	end
end

function GetExtensions()
	return cmdConfig
end

function GetContexts()
	return contextParser
end
