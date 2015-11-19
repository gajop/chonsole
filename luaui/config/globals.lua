-- constants
local grey = { 0.7, 0.7, 0.7, 1 }
local white = { 1, 1, 1, 1 }
local blue = { 0, 0, 1, 1 }
local teal = { 0, 1, 1, 1 }
local red =  { 1, 0, 0, 1 }
local green = { 0, 1, 0, 1 }
local yellow = { 1, 1, 0, 1 }

-- General
config = {
	console = {
		x = 0.26,
		y = 0.25,
		w = 0.5,
		--fontFile = "LuaUI/fonts/dejavu-sans-mono/DejaVuSansMono.ttf",
	},
	suggestions = {
		h = 0.4,
		fontSize = 16,
		padding = 4,
		pageUpFactor = 10,
		pageDownFactor = 10,
		selectedColor = { 0, 1, 1, 0.4 },
		subsuggestionColor = { 0, 0, 0, 0 },
	},
}

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