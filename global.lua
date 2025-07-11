ShaguScan = {}
ShaguScan_db = {
  -- Global settings that apply to all scan windows
  global_settings = {
    -- Default display template for new scan windows
    default_template = {
      bar_texture = "Interface\\TargetingFrame\\UI-StatusBar",
      bar_color_mode = "reaction",
      bar_color_custom = {r=1, g=0.8, b=0.2, a=1},
      background_alpha = 0.8,
      background_color = {r=0, g=0, b=0, a=1},
      border_style = "default",
      border_color = {r=0.2, g=0.2, b=0.2, a=1},
      text_font = STANDARD_TEXT_FONT,
      text_size = 9,
      text_outline = "THINOUTLINE",
      text_position = "left",
      text_format = "level_name",
      text_color = {r=1, g=1, b=1, a=1},
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
    debug_mode = false
  },
  config = {
    ["Infight NPCs"] = {
      filter = "npc,infight",
      scale = 1, anchor = "CENTER", x = -240, y = 120, width = 100, height = 14, spacing = 4, maxrow = 20,
      -- Display customization options
      bar_texture = "Interface\\TargetingFrame\\UI-StatusBar",
      bar_color_mode = "reaction", -- "reaction", "class", "custom"
      bar_color_custom = {r=1, g=0.8, b=0.2, a=1},
      background_alpha = 0.8,
      background_color = {r=0, g=0, b=0, a=1},
      border_style = "default", -- "none", "thin", "thick", "glow", "default"
      border_color = {r=0.2, g=0.2, b=0.2, a=1},
      text_font = STANDARD_TEXT_FONT,
      text_size = 9,
      text_outline = "THINOUTLINE",
      text_position = "left", -- "left", "center", "right"
      text_format = "level_name", -- "level_name", "name_only", "level_only", "health_percent", "health_current"
      text_color = {r=1, g=1, b=1, a=1},
      health_text_enabled = false,
      health_text_position = "right", -- "left", "center", "right"
      health_text_format = "percent", -- "percent", "current", "current_max", "deficit"
      frame_shadow = false,
      frame_glow = false
    },

    ["Raid Targets"] = {
      filter = "icon,alive",
      scale = 1, anchor = "CENTER", x = 240, y = 120, width = 100, height = 14, spacing = 4, maxrow = 20,
      -- Display customization options
      bar_texture = "Interface\\TargetingFrame\\UI-StatusBar",
      bar_color_mode = "reaction", -- "reaction", "class", "custom"
      bar_color_custom = {r=1, g=0.8, b=0.2, a=1},
      background_alpha = 0.8,
      background_color = {r=0, g=0, b=0, a=1},
      border_style = "default", -- "none", "thin", "thick", "glow", "default"
      border_color = {r=0.2, g=0.2, b=0.2, a=1},
      text_font = STANDARD_TEXT_FONT,
      text_size = 9,
      text_outline = "THINOUTLINE",
      text_position = "left", -- "left", "center", "right"
      text_format = "level_name", -- "level_name", "name_only", "level_only", "health_percent", "health_current"
      text_color = {r=1, g=1, b=1, a=1},
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