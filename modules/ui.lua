if ShaguScan.disabled then return end

local utils = ShaguScan.utils
local filter = ShaguScan.filter
-- Note: settings is loaded after ui, so we access it dynamically

local ui = CreateFrame("Frame", nil, UIParent)

ui.border = {
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 16, edgeSize = 8,
  insets = { left = 2, right = 2, top = 2, bottom = 2 }
}

ui.background = {
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  tile = true, tileSize = 8, edgeSize = 8,
  insets = { left = 0, right = 0, top = 0, bottom = 0 }
}

ui.frames = {}

ui.CreateRoot = function(parent, caption)
  local frame = CreateFrame("Frame", "ShaguScan"..caption, parent)
  frame.id = caption

  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetMovable(true)

  frame:SetScript("OnDragStart", function()
    this.lock = true
    this:StartMoving()
  end)

  frame:SetScript("OnDragStop", function()
    -- load current window config
    local config = ShaguScan_db.config[this.id]

    -- convert to best anchor depending on position
    local new_anchor = utils.GetBestAnchor(this)
    local anchor, x, y = utils.ConvertFrameAnchor(this, new_anchor)
    this:ClearAllPoints()
    this:SetPoint(anchor, UIParent, anchor, x, y)

    -- save new position
    local anchor, _, _, x, y = this:GetPoint()
    config.anchor, config.x, config.y = anchor, x, y

    -- stop drag
    this:StopMovingOrSizing()
    this.lock = false
  end)

  -- assign/initialize elements
  frame.CreateBar = ui.CreateBar
  frame.frames = {}

  -- create title text
  frame.caption = frame:CreateFontString(nil, "HIGH", "GameFontWhite")
  frame.caption:SetFont(STANDARD_TEXT_FONT, 9, "THINOUTLINE")
  frame.caption:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -2)
  frame.caption:SetTextColor(1, 1, 1, 1)
  frame.caption:SetText(caption)

  -- create option button
  frame.settings = CreateFrame("Button", nil, frame)
  frame.settings:SetPoint("RIGHT", frame.caption, "LEFT", -2, 0)
  frame.settings:SetWidth(8)
  frame.settings:SetHeight(8)

  frame.settings:SetScript("OnEnter", function()
    frame.settings.tex:SetAlpha(1)
  end)

  frame.settings:SetScript("OnLeave", function()
    frame.settings.tex:SetAlpha(.5)
  end)

  frame.settings.tex = frame.settings:CreateTexture(nil, 'OVERLAY')
  frame.settings.tex:SetTexture("Interface\\AddOns\\ShaguScan\\img\\config")
  frame.settings.tex:SetAllPoints()
  frame.settings.tex:SetAlpha(.5)

  frame.settings:SetScript("OnClick", function()
    ShaguScan.dialogs.OpenConfig(this:GetParent().id)
  end)

  return frame
end

ui.BarEnter = function()
  if this.border then
    this.border:SetBackdropBorderColor(1, 1, 1, 1)
  end
  this.hover = true

  GameTooltip_SetDefaultAnchor(GameTooltip, this)
  GameTooltip:SetUnit(this.guid)
  GameTooltip:Show()
end

ui.BarLeave = function()
  this.hover = false
  GameTooltip:Hide()
end

ui.BarUpdate = function(elapsed)
  if not elapsed then return end
  -- animate combat text
  CombatFeedback_OnUpdate(elapsed)

  -- update statusbar values
  if this.guid == "test_unit_preview" then
    -- Keep test bar at fixed values
    this.bar:SetMinMaxValues(0, 100)
    this.bar:SetValue(75)
  else
    this.bar:SetMinMaxValues(0, UnitHealthMax(this.guid))
    this.bar:SetValue(UnitHealth(this.guid))
  end

  -- update statusbar texture based on configuration
  if this.config.bar_texture and this.config.bar_texture ~= "" then
    this.bar:SetStatusBarTexture(this.config.bar_texture)
    -- Also update background texture
    if this.bar.bg then
      this.bar.bg:SetTexture(this.config.bar_texture)
    end
  end

  -- update health bar color based on configuration
  local hex, r, g, b, a = utils.GetBarColor(this.guid, this.config)
  this.bar:SetStatusBarColor(r, g, b, this.config.bar_alpha or 1)
  -- Also update frame alpha for better transparency
  this.bar:SetAlpha(this.config.bar_alpha or 1)
  
  -- Debug color
  if ShaguScan_db.global_settings.debug_mode and not this.debug_color_logged then
    if this.guid == "test_unit_preview" then
      DEFAULT_CHAT_FRAME:AddMessage("Color Debug: TEST UNIT PREVIEW - mode=" .. tostring(this.config.bar_color_mode))
      DEFAULT_CHAT_FRAME:AddMessage("  Final Color: r=" .. tostring(r) .. " g=" .. tostring(g) .. " b=" .. tostring(b))
    else
      local isPlayer = UnitIsPlayer(this.guid)
      local _, class = UnitClass(this.guid)
      DEFAULT_CHAT_FRAME:AddMessage("Color Debug: GUID=" .. tostring(this.guid) .. " mode=" .. tostring(this.config.bar_color_mode))
      DEFAULT_CHAT_FRAME:AddMessage("  IsPlayer=" .. tostring(isPlayer) .. " Class=" .. tostring(class))
      DEFAULT_CHAT_FRAME:AddMessage("  Final Color: r=" .. tostring(r) .. " g=" .. tostring(g) .. " b=" .. tostring(b))
    end
    this.debug_color_logged = true
  end
  

  -- update caption text based on configuration
  local text = utils.FormatMainText(this.guid, this.config.text_format, this.config)
  -- Only update text if it has changed (prevents flicker and improves performance)
  if this.text:GetText() ~= text then
    this.text:SetText(text)
  end
  this.text:Show()
  
  -- Update font and color (fixes font change bug)
  local fontPath = utils.GetFontPathFromName(this.config.text_font)
  this.text:SetFont(fontPath, this.config.text_size, this.config.text_outline)
  this.text:SetTextColor(this.config.text_color.r, this.config.text_color.g, this.config.text_color.b, this.config.text_color.a)

  -- update health text if enabled
  if this.config.health_text_enabled and this.health_text then
    local health_text = utils.FormatHealthText(this.guid, this.config.health_text_format)
    this.health_text:SetText(health_text)
    -- update font settings if they have changed
    local fontPath = utils.GetFontPathFromName(this.config.text_font)
    this.health_text:SetFont(fontPath, this.config.text_size, this.config.text_outline)
    this.health_text:Show()
  elseif this.health_text then
    this.health_text:Hide()
  end

  -- update health bar border
  if this.border then
    local border_color = this.config.border_color
    if this.hover then
      this.border:SetBackdropBorderColor(1, 1, 1, 1)
    elseif this.guid ~= "test_unit_preview" and UnitAffectingCombat(this.guid) then
      this.border:SetBackdropBorderColor(.8, .2, .2, 1)
    else
      this.border:SetBackdropBorderColor(border_color.r, border_color.g, border_color.b, border_color.a)
    end
  end

  -- show raid icon if existing (not for players or test units)
  if this.guid ~= "test_unit_preview" and GetRaidTargetIndex(this.guid) and not UnitIsPlayer(this.guid) then
    this.icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    SetRaidTargetIconTexture(this.icon, GetRaidTargetIndex(this.guid))
    this.icon:Show()
  else
    this.icon:Hide()
  end

  -- update target indicator (not for test units)
  if this.guid ~= "test_unit_preview" and UnitExists("target") and UnitIsUnit("target", this.guid) then
    this.target_left:Show()
    this.target_right:Show()
  else
    this.target_left:Hide()
    this.target_right:Hide()
  end
end

ui.BarClick = function()
  -- Don't target test units
  if this.guid == "test_unit_preview" then return end
  TargetUnit(this.guid)
end

ui.BarEvent = function()
  if arg1 ~= this.guid then return end
  CombatFeedback_OnCombatEvent(arg2, arg3, arg4, arg5)
end

ui.CreateBar = function(parent, guid, config)
  local frame = CreateFrame("Button", nil, parent)
  frame.guid = guid
  frame.config = config

  -- assign required events and scripts
  frame:RegisterEvent("UNIT_COMBAT")
  frame:SetScript("OnEvent", ui.BarEvent)
  frame:SetScript("OnClick", ui.BarClick)
  frame:SetScript("OnEnter", ui.BarEnter)
  frame:SetScript("OnLeave", ui.BarLeave)
  frame:SetScript("OnUpdate", ui.BarUpdate)

  -- create health bar using widget factory (replaces 40+ lines of repeated code)
  local bar = ShaguScan.factory.CreateStatusBarWithConfig(frame, config, guid)
  -- Handle test units differently
  if guid == "test_unit_preview" then
    bar:SetMinMaxValues(0, 100)
    bar:SetValue(75)
  else
    bar:SetMinMaxValues(0, UnitHealthMax(guid) or 100)
    bar:SetValue(UnitHealth(guid) or 100)
  end
  bar:SetAllPoints()
  
  -- Set initial color based on unit
  local hex, r, g, b, a = utils.GetBarColor(guid, config)
  bar:SetStatusBarColor(r, g, b, config.bar_alpha or 1)
  frame.bar = bar

  -- create caption text
  local text = frame.bar:CreateFontString(nil, "OVERLAY", "GameFontWhite")
  local fontPath = utils.GetFontPathFromName(config.text_font)
  text:SetFont(fontPath, config.text_size, config.text_outline)
  text:SetTextColor(config.text_color.r, config.text_color.g, config.text_color.b, config.text_color.a)
  
  -- position text based on configuration
  if config.text_position == "center" then
    text:SetPoint("CENTER", bar, "CENTER", 0, 0)
    text:SetJustifyH("CENTER")
  elseif config.text_position == "right" then
    text:SetPoint("RIGHT", bar, "RIGHT", -2, 0)
    text:SetJustifyH("RIGHT")
  else -- left (default)
    text:SetPoint("LEFT", bar, "LEFT", 2, 0)
    text:SetJustifyH("LEFT")
  end
  frame.text = text
  
  -- Set initial text and color
  local initialText = utils.FormatMainText(guid, config.text_format, config)
  text:SetText(initialText)
  text:SetTextColor(config.text_color.r, config.text_color.g, config.text_color.b, config.text_color.a)

  -- create health text if enabled
  if config.health_text_enabled then
    local health_text = frame.bar:CreateFontString(nil, "OVERLAY", "GameFontWhite")
    local fontPath = utils.GetFontPathFromName(config.text_font)
    health_text:SetFont(fontPath, config.text_size, config.text_outline)
    health_text:SetTextColor(config.text_color.r, config.text_color.g, config.text_color.b, config.text_color.a)
    
    -- position health text based on configuration
    if config.health_text_position == "center" then
      health_text:SetPoint("CENTER", bar, "CENTER", 0, 0)
      health_text:SetJustifyH("CENTER")
    elseif config.health_text_position == "left" then
      health_text:SetPoint("LEFT", bar, "LEFT", 2, 0)
      health_text:SetJustifyH("LEFT")
    else -- right (default)
      health_text:SetPoint("RIGHT", bar, "RIGHT", -2, 0)
      health_text:SetJustifyH("RIGHT")
    end
    frame.health_text = health_text
  end

  -- create combat feedback text
  local feedback = bar:CreateFontString(guid.."feedback"..GetTime(), "OVERLAY", "NumberFontNormalHuge")
  feedback:SetAlpha(.8)
  feedback:SetFont(DAMAGE_TEXT_FONT, 12, "OUTLINE")
  feedback:SetParent(bar)
  feedback:ClearAllPoints()
  feedback:SetPoint("CENTER", bar, "CENTER", 0, 0)

  frame.feedbackFontHeight = 14
  frame.feedbackStartTime = GetTime()
  frame.feedbackText = feedback

  -- create raid icon textures
  local icon = bar:CreateTexture(nil, "OVERLAY")
  icon:SetWidth(16)
  icon:SetHeight(16)
  icon:SetPoint("RIGHT", frame, "RIGHT", -2, 0)
  -- Don't set texture here - only set it when showing the icon
  icon:Hide()
  frame.icon = icon

  -- create target indicator
  local target_left = bar:CreateTexture(nil, "OVERLAY")
  target_left:SetWidth(8)
  target_left:SetHeight(8)
  target_left:SetPoint("LEFT", frame, "LEFT", -4, 0)
  target_left:SetTexture("Interface\\AddOns\\ShaguScan\\img\\target-left")
  target_left:Hide()
  frame.target_left = target_left

  local target_right = bar:CreateTexture(nil, "OVERLAY")
  target_right:SetWidth(8)
  target_right:SetHeight(8)
  target_right:SetPoint("RIGHT", frame, "RIGHT", 4, 0)
  target_right:SetTexture("Interface\\AddOns\\ShaguScan\\img\\target-right")
  target_right:Hide()
  frame.target_right = target_right

  -- Create border backdrop (no background for health bars)
  local backdrop = utils.GetBorderBackdrop(config)
  if backdrop then
    frame:SetBackdrop(backdrop)
    frame:SetBackdropBorderColor(config.border_color.r, config.border_color.g, config.border_color.b, config.border_color.a)
  end
  frame.border = frame

  -- Shadow is now handled by integrated pfUI styling system
  
  -- create frame glow if enabled (apply to bar frame for proper positioning)
  frame.glow = utils and utils.CreateFrameGlow and utils.CreateFrameGlow(frame.bar, config)

  return frame
end

ui:SetAllPoints()
ui:Show()

ui:SetScript("OnUpdate", function()
  if (this.tick or 1) > GetTime() then return else this.tick = GetTime() + .1 end

  -- cleanup old GUIDs for better performance
  if ShaguScan.core and ShaguScan.core.cleanup then
    ShaguScan.core.cleanup()
  end

  -- remove old leftover frames
  for caption, root in pairs(ui.frames) do
    if not ShaguScan_db.config[caption] then
      ui.frames[caption]:Hide()
      ui.frames[caption] = nil
    end
  end

  -- create ui frames based on config values
  for caption, config in pairs(ShaguScan_db.config) do
    -- ensure config has all required fields for backward compatibility
    config = utils.MergeConfigDefaults(config)
    
    -- create root frame if not existing
    ui.frames[caption] = ui.frames[caption] or ui.CreateRoot(UIParent, caption)
    local root = ui.frames[caption]

    -- skip if locked (due to moving)
    if not root.lock then

    -- update position based on config
    local posKey = config.anchor .. "_" .. config.x .. "_" .. config.y .. "_" .. config.scale
    if not root.pos or root.pos ~= posKey then
      root.pos = posKey
      root:ClearAllPoints()
      root:SetPoint(config.anchor, config.x, config.y)
      root:SetScale(config.scale)
    end

    -- update filter if required
    if not root.filter_conf or root.filter_conf ~= config.filter then
      root.filter = {}

      -- prepare all filter texts
      local filter_texts = { utils.strsplit(',', config.filter) }
      for id, filter_text in pairs(filter_texts) do
        local name, args = utils.strsplit(':', filter_text)
        root.filter[name] = args or true
      end

      -- mark current state of data
      root.filter_conf = config.filter
    end

    -- run through all guids and fill with bars
    local title_size = 12 + config.spacing
    local width, height = config.width, config.height + title_size
    local x, y, count = 0, 0, 0
    for guid, time in pairs(ShaguScan.core.guids) do
      -- apply filters with short-circuiting
      local visible = true
      for name, args in pairs(root.filter) do
        if filter[name] and not filter[name](guid, args) then
          visible = false
          break -- Exit immediately on first failed filter
        end
      end

      -- display element if filters allow it
      if UnitExists(guid) and visible then
        count = count + 1

        if count > config.maxrow then
          count, x = 1, x + config.width + config.spacing
          width = math.max(x + config.width, width)
        end

        y = (count-1) * (config.height + config.spacing) + title_size
        height = math.max(y + config.height + config.spacing, height)

        root.frames[guid] = root.frames[guid] or ui.CreateBar(root, guid, config)
        
        -- update frame config reference if it exists
        if root.frames[guid] then
          root.frames[guid].config = config
          -- Force texture update if statusbar texture has changed
          if root.frames[guid].bar and config.bar_texture then
            root.frames[guid].bar:SetStatusBarTexture(config.bar_texture)
          end
        end

        -- update position if required
        local framePos = x .. "_" .. (-y)
        if not root.frames[guid].pos or root.frames[guid].pos ~= framePos then
          root.frames[guid]:ClearAllPoints()
          root.frames[guid]:SetPoint("TOPLEFT", root, "TOPLEFT", x, -y)
          root.frames[guid].pos = framePos
        end

        -- update sizes if required
        local sizeKey = config.width .. "_" .. config.height
        if not root.frames[guid].sizes or root.frames[guid].sizes ~= sizeKey then
          root.frames[guid]:SetWidth(config.width)
          root.frames[guid]:SetHeight(config.height)
          root.frames[guid].sizes = sizeKey
        end

        root.frames[guid]:Show()
      elseif root.frames[guid] then
        root.frames[guid]:Hide()
        root.frames[guid] = nil
      end
    end

    -- update caption visibility based on global setting and unit count
    if root.caption then
      local global_config = ShaguScan_db.global_settings or {}
      -- Ensure global settings have all defaults
      if utils and utils.MergeGlobalDefaults then
        global_config = utils.MergeGlobalDefaults(global_config)
      end
      
      -- Store unit count for reference
      root.unit_count = count
      
      if global_config.hide_window_headers then
        -- Show header only when there are units found OR settings window is open
        if count > 0 or ui.IsSettingsWindowOpen() then
          root.caption:Show()
          root.settings:Show()
        else
          root.caption:Hide()
          root.settings:Hide()
        end
      else
        -- Always show header when setting is disabled
        root.caption:Show()
        root.settings:Show()
      end
    end

    -- update window size
    root:SetWidth(width)
    root:SetHeight(height)
    
    end -- end of else block (not locked)
  end
end)

-- Function to check if any settings window is open
ui.IsSettingsWindowOpen = function()
  -- Check if main /scan window is open
  local mainWindow = getglobal("ShaguScanMainWindow")
  if mainWindow and mainWindow:IsVisible() then
    return true
  end
  
  -- Check if main settings dialog is open
  local mainDialog = getglobal("ShaguScanMainConfigDialog")
  if mainDialog and mainDialog:IsVisible() then
    return true
  end
  
  -- Check if any individual window config dialogs are open
  for caption, _ in pairs(ShaguScan_db.config or {}) do
    local dialogName = "ShaguScanConfigDialog" .. caption
    local dialog = getglobal(dialogName)
    if dialog and dialog:IsVisible() then
      return true
    end
  end
  
  return false
end

-- Function to manually update header visibility for all windows
ui.UpdateHeaderVisibility = function()
  if not ui.frames then return end
  
  local global_config = ShaguScan_db.global_settings or {}
  if utils and utils.MergeGlobalDefaults then
    global_config = utils.MergeGlobalDefaults(global_config)
  end
  
  for caption, root in pairs(ui.frames) do
    if root.caption then
      local count = root.unit_count or 0
      
      if global_config.hide_window_headers then
        -- Show header only when there are units found OR settings window is open
        if count > 0 or ui.IsSettingsWindowOpen() then
          root.caption:Show()
          root.settings:Show()
        else
          root.caption:Hide()
          root.settings:Hide()
        end
      else
        -- Always show header when setting is disabled
        root.caption:Show()
        root.settings:Show()
      end
    end
  end
end

ShaguScan.ui = ui
