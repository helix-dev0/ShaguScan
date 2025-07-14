if ShaguScan.disabled then return end

local utils = ShaguScan.utils
local settings = {}

-- Slash command setup
SLASH_SHAGUSCAN1, SLASH_SHAGUSCAN2, SLASH_SHAGUSCAN3 = "/scan", "/sscan", "/shaguscan"

SlashCmdList["SHAGUSCAN"] = function(input)
  if input and input ~= '' then
    -- Direct access to specific window config (advanced usage)
    ShaguScan.dialogs.OpenConfig(input)
  else
    -- Show main window/settings (default behavior)
    ShaguScan.mainpanel.OpenMainWindow()
  end
end

-- Legacy function for backward compatibility
settings.OpenMainWindow = function()
  ShaguScan.mainpanel.OpenMainWindow()
end

-- Legacy function for backward compatibility
settings.OpenConfig = function(caption)
  ShaguScan.dialogs.OpenConfig(caption)
end

-- Export the module
ShaguScan.settings = settings