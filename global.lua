ShaguScan = {}
ShaguScan.core = {} -- Forward declaration for core module

-- Initialize pfUI integration after addon loading
local function InitializePfUIIntegration()
  -- This will be called after all addons are loaded
  if ShaguScan.utils and ShaguScan.pfui then
    -- Update to use integrated pfUI styling
    local defaultFont = "Interface\\AddOns\\ShaguScan\\fonts\\RobotoMono.ttf"
    local pfUIColors = ShaguScan.utils.GetIntegratedPfUIColors()
    
    -- Update global template to use integrated pfUI styling
    if ShaguScan_db.global_settings.default_template.text_font == STANDARD_TEXT_FONT then
      ShaguScan_db.global_settings.default_template.text_font = defaultFont
      ShaguScan_db.global_settings.default_template.background_color = pfUIColors.background
      ShaguScan_db.global_settings.default_template.border_color = pfUIColors.border
      ShaguScan_db.global_settings.default_template.text_color = pfUIColors.text
      ShaguScan_db.global_settings.default_template.bar_texture = "Interface\\AddOns\\ShaguScan\\img\\bar"
      ShaguScan_db.global_settings.default_template.frame_shadow = true
    end
    
    -- Update existing window configs to use integrated pfUI styling
    for windowName, config in pairs(ShaguScan_db.config) do
      if config.text_font == STANDARD_TEXT_FONT then
        config.text_font = defaultFont
        config.background_color = pfUIColors.background
        config.border_color = pfUIColors.border
        config.text_color = pfUIColors.text
        config.bar_texture = "Interface\\AddOns\\ShaguScan\\img\\bar"
        config.frame_shadow = true
      end
    end
  end
end

ShaguScan_db = {
  -- Global settings that apply to all scan windows
  global_settings = {
    -- Default display template for new scan windows
    default_template = {
      bar_texture = "Interface\\AddOns\\ShaguScan\\img\\bar",
      bar_color_mode = "reaction",
      bar_color_custom = {r=1, g=0.8, b=0.2, a=1},
      background_alpha = 0.9,
      background_color = {r=0.06, g=0.06, b=0.06, a=0.9},
      background_texture = "default",
      border_style = "default",
      border_color = {r=0.2, g=0.2, b=0.2, a=1},
      text_font = STANDARD_TEXT_FONT,
      text_size = 10,
      text_outline = "THINOUTLINE",
      text_position = "left",
      text_format = "level_name",
      text_color = {r=0.8, g=0.8, b=0.8, a=1},
      health_text_enabled = false,
      health_text_position = "right",
      health_text_format = "percent",
      frame_shadow = false,
      frame_glow = false
    },
    -- General addon settings
    auto_cleanup_time = 30, -- seconds to keep old units
    max_units_per_window = 50, -- maximum units to show per window
    enable_sound_alerts = false,
    enable_minimap_button = true,
    debug_mode = false,
    hide_window_headers = false -- hide scan window name/header when no units are found
  },
  config = {
    ["Infight NPCs"] = {
      filter = "npc,infight",
      scale = 1, anchor = "CENTER", x = -240, y = 120, width = 100, height = 14, spacing = 4, maxrow = 20,
      -- Display customization options with pfUI-inspired defaults
      bar_texture = "Interface\\TargetingFrame\\UI-StatusBar",
      bar_color_mode = "reaction", -- "reaction", "class", "custom"
      bar_color_custom = {r=1, g=0.8, b=0.2, a=1},
      background_alpha = 0.9,
      background_color = {r=0.06, g=0.06, b=0.06, a=0.9},
      border_style = "default", -- "none", "thin", "thick", "glow", "default"
      border_color = {r=0.2, g=0.2, b=0.2, a=1},
      text_font = STANDARD_TEXT_FONT,
      text_size = 10,
      text_outline = "THINOUTLINE",
      text_position = "left", -- "left", "center", "right"
      text_format = "level_name", -- "level_name", "name_only", "level_only", "health_percent", "health_current"
      text_color = {r=0.8, g=0.8, b=0.8, a=1},
      health_text_enabled = false,
      health_text_position = "right", -- "left", "center", "right"
      health_text_format = "percent", -- "percent", "current", "current_max", "deficit"
      frame_shadow = false,
      frame_glow = false
    },

    ["Raid Targets"] = {
      filter = "icon,alive",
      scale = 1, anchor = "CENTER", x = 240, y = 120, width = 100, height = 14, spacing = 4, maxrow = 20,
      -- Display customization options with pfUI-inspired defaults
      bar_texture = "Interface\\TargetingFrame\\UI-StatusBar",
      bar_color_mode = "reaction", -- "reaction", "class", "custom"
      bar_color_custom = {r=1, g=0.8, b=0.2, a=1},
      background_alpha = 0.9,
      background_color = {r=0.06, g=0.06, b=0.06, a=0.9},
      border_style = "default", -- "none", "thin", "thick", "glow", "default"
      border_color = {r=0.2, g=0.2, b=0.2, a=1},
      text_font = STANDARD_TEXT_FONT,
      text_size = 10,
      text_outline = "THINOUTLINE",
      text_position = "left", -- "left", "center", "right"
      text_format = "level_name", -- "level_name", "name_only", "level_only", "health_percent", "health_current"
      text_color = {r=0.8, g=0.8, b=0.8, a=1},
      health_text_enabled = false,
      health_text_position = "right", -- "left", "center", "right"
      health_text_format = "percent", -- "percent", "current", "current_max", "deficit"
      frame_shadow = false,
      frame_glow = false
    }
  }
}

if not GetPlayerBuffID or not CombatLogAdd or not SpellInfo then
  local notify = CreateFrame("Frame", nil, UIParent)
  notify:SetScript("OnUpdate", function()
    DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00Shagu|cffffffffScan:|cffffaaaa Couldn't detect SuperWoW.")
    this:Hide()
  end)

  ShaguScan.disabled = true
end

-- Hook for pfUI integration after addon loading
local pfUIInitFrame = CreateFrame("Frame")
pfUIInitFrame:RegisterEvent("ADDON_LOADED")
pfUIInitFrame:SetScript("OnEvent", function()
  if event == "ADDON_LOADED" and arg1 == "ShaguScan" then
    -- Initialize pfUI integration after our addon is loaded
    InitializePfUIIntegration()
    this:UnregisterEvent("ADDON_LOADED")
  end
end)