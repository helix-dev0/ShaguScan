if ShaguScan.disabled then return end

local utils = {}

utils.strsplit = function(delimiter, subject)
  if not subject then return nil end
  local delimiter, fields = delimiter or ":", {}
  local pattern = string.format("([^%s]+)", delimiter)
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
  local color = UnitReactionColor[UnitReaction(unitstr, "player")]
  local r, g, b = .8, .8, .8

  if color then
    r, g, b = color.r, color.g, color.b
  end

  return utils.rgbhex(r,g,b), r, g, b
end

utils.GetUnitColor = function(unitstr)
  local r, g, b = .8, .8, .8

  if UnitIsPlayer(unitstr) then
    local _, class = UnitClass(unitstr)

    if RAID_CLASS_COLORS[class] then
      r, g, b = RAID_CLASS_COLORS[class].r, RAID_CLASS_COLORS[class].g, RAID_CLASS_COLORS[class].b
    end
  else
    return utils.GetReactionColor(unitstr)
  end

  return utils.rgbhex(r,g,b), r, g, b
end

utils.GetLevelColor = function(unitstr)
  local color = GetDifficultyColor(UnitLevel(unitstr))
  local r, g, b = .8, .8, .8

  if color then
    r, g, b = color.r, color.g, color.b
  end

  return utils.rgbhex(r,g,b), r, g, b
end

utils.GetLevelString = function(unitstr)
  local level = UnitLevel(unitstr)
  if level == -1 then level = "??" end

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

  return level
end

utils.GetBarColor = function(unitstr, config)
  if config.bar_color_mode == "custom" then
    local c = config.bar_color_custom
    return utils.rgbhex(c.r, c.g, c.b, c.a), c.r, c.g, c.b, c.a
  elseif config.bar_color_mode == "class" then
    return utils.GetUnitColor(unitstr)
  else -- reaction mode (default)
    return utils.GetReactionColor(unitstr)
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
  local current = UnitHealth(unitstr)
  local max = UnitHealthMax(unitstr)
  
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
  local name = UnitName(unitstr)
  
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
  local defaults = {
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

ShaguScan.utils = utils
