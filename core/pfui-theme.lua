-- pfUI Theme Integration for ShaguScan
-- Extracted and adapted from pfUI (https://github.com/shagu/pfUI)
-- This provides standalone pfUI-style theming without requiring pfUI addon

if not ShaguScan then ShaguScan = {} end
if not ShaguScan.pfui then ShaguScan.pfui = {} end

local pfui = ShaguScan.pfui

-- pfUI-style configuration (standalone)
pfui.config = {
  appearance = {
    border = {
      background = "0.06,0.06,0.06,0.9",
      color = "0.2,0.2,0.2,1",
      shadow = "1",
      shadow_intensity = "0.4",
      pixelperfect = "1",
      hidpi = "0",
      force_blizz = "0",
      default = "3"
    }
  }
}

-- Cache for optimized operations
pfui.borders = {}
pfui.pixel = nil

-- Media paths for ShaguScan (will point to our own assets)
pfui.media = setmetatable({}, { __index = function(tab,key)
  local value = tostring(key)
  if strfind(value, "img:") then
    value = string.gsub(value, "img:", "Interface\\AddOns\\ShaguScan\\img\\")
  elseif strfind(value, "font:") then
    value = string.gsub(value, "font:", "Interface\\AddOns\\ShaguScan\\fonts\\")
  end
  rawset(tab,key,value)
  return value
end})

-- Backdrop definitions (extracted from pfUI)
pfui.backdrop = {
  bgFile = "Interface\\BUTTONS\\WHITE8X8", tile = false, tileSize = 0,
  edgeFile = "Interface\\BUTTONS\\WHITE8X8", edgeSize = 1,
  insets = {left = -1, right = -1, top = -1, bottom = -1},
}

pfui.backdrop_thin = {
  bgFile = "Interface\\BUTTONS\\WHITE8X8", tile = false, tileSize = 0,
  edgeFile = "Interface\\BUTTONS\\WHITE8X8", edgeSize = 1,
  insets = {left = 0, right = 0, top = 0, bottom = 0},
}

pfui.backdrop_shadow = {
  edgeFile = pfui.media["img:glow2"], edgeSize = 8,
  insets = {left = 0, right = 0, top = 0, bottom = 0},
}

pfui.backdrop_blizz_full = {
  bgFile =  "Interface\\BUTTONS\\WHITE8X8", tile = true, tileSize = 8,
  edgeFile = pfui.media["img:border_blizz"], edgeSize = 6,
  insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

pfui.backdrop_blizz_border = {
  bgFile = nil,
  edgeFile = pfui.media["img:border_blizz"], edgeSize = 6,
  insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

-- Utility Functions (extracted from pfUI API)

-- String split function
function pfui.strsplit(delimiter, subject)
  if not subject then return nil end
  local delim, fields = delimiter or ":", {}
  local pattern = string.format("([^%s]+)", delim)
  string.gsub(subject, pattern, function(c) fields[table.getn(fields)+1] = c end)
  return unpack(fields)
end

-- Round function
function pfui.round(input, places)
  if not places then places = 0 end
  if type(input) == "number" and type(places) == "number" then
    local pow = 1
    for i = 1, places do pow = pow * 10 end
    return floor(input * pow + 0.5) / pow
  end
end

-- Get color values from string
local color_cache = {}
function pfui.GetStringColor(colorstr)
  if not color_cache[colorstr] then
    local r, g, b, a = pfui.strsplit(",", colorstr)
    color_cache[colorstr] = { r, g, b, a }
  end
  return unpack(color_cache[colorstr])
end

-- Get perfect pixel scaling
function pfui.GetPerfectPixel()
  if pfui.pixel then return pfui.pixel end

  if pfui.config.appearance.border.pixelperfect == "1" and GetCVar then
    local scale = GetCVar("uiScale")
    local resolution = GetCVar("gxResolution")
    local _, _, screenwidth, screenheight = strfind(resolution, "(.+)x(.+)")

    pfui.pixel = 768 / screenheight / scale
    pfui.pixel = pfui.pixel > 1 and 1 or pfui.pixel

    -- autodetect and zoom for HiDPI displays
    if pfui.config.appearance.border.hidpi == "1" then
      pfui.pixel = pfui.pixel < .5 and pfui.pixel * 2 or pfui.pixel
    end
  else
    pfui.pixel = .7
  end

  -- Update backdrop definitions with pixel perfect scaling
  pfui.backdrop = {
    bgFile = "Interface\\BUTTONS\\WHITE8X8", tile = false, tileSize = 0,
    edgeFile = "Interface\\BUTTONS\\WHITE8X8", edgeSize = pfui.pixel,
    insets = {left = -pfui.pixel, right = -pfui.pixel, top = -pfui.pixel, bottom = -pfui.pixel},
  }

  pfui.backdrop_thin = {
    bgFile = "Interface\\BUTTONS\\WHITE8X8", tile = false, tileSize = 0,
    edgeFile = "Interface\\BUTTONS\\WHITE8X8", edgeSize = pfui.pixel,
    insets = {left = 0, right = 0, top = 0, bottom = 0},
  }

  return pfui.pixel
end

-- Get border size with pixel scaling
function pfui.GetBorderSize(pref)
  if not pfui.borders then pfui.borders = {} end

  -- set to default border if accessing a wrong border type
  if not pref or not pfui.config.appearance.border[pref] or pfui.config.appearance.border[pref] == "-1" then
    pref = "default"
  end

  if pfui.borders[pref] then
    -- return already cached values
    return pfui.borders[pref][1], pfui.borders[pref][2]
  else
    -- add new borders to the pfui tree
    local raw = tonumber(pfui.config.appearance.border[pref])
    if raw == -1 then raw = 3 end

    local scaled = raw * pfui.GetPerfectPixel()
    pfui.borders[pref] = { raw, scaled }

    return raw, scaled
  end
end

-- Main backdrop creation function (extracted and adapted from pfUI)
function pfui.CreateBackdrop(f, inset, legacy, transp, backdropSetting)
  -- exit if no frame was given
  if not f then return end

  -- load raw and pixel perfect scaled border
  local rawborder, border = pfui.GetBorderSize()

  -- load custom border if existing
  if inset then
    rawborder = inset / pfui.GetPerfectPixel()
    border = inset
  end

  -- detect if blizzard backdrops shall be used
  local blizz = pfui.config.appearance.border.force_blizz == "1" and true or nil
  local backdrop = blizz and pfui.backdrop_blizz_full or rawborder == 1 and pfui.backdrop_thin or pfui.backdrop
  border = blizz and math.max(border, 3) or border

  -- get the color settings
  local br, bg, bb, ba = pfui.GetStringColor(pfui.config.appearance.border.background)
  local er, eg, eb, ea = pfui.GetStringColor(pfui.config.appearance.border.color)

  if transp and transp < tonumber(ba) then ba = transp end

  -- use legacy backdrop handling
  if legacy then
    if backdropSetting then f:SetBackdrop(backdropSetting) end
    f:SetBackdrop(backdrop)
    f:SetBackdropColor(br, bg, bb, ba)
    f:SetBackdropBorderColor(er, eg, eb , ea)
  else
    -- increase clickable area if available
    if f.SetHitRectInsets and ( not InCombatLockdown or not InCombatLockdown()) then
      f:SetHitRectInsets(-border,-border,-border,-border)
    end

    -- use new backdrop behaviour
    if not f.backdrop then
      if f:GetBackdrop() then f:SetBackdrop(nil) end

      local b = CreateFrame("Frame", nil, f)
      local level = f:GetFrameLevel()
      if level < 1 then
        b:SetFrameLevel(level)
      else
        b:SetFrameLevel(level - 1)
      end

      f.backdrop = b
    end

    f.backdrop:SetPoint("TOPLEFT", f, "TOPLEFT", -border, border)
    f.backdrop:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", border, -border)
    f.backdrop:SetBackdrop(backdrop)
    f.backdrop:SetBackdropColor(br, bg, bb, ba)
    f.backdrop:SetBackdropBorderColor(er, eg, eb , ea)

    if blizz then
      if not f.backdrop_border then
        local border_frame = CreateFrame("Frame", nil, f.backdrop)
        border_frame:SetFrameLevel(level + 2)
        f.backdrop_border = border_frame

        local hookSetBackdropBorderColor = f.backdrop.SetBackdropBorderColor
        f.backdrop.SetBackdropBorderColor = function(self, r, g, b, a)
          f.backdrop_border:SetBackdropBorderColor(r, g, b, a)
          hookSetBackdropBorderColor(f.backdrop, r, g, b, a)
        end
      end

      f.backdrop_border:SetAllPoints(f.backdrop)
      f.backdrop_border:SetBackdrop(pfui.backdrop_blizz_border)
      f.backdrop_border:SetBackdropBorderColor(er, eg, eb , ea)
    end
  end
end

-- Shadow creation function (extracted from pfUI)
function pfui.CreateBackdropShadow(f)
  -- exit if no frame was given
  if not f then return end

  if f.backdrop_shadow or pfui.config.appearance.border.shadow ~= "1" then
    return
  end

  local anchor = f.backdrop or f
  f.backdrop_shadow = CreateFrame("Frame", nil, anchor)
  f.backdrop_shadow:SetFrameStrata("BACKGROUND")
  f.backdrop_shadow:SetFrameLevel(1)
  f.backdrop_shadow:SetPoint("TOPLEFT", anchor, "TOPLEFT", -5, 5)
  f.backdrop_shadow:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", 5, -5)
  f.backdrop_shadow:SetBackdrop(pfui.backdrop_shadow)
  f.backdrop_shadow:SetBackdropBorderColor(0, 0, 0, tonumber(pfui.config.appearance.border.shadow_intensity))
end


-- Clean, efficient ShaguScan integration function
function pfui.StyleFrame(frame, config)
  if not frame then return end
  
  -- For health bars, we only want border, no background
  local isHealthBar = frame.bar ~= nil
  
  -- Create temporary pfUI config without affecting global state
  local tempConfig = {
    appearance = {
      border = {
        background = config and config.background_color and not isHealthBar and
          string.format("%.2f,%.2f,%.2f,%.2f", config.background_color.r, config.background_color.g, config.background_color.b, config.background_color.a) or
          (isHealthBar and "0,0,0,0" or "0.06,0.06,0.06,0.9"),
        color = config and config.border_color and
          string.format("%.2f,%.2f,%.2f,%.2f", config.border_color.r, config.border_color.g, config.border_color.b, config.border_color.a) or
          "0.2,0.2,0.2,1",
        shadow = config and config.frame_shadow and "1" or "0",
        shadow_intensity = "0.4",
        pixelperfect = "1",
        hidpi = "0",
        force_blizz = "0",
        default = "3"
      }
    }
  }

  -- Temporarily swap config, apply styling, restore
  local oldConfig = pfui.config
  pfui.config = tempConfig
  
  pfui.CreateBackdrop(frame)
  if tempConfig.appearance.border.shadow == "1" then
    pfui.CreateBackdropShadow(frame)
  end
  
  pfui.config = oldConfig
end

-- Export to ShaguScan namespace
ShaguScan.pfui = pfui