if ShaguScan.disabled then return end

local utils = {}

utils.strsplit = function(delimiter, subject)
  if not subject then return nil end
  local delim, fields = delimiter or ":", {}
  local pattern = string.format("([^%s]+)", delim)
  string.gsub(subject, pattern, function(c) fields[table.getn(fields)+1] = c end)
  return unpack(fields)
end

utils.round = function(input, places)
  if not places then places = 0 end
  if type(input) == "number" and type(places) == "number" then
    local pow = 1
    for i = 1, places do pow = pow * 10 end
    return floor(input * pow + 0.5) / pow
  end
end

utils.IsValidAnchor = function(anchor)
  if anchor == "TOP" then return true end
  if anchor == "TOPLEFT" then return true end
  if anchor == "TOPRIGHT" then return true end
  if anchor == "CENTER" then return true end
  if anchor == "LEFT" then return true end
  if anchor == "RIGHT" then return true end
  if anchor == "BOTTOM" then return true end
  if anchor == "BOTTOMLEFT" then return true end
  if anchor == "BOTTOMRIGHT" then return true end
  return false
end

utils.GetBestAnchor = function(self)
  local scale = self:GetScale()
  local x, y = self:GetCenter()
  local a = GetScreenWidth()  / scale / 3
  local b = GetScreenWidth()  / scale / 3 * 2
  local c = GetScreenHeight() / scale / 3 * 2
  local d = GetScreenHeight() / scale / 3
  if not x or not y then return end

  if x < a and y > c then
    return "TOPLEFT"
  elseif x > a and x < b and y > c then
    return "TOP"
  elseif x > b and y > c then
    return "TOPRIGHT"
  elseif x < a and y > d and y < c then
    return "LEFT"
  elseif x > a and x < b and y > d and y < c then
    return "CENTER"
  elseif x > b and y > d and y < c then
    return "RIGHT"
  elseif x < a and y < d then
    return "BOTTOMLEFT"
  elseif x > a and x < b and y < d then
    return "BOTTOM"
  elseif x > b and y < d then
    return "BOTTOMRIGHT"
  end
end

utils.ConvertFrameAnchor = function(self, anchor)
  local scale, x, y, _ = self:GetScale(), nil, nil, nil

  if anchor == "CENTER" then
    x, y = self:GetCenter()
    x, y = x - GetScreenWidth()/2/scale, y - GetScreenHeight()/2/scale
  elseif anchor == "TOPLEFT" then
    x, y = self:GetLeft(), self:GetTop() - GetScreenHeight()/scale
  elseif anchor == "TOP" then
    x, _ = self:GetCenter()
    x, y = x - GetScreenWidth()/2/scale, self:GetTop() - GetScreenHeight()/scale
  elseif anchor == "TOPRIGHT" then
    x, y = self:GetRight() - GetScreenWidth()/scale, self:GetTop() - GetScreenHeight()/scale
  elseif anchor == "RIGHT" then
    _, y = self:GetCenter()
    x, y = self:GetRight() - GetScreenWidth()/scale, y - GetScreenHeight()/2/scale
  elseif anchor == "BOTTOMRIGHT" then
    x, y = self:GetRight() - GetScreenWidth()/scale, self:GetBottom()
  elseif anchor == "BOTTOM" then
    x, _ = self:GetCenter()
    x, y = x - GetScreenWidth()/2/scale, self:GetBottom()
  elseif anchor == "BOTTOMLEFT" then
    x, y = self:GetLeft(), self:GetBottom()
  elseif anchor == "LEFT" then
    _, y = self:GetCenter()
    x, y = self:GetLeft(), y - GetScreenHeight()/2/scale
  end

  return anchor, utils.round(x, 2), utils.round(y, 2)
end

local _r, _g, _b, _a
utils.rgbhex = function(r, g, b, a)
  if type(r) == "table" then
    if r.r then
      _r, _g, _b, _a = r.r, r.g, r.b, (r.a or 1)
    elseif table.getn(r) >= 3 then
      _r, _g, _b, _a = r[1], r[2], r[3], (r[4] or 1)
    end
  elseif tonumber(r) then
    _r, _g, _b, _a = r, g, b, (a or 1)
  end

  if _r and _g and _b and _a then
    -- limit values to 0-1
    _r = _r + 0 > 1 and 1 or _r + 0
    _g = _g + 0 > 1 and 1 or _g + 0
    _b = _b + 0 > 1 and 1 or _b + 0
    _a = _a + 0 > 1 and 1 or _a + 0
    return string.format("|c%02x%02x%02x%02x", _a*255, _r*255, _g*255, _b*255)
  end

  return ""
end

utils.GetReactionColor = function(unitstr)
  -- Handle test units
  if unitstr == "test_unit_preview" then
    return utils.rgbhex(0.2, 1, 0.2), 0.2, 1, 0.2  -- Green (friendly) for test
  end
  
  local reaction = UnitReaction(unitstr, "player")
  local r, g, b = 1, 0.2, 0.2 -- Default to red (hostile)
  
  if reaction and UnitReactionColor[reaction] then
    local color = UnitReactionColor[reaction]
    r, g, b = color.r, color.g, color.b
  end

  return utils.rgbhex(r,g,b), r, g, b
end

utils.GetUnitColor = function(unitstr)
  local r, g, b = .8, .8, .8
  
  -- Handle test units
  if unitstr == "test_unit_preview" then
    return utils.rgbhex(0.67, 0.83, 0.45), 0.67, 0.83, 0.45  -- Hunter green for test
  end

  if UnitIsPlayer(unitstr) then
    local _, class = UnitClass(unitstr)

    if class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] then
      r, g, b = RAID_CLASS_COLORS[class].r, RAID_CLASS_COLORS[class].g, RAID_CLASS_COLORS[class].b
    elseif class then
      -- Fallback class colors
      if class == "WARRIOR" then r, g, b = 0.78, 0.61, 0.43
      elseif class == "PALADIN" then r, g, b = 0.96, 0.55, 0.73
      elseif class == "HUNTER" then r, g, b = 0.67, 0.83, 0.45
      elseif class == "ROGUE" then r, g, b = 1, 0.96, 0.41
      elseif class == "PRIEST" then r, g, b = 1, 1, 1
      elseif class == "SHAMAN" then r, g, b = 0, 0.44, 0.87
      elseif class == "MAGE" then r, g, b = 0.41, 0.8, 0.94
      elseif class == "WARLOCK" then r, g, b = 0.58, 0.51, 0.79
      elseif class == "DRUID" then r, g, b = 1, 0.49, 0.04
      end
    end
  end

  return utils.rgbhex(r,g,b), r, g, b
end

utils.GetLevelColor = function(unitstr)
  -- Handle test units
  if unitstr == "test_unit_preview" then
    return utils.rgbhex(1, 1, 0), 1, 1, 0  -- Yellow for level 60
  end
  
  local color = GetDifficultyColor(UnitLevel(unitstr))
  local r, g, b = .8, .8, .8

  if color then
    r, g, b = color.r, color.g, color.b
  end

  return utils.rgbhex(r,g,b), r, g, b
end

utils.GetLevelString = function(unitstr)
  -- Handle test units
  if unitstr == "test_unit_preview" then
    return "60"
  end
  
  local level = UnitLevel(unitstr)
  if not level or level == -1 then 
    level = "??" 
  else
    level = tostring(level)
  end

  -- Don't check classification for test units
  if unitstr ~= "test_unit_preview" then
    local elite = UnitClassification(unitstr)
    if elite == "worldboss" then
      level = level .. "B"
    elseif elite == "rareelite" then
      level = level .. "R+"
    elseif elite == "elite" then
      level = level .. "+"
    elseif elite == "rare" then
      level = level .. "R"
    end
  end

  return level
end

utils.GetBarColor = function(unitstr, config)
  if config.bar_color_mode == "custom" then
    local c = config.bar_color_custom
    return utils.rgbhex(c.r, c.g, c.b, c.a), c.r, c.g, c.b, c.a or 1
  elseif config.bar_color_mode == "class" then
    local hex, r, g, b = utils.GetUnitColor(unitstr)
    return hex, r, g, b, 1 -- always return alpha of 1
  else -- reaction mode (default)
    local hex, r, g, b = utils.GetReactionColor(unitstr)
    return hex, r, g, b, 1 -- always return alpha of 1
  end
end

utils.GetBorderBackdrop = function(config)
  local backdrop = {
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 8,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
  }
  
  if config.border_style == "none" then
    return nil
  elseif config.border_style == "thin" then
    backdrop.edgeSize = 4
    backdrop.insets = { left = 1, right = 1, top = 1, bottom = 1 }
  elseif config.border_style == "thick" then
    backdrop.edgeSize = 12
    backdrop.insets = { left = 3, right = 3, top = 3, bottom = 3 }
  elseif config.border_style == "glow" then
    -- Use regular border with larger size for glow effect (vanilla may not have glow texture)
    backdrop.edgeSize = 16
    backdrop.insets = { left = 4, right = 4, top = 4, bottom = 4 }
  end
  
  return backdrop
end

utils.FormatHealthText = function(unitstr, format)
  -- Handle test units
  local current, max
  if unitstr == "test_unit_preview" then
    current, max = 75, 100
  else
    current = UnitHealth(unitstr)
    max = UnitHealthMax(unitstr)
  end
  
  if format == "percent" then
    local percent = max > 0 and floor(current / max * 100) or 0
    return percent .. "%"
  elseif format == "current" then
    return current
  elseif format == "current_max" then
    return current .. "/" .. max
  elseif format == "deficit" then
    local deficit = max - current
    return deficit > 0 and "-" .. deficit or ""
  end
  
  return ""
end

utils.FormatMainText = function(unitstr, format, config)
  local level = utils.GetLevelString(unitstr)
  local level_color = utils.GetLevelColor(unitstr)
  local name
  
  -- Handle test units
  if unitstr == "test_unit_preview" then
    name = "Test Unit Preview"
  else
    name = UnitName(unitstr)
  end
  
  -- Simple fallback for empty names
  if not name or name == "" then
    name = "Unknown"
  end
  
  if format == "name_only" then
    return name
  elseif format == "level_only" then
    return level_color .. level .. "|r"
  elseif format == "health_percent" then
    return utils.FormatHealthText(unitstr, "percent")
  elseif format == "health_current" then
    return utils.FormatHealthText(unitstr, "current")
  else -- level_name (default)
    return level_color .. level .. "|r " .. name
  end
end

utils.CreateFrameShadow = function(frame, config)
  if not config.frame_shadow then return end
  
  local shadow = CreateFrame("Frame", nil, frame)
  shadow:SetFrameStrata("BACKGROUND")
  shadow:SetFrameLevel(frame:GetFrameLevel() - 1)
  shadow:SetPoint("TOPLEFT", frame, "TOPLEFT", -4, 4)
  shadow:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 4, -4)
  
  local texture = shadow:CreateTexture(nil, "BACKGROUND")
  texture:SetAllPoints()
  texture:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
  texture:SetVertexColor(0, 0, 0, 0.8)
  
  return shadow
end

utils.CreateFrameGlow = function(frame, config)
  if not config.frame_glow then return end
  
  local glow = CreateFrame("Frame", nil, frame)
  glow:SetFrameStrata("BACKGROUND")
  glow:SetFrameLevel(frame:GetFrameLevel() - 1)
  glow:SetPoint("TOPLEFT", frame, "TOPLEFT", -8, 8)
  glow:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 8, -8)
  
  local texture = glow:CreateTexture(nil, "BACKGROUND")
  texture:SetAllPoints()
  texture:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border-Glow")
  texture:SetVertexColor(1, 1, 1, 0.3)
  
  return glow
end

utils.MergeConfigDefaults = function(config)
  -- Ensure all new display options have defaults for backward compatibility
  local pfui_colors = utils.GetPfUIColors()
  local defaults = {
    anchor = "CENTER",
    x = 0,
    y = 0,
    width = 150,
    height = 15,
    scale = 1,
    maxrow = 20,
    spacing = 2,
    filter = "player",
    bar_texture = utils.GetDefaultStatusbarTexture(),
    bar_color_mode = "reaction",
    bar_color_custom = {r=1, g=0.8, b=0.2, a=1},
    bar_alpha = 1.0,
    background_alpha = 0.9,
    background_color = pfui_colors.background,
    border_style = "default",
    border_color = pfui_colors.border,
    text_font = utils.GetDefaultPfUIFont(),
    text_size = 10,
    text_outline = "THINOUTLINE",
    text_position = "left",
    text_format = "level_name",
    text_color = pfui_colors.text,
    health_text_enabled = false,
    health_text_position = "right",
    health_text_format = "percent",
    frame_shadow = false,
    frame_glow = false
  }
  
  for key, value in pairs(defaults) do
    if config[key] == nil then
      config[key] = value
    end
  end
  
  return config
end

utils.DeepCopy = function(orig)
  local copy
  if type(orig) == 'table' then
    copy = {}
    for orig_key, orig_value in pairs(orig) do
      copy[orig_key] = utils.DeepCopy(orig_value)
    end
  else
    copy = orig
  end
  return copy
end

utils.MergeGlobalDefaults = function(global_config)
  -- Ensure global settings have all default values for backward compatibility
  local defaults = {
    auto_cleanup_time = 30,
    max_units_per_window = 50,
    enable_sound_alerts = false,
    enable_minimap_button = true,
    debug_mode = false,
    hide_window_headers = false
  }
  
  for key, value in pairs(defaults) do
    if global_config[key] == nil then
      global_config[key] = value
    end
  end
  
  return global_config
end

-- pfUI Font Integration
utils.pfUI_fonts = {
  ["BalooBhaina"] = "Interface\\AddOns\\pfUI-fonts\\fonts\\BalooBhaina.ttf",
  ["Bungee"] = "Interface\\AddOns\\pfUI-fonts\\fonts\\Bungee.ttf",
  ["CaesarDressing"] = "Interface\\AddOns\\pfUI-fonts\\fonts\\CaesarDressing.ttf",
  ["CoveredByYourGrace"] = "Interface\\AddOns\\pfUI-fonts\\fonts\\CoveredByYourGrace.ttf",
  ["JotiOne"] = "Interface\\AddOns\\pfUI-fonts\\fonts\\JotiOne.ttf",
  ["LodrinaSolid"] = "Interface\\AddOns\\pfUI-fonts\\fonts\\LodrinaSolid.ttf",
  ["NovaFlat"] = "Interface\\AddOns\\pfUI-fonts\\fonts\\NovaFlat.ttf",
  ["Roboto"] = "Interface\\AddOns\\pfUI-fonts\\fonts\\Roboto.ttf",
  ["SedgwickAveDisplay"] = "Interface\\AddOns\\pfUI-fonts\\fonts\\SedgwickAveDisplay.ttf",
  ["Share"] = "Interface\\AddOns\\pfUI-fonts\\fonts\\Share.ttf",
  ["ShareBold"] = "Interface\\AddOns\\pfUI-fonts\\fonts\\ShareBold.ttf",
  ["Sniglet"] = "Interface\\AddOns\\pfUI-fonts\\fonts\\Sniglet.ttf",
  ["SquadaOne"] = "Interface\\AddOns\\pfUI-fonts\\fonts\\SquadaOne.ttf"
}

utils.GetPfUIFont = function(fontName)
  if utils.pfUI_fonts[fontName] then
    return utils.pfUI_fonts[fontName]
  end
  return nil
end

utils.IsPfUIFontsAvailable = function()
  -- Check if pfUI-fonts addon is loaded
  if pfUI_fonts then
    return true
  end
  -- Alternative check: try to access a font file
  local testFont = utils.pfUI_fonts["Roboto"]
  if testFont then
    -- In vanilla WoW, we can't easily test file existence, so assume it's available if pfUI is present
    return pfUI ~= nil
  end
  return false
end

utils.GetDefaultPfUIFont = function()
  -- Return a good default pfUI font for UI elements
  if utils.IsPfUIFontsAvailable() then
    -- Roboto is a clean, readable font good for UI text
    return utils.GetPfUIFont("Roboto") or STANDARD_TEXT_FONT
  end
  return STANDARD_TEXT_FONT
end


utils.GetPfUIFontList = function()
  local fonts = {}
  local index = 1
  
  -- Add standard WoW fonts first
  fonts[index] = {name = "Standard", path = STANDARD_TEXT_FONT, preview = true}
  index = index + 1
  fonts[index] = {name = "Damage", path = DAMAGE_TEXT_FONT, preview = true}
  index = index + 1
  
  -- Add top 5 most popular and readable fonts for UI text
  local popular_fonts = {
    ["RobotoMono"] = "Interface\\AddOns\\ShaguScan\\fonts\\RobotoMono.ttf",
    ["PT Sans"] = "Interface\\AddOns\\ShaguScan\\fonts\\PT-Sans-Narrow-Regular.ttf",
    ["Continuum"] = "Interface\\AddOns\\ShaguScan\\fonts\\Continuum.ttf"
  }
  
  -- Add integrated fonts to list
  for name, path in pairs(popular_fonts) do
    fonts[index] = {name = name, path = path, preview = true}
    index = index + 1
  end
  
  -- Add only the 2 most popular pfUI fonts if available
  if pfUI and pfUI.font then
    local top_pfUI_fonts = {
      ["Roboto"] = "Interface\\AddOns\\pfUI\\fonts\\Roboto.ttf",
      ["Homespun"] = "Interface\\AddOns\\pfUI\\fonts\\Homespun.ttf"
    }
    
    for name, path in pairs(top_pfUI_fonts) do
      fonts[index] = {name = name, path = path, preview = true}
      index = index + 1
    end
  end
  
  return fonts
end

utils.GetFontPathFromName = function(fontName)
  -- Convert font name to path, handling both names and paths
  if not fontName then return STANDARD_TEXT_FONT end
  
  -- If it's already a path (contains backslash), return as-is
  if string.find(fontName, "\\") then
    return fontName
  end
  
  -- Convert name to path
  local fontList = utils.GetPfUIFontList()
  for i = 1, table.getn(fontList) do
    if fontList[i].name == fontName then
      return fontList[i].path
    end
  end
  
  -- Fallback to standard font
  return STANDARD_TEXT_FONT
end

-- Pre-defined backdrop configurations for performance
local BACKDROP_CONFIGS = {
  none = nil,
  default = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    tile = true, tileSize = 8,
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
  },
  gradient = {
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground", 
    tile = true, tileSize = 8,
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
  }
}

-- pfUI statusbar texture list
utils.GetPfUIStatusbarTextures = function()
  local textures = {}
  local index = 1
  
  -- Add default WoW statusbar textures first
  textures[index] = {name = "Default", path = "Interface\\TargetingFrame\\UI-StatusBar"}
  index = index + 1
  
  -- Add integrated pfUI-style statusbar textures (now included with ShaguScan)
  local integrated_textures = {
    ["pfUI Bar"] = "Interface\\AddOns\\ShaguScan\\img\\bar",
    ["pfUI ElvUI Style"] = "Interface\\AddOns\\ShaguScan\\img\\bar_elvui",
    ["pfUI Gradient"] = "Interface\\AddOns\\ShaguScan\\img\\bar_gradient",
    ["pfUI Striped"] = "Interface\\AddOns\\ShaguScan\\img\\bar_striped",
    ["pfUI TukUI Style"] = "Interface\\AddOns\\ShaguScan\\img\\bar_tukui"
  }
  
  -- Add integrated textures to list
  for name, path in pairs(integrated_textures) do
    textures[index] = {name = name, path = path}
    index = index + 1
  end
  
  -- Legacy: Add external pfUI textures if available (for backward compatibility)
  if pfUI and pfUI.media then
    -- Most popular pfUI statusbar textures
    local pfUI_textures = {
      ["Minimalist"] = "Interface\\AddOns\\pfUI\\media\\statusbar\\minimalist",
      ["Smooth"] = "Interface\\AddOns\\pfUI\\media\\statusbar\\smooth", 
      ["Gradient"] = "Interface\\AddOns\\pfUI\\media\\statusbar\\gradient",
      ["Flat"] = "Interface\\AddOns\\pfUI\\media\\statusbar\\flat",
      ["Gloss"] = "Interface\\AddOns\\pfUI\\media\\statusbar\\gloss",
      ["Aluminium"] = "Interface\\AddOns\\pfUI\\media\\statusbar\\aluminium",
      ["Glamour"] = "Interface\\AddOns\\pfUI\\media\\statusbar\\glamour",
      ["Perl"] = "Interface\\AddOns\\pfUI\\media\\statusbar\\perl",
      ["Outline"] = "Interface\\AddOns\\pfUI\\media\\statusbar\\outline",
      ["Striped"] = "Interface\\AddOns\\pfUI\\media\\statusbar\\striped"
    }
    
    -- Add pfUI textures to list
    for name, path in pairs(pfUI_textures) do
      textures[index] = {name = name, path = path}
      index = index + 1
    end
  end
  
  return textures
end

utils.GetBackgroundTexture = function(style)
  return BACKDROP_CONFIGS[style] or BACKDROP_CONFIGS.default
end

utils.GetPfUIBackground = function()
  return BACKDROP_CONFIGS.default
end

utils.GetPfUIColors = function()
  -- Return pfUI-inspired color scheme
  return {
    background = {r=0.06, g=0.06, b=0.06, a=0.9},      -- Dark gray background (#111111 equivalent)
    border = {r=0.2, g=0.2, b=0.2, a=1},               -- Medium gray border
    text = {r=0.8, g=0.8, b=0.8, a=1},                 -- Light gray text (#cccccc equivalent)
    accent = {r=0.2, g=1, b=0.8, a=1},                 -- Bright teal accent (#33ffcc equivalent)
    hover = {r=1, g=1, b=1, a=1}                       -- White hover
  }
end

utils.GetDefaultStatusbarTexture = function()
  -- Return integrated pfUI bar texture as default, with fallback
  return "Interface\\AddOns\\ShaguScan\\img\\bar"
end

-- Enhanced pfUI styling function using our integrated system
utils.ApplyPfUIStyle = function(frame, config)
  if not frame or not ShaguScan.pfui then return end
  
  -- Use our integrated pfUI styling system
  ShaguScan.pfui.StyleFrame(frame, config)
end

-- Check if integrated pfUI styling is available
utils.HasIntegratedPfUIStyle = function()
  return ShaguScan.pfui ~= nil
end

-- Get integrated pfUI default colors
utils.GetIntegratedPfUIColors = function()
  if ShaguScan.pfui then
    return {
      background = {r=0.06, g=0.06, b=0.06, a=0.9},
      border = {r=0.2, g=0.2, b=0.2, a=1},
      text = {r=0.8, g=0.8, b=0.8, a=1},
      accent = {r=0.2, g=1, b=0.8, a=1},
      hover = {r=1, g=1, b=1, a=1}
    }
  end
  return utils.GetPfUIColors() -- fallback to existing function
end

ShaguScan.utils = utils
