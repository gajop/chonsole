-- Lobby chat
local consoles = {} -- ID -> name mapping

-- disable in case there's no liblobby installed
if not WG.LibLobby or not WG.LibLobby.lobby then
	Spring.Echo("Chonsole", "liblobby is not installed. Lobby support disabled.")
	return
end
Spring.Echo("Chonsole", "liblobby is installed. Lobby support enabled.")

commands = {
	{
		command = "login",
		description = "Login to Spring Lobby",
		exec = function(command, cmdParts)
			WG.LibLobby.lobby:AddListener("OnTASServer", function()
				WG.LibLobby.lobby:Login(cmdParts[2], VFS.CalcMd5(cmdParts[3]), 3)
				WG.LibLobby.lobby:AddListener("OnJoin",
					function(listener, chanName)
						local id = 1
						while true do
							if not consoles[id] then
								consoles[id] = chanName
								Spring.Echo("\255\204\153\1Joined [" .. tostring(id) .. ". " .. chanName .. "]")
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
			WG.LibLobby.lobby:AddListener("OnAccepted",
				function(listener)
				Spring.Echo("\255\204\153\1Connected to server.")
				end
			)
			WG.LibLobby.lobby:AddListener("OnDisconnected",
				function(listener)
				Spring.Echo("\255\204\153\1Disconnected from server.")
				end
			)
			WG.LibLobby.lobby:Connect("springrts.com", 8200)
		end,
	},
	{
		command = "logout",
		description = "Logout from Spring Lobby",
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
		description = "Join a channel",
		exec = function(command, cmdParts)
			WG.LibLobby.lobby:Join(cmdParts[2], cmdParts[3])
		end,
	},
	{
		command = "leave",
		description = "Leave a channel",
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
					Spring.Echo("\255\204\153\1Left [" .. tostring(id) .. ". " .. chanName .. "]")
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
					return true, { display = "\255\204\153\1[" .. tostring(id) .. ". " .. consoles[id] .. "]\b", name = "channel", id = id, persist = true }
				end
			end
		end,
		exec = function(str, context)
			WG.LibLobby.lobby:Say(consoles[context.id], str)
		end
	},
}