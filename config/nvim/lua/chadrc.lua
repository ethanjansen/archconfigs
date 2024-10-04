-- This file needs to have same structure as nvconfig.lua 
-- https://github.com/NvChad/ui/blob/v2.5/lua/nvconfig.lua
-- Please read that file to know all available options :( 

---@type ChadrcConfig
local M = {}

M.base46 = {
  theme = "dark_horizon",
  theme_toggle = {"dark_horizon", "doomchad"},
  -- transparency = true,
  

  hl_override = {
		Comment = { italic = true },
		["@comment"] = { italic = true },
	},
}

M.ui = {
  statusline = {
    theme = "vscode_colored",
  },
}

return M
