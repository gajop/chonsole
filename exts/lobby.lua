-- Lobby chat
local consoles = {} -- ID -> name mapping

-- disable in case there's no liblobby installed
if not WG.LibLobby or not WG.LibLobby.lobby then
	Spring.Echo("Chonsole", i18n("liblobby_not_installed", {default = "liblobby is not installed. Lobby support disabled."}))
	return
end
Spring.Echo("Chonsole", i18n("liblobby_not_installed", {default = "liblobby is installed. Lobby support enabled."}))

local channelColor = "\204\153\1"
commands = {
	{
		command = "login",
		description = i18n("login_desc", {default = "Login to Spring Lobby"}),
		exec = function(command, cmdParts)
			WG.LibLobby.lobby:AddListener("OnTASServer", function()
				WG.LibLobby.lobby:Login(cmdParts[2], VFS.CalcMd5(cmdParts[3]), 3)
				WG.LibLobby.lobby:AddListener("OnJoin",
					function(listener, chanName)
						local id = 1
						while true do
							if not consoles[id] then
								consoles[id] = chanName
								Spring.Echo("\255" .. channelColor .. i18n("joined", {default = "Joined"}) .. " [" .. tostring(id) .. ". " .. chanName .. "]")
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
								local msg = "\255" .. channelColor .. "[" .. tostring(id) .. ". " .. chanName .. "] <" .. userName .. "> " .. message .. "\b"
								Spring.Echo(msg)
								break
							end
						end
					end
				)
			end)
			WG.LibLobby.lobby:AddListener("OnAccepted",
				function(listener)
				Spring.Echo("\255" .. channelColor .. i18n("connected_server", {default="Connected to server."}))
				end
			)
			WG.LibLobby.lobby:AddListener("OnDisconnected",
				function(listener)
				Spring.Echo("\255" .. channelColor .. i18n("disconnected_server", {default="Disconnected from server."}))
				end
			)
			WG.LibLobby.lobby:Connect("springrts.com", 8200)
		end,
	},
	{
		command = "logout",
		description = i18n("logout_desc", {default="Logout from Spring Lobby"}),
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
		description = i18n("join_desc", {default="Join a channel"}),
		exec = function(command, cmdParts)
			WG.LibLobby.lobby:Join(cmdParts[2], cmdParts[3])
		end,
	},
	{
		command = "leave",
		description = i18n("leave_desc", {default="Leave a channel"}),
		exec = function(command, cmdParts)
			local chanName = cmdParts[2]
			local currentContext = GetCurrentContext()
			if chanName == nil or chanName:trim() == "" then
				if currentContext.name == "channel" then
					chanName = consoles[currentContext.id]
				else
					return
				end
			end
			-- TODO: should probably use a listener instead but need to implement it
			for id, name in pairs(consoles) do
				if name == chanName then
					Spring.Echo("\255" .. channelColor .. i18n("left", {default="Left"}) .. "[" .. tostring(id) .. ". " .. chanName .. "]")
					if currentContext.name == "channel" and currentContext.id == id then
						ResetCurrentContext()
					end
					consoles[id] = nil
					break
				end
			end
			WG.LibLobby.lobby:Leave(chanName)
		end,
	},
}

context = {
	{
		name = "channel",
		parse = function(txt)
			if tonumber(txt:trim():sub(2)) ~= nil and txt:sub(#txt, #txt) == " " then
				local id = tonumber(txt:trim():sub(2))
				if consoles[id] ~= nil then
					return true, { display = "\255" .. channelColor .. "[" .. tostring(id) .. ". " .. consoles[id] .. "]\b", name = "channel", id = id, persist = true }
				end
			end
		end,
		exec = function(str, context)
			WG.LibLobby.lobby:Say(consoles[context.id], str)
		end
	},
}