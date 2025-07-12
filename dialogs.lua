-- dialogs.lua - Individual window configuration dialogs
-- Extracted from settings.lua to reduce file size

local dialogs = {}

-- Export the module immediately for proper loading order
ShaguScan.dialogs = dialogs

-- References to other modules
local utils = ShaguScan.utils
local widgets = ShaguScan.widgets

dialogs.OpenConfig = function(caption)
  -- Check if addon is disabled
  if ShaguScan.disabled then
    DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00Shagu|cffffffffScan:|cffffaaaa Addon is disabled (SuperWoW not detected)")
    return
  end

  -- Safety check for nil caption
  if not caption or caption == "" then
    DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00Shagu|cffffffffScan:|cffffaaaa Error: Invalid window name!")
    return
  end
  
  -- Toggle Existing Dialog
  local existing = getglobal("ShaguScanConfigDialog"..caption)
  if existing then
    if existing:IsShown() then existing:Hide() else existing:Show() end
    return
  end

  -- Ensure ShaguScan_db.config exists
  if not ShaguScan_db.config then
    ShaguScan_db.config = {}
  end

  -- Create defconfig if new config
  if not ShaguScan_db.config[caption] then
    -- Get template from global settings
    local template = ShaguScan_db.global_settings and ShaguScan_db.global_settings.default_template or {}
    
    -- Create new config with template values
    ShaguScan_db.config[caption] = {
      filter = "npc,infight,alive",
      scale = 1, anchor = "LEFT", x = 50, y = 0, width = 75, height = 12, spacing = 4, maxrow = 20,
      -- Display customization options from template
      bar_texture = template.bar_texture or "Interface\\TargetingFrame\\UI-StatusBar",
      bar_color_mode = template.bar_color_mode or "reaction",
      bar_color_custom = utils.DeepCopy(template.bar_color_custom) or {r=1, g=0.8, b=0.2, a=1},
      bar_alpha = template.bar_alpha or 1.0,
      background_alpha = template.background_alpha or 0.8,
      background_color = utils.DeepCopy(template.background_color) or {r=0, g=0, b=0, a=1},
      background_texture = template.background_texture or "default",
      border_style = template.border_style or "default",
      border_color = utils.DeepCopy(template.border_color) or {r=0.2, g=0.2, b=0.2, a=1},
      text_font = template.text_font or utils.GetDefaultPfUIFont(),
      text_size = template.text_size or 9,
      text_outline = template.text_outline or "THINOUTLINE",
      text_position = template.text_position or "left",
      text_format = template.text_format or "level_name",
      text_color = utils.DeepCopy(template.text_color) or {r=1, g=1, b=1, a=1},
      health_text_enabled = template.health_text_enabled or false,
      health_text_position = template.health_text_position or "right",
      health_text_format = template.health_text_format or "percent",
      frame_shadow = template.frame_shadow or false,
      frame_glow = template.frame_glow or false
    }
  end

  -- Ensure config exists
  if not ShaguScan_db.config[caption] then
    DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00Shagu|cffffffffScan:|cffffaaaa Error: Config not found for window '" .. caption .. "'")
    return
  end

  -- Save Shortcuts and ensure config has all defaults for backward compatibility
  local config = ShaguScan_db.config[caption]
  if config and utils and utils.MergeConfigDefaults then
    config = utils.MergeConfigDefaults(config)
    ShaguScan_db.config[caption] = config  -- Update the stored config with defaults
  end

  -- Create dialog using widget factory (consolidates backdrop creation)
  local dialog = ShaguScan.factory.CreateDialog("ShaguScan Configuration: " .. caption, 420, 620, true, "ShaguScanConfigDialog"..caption)
  table.insert(UISpecialFrames, "ShaguScanConfigDialog"..caption)
  
  dialog:SetFrameStrata("FULLSCREEN_DIALOG")
  dialog:SetFrameLevel(100)

  -- Create scroll frame for content
  local scrollFrame = CreateFrame("ScrollFrame", nil, dialog)
  scrollFrame:SetPoint("TOPLEFT", dialog, "TOPLEFT", 8, -40)
  scrollFrame:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -25, 40) -- Leave space for scroll bar
  
  -- Create scroll child (content container)
  local scrollChild = CreateFrame("Frame", nil, scrollFrame)
  scrollChild:SetWidth(1) -- Will be set dynamically based on scroll frame
  scrollChild:SetHeight(800) -- Initial height - will be set dynamically
  scrollChild:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, 0)
  scrollFrame:SetScrollChild(scrollChild)
  
  -- Update scroll child width to match scroll frame width
  local function UpdateScrollChildSize()
    local scrollFrameWidth = scrollFrame:GetWidth()
    if scrollFrameWidth and scrollFrameWidth > 0 then
      scrollChild:SetWidth(scrollFrameWidth)
      -- Also update backdrop width to match (defined later)
      if backdrop then
        backdrop:SetWidth(scrollFrameWidth)
      end
    end
  end
  
  -- Set up proper width on creation and when resized
  scrollFrame:SetScript("OnSizeChanged", function()
    UpdateScrollChildSize()
  end)
  
  -- Initial width update
  UpdateScrollChildSize()
  
  -- Create scroll bar
  local scrollBar = CreateFrame("Slider", nil, scrollFrame)
  scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 5, 0)
  scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 5, 0)
  scrollBar:SetWidth(15)
  scrollBar:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 8,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
  })
  scrollBar:SetBackdropColor(0, 0, 0, 0.5)
  scrollBar:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
  scrollBar:SetOrientation("VERTICAL")
  scrollBar:SetMinMaxValues(0, 1)
  scrollBar:SetValue(0)
  scrollBar:SetValueStep(1)
  
  -- Create scroll bar thumb
  scrollBar.thumb = scrollBar:CreateTexture(nil, "OVERLAY")
  scrollBar.thumb:SetTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
  scrollBar.thumb:SetWidth(15)
  scrollBar.thumb:SetHeight(20)
  scrollBar:SetThumbTexture(scrollBar.thumb)
  
  scrollBar:SetScript("OnValueChanged", function()
    scrollFrame:SetVerticalScroll(this:GetValue())
  end)
  
  -- Enable mouse wheel scrolling (pfUI-style)
  scrollFrame:EnableMouseWheel(true)
  scrollFrame:SetScript("OnMouseWheel", function()
    local current = scrollBar:GetValue()
    local minVal, maxVal = scrollBar:GetMinMaxValues()
    local step = 20 -- Scroll step size
    
    if arg1 > 0 then
      -- Scroll up
      scrollBar:SetValue(math.max(minVal, current - step))
    else
      -- Scroll down  
      scrollBar:SetValue(math.min(maxVal, current + step))
    end
  end)

  -- Assign functions to dialog
  dialog.CreateTextBox = widgets.CreateTextBox
  dialog.CreateLabel = widgets.CreateLabel
  dialog.CreateDropdown = widgets.CreateDropdown
  dialog.CreateFontDropdown = widgets.CreateFontDropdown

  -- Save & Reload
  dialog.save = CreateFrame("Button", nil, dialog, "GameMenuButtonTemplate")
  dialog.save:SetWidth(110)
  dialog.save:SetHeight(22)
  dialog.save:SetFont(STANDARD_TEXT_FONT, 11)
  dialog.save:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -12, 12)
  dialog.save:SetText("Save Changes")
  dialog.save:SetScript("OnClick", function()
    local new_caption = dialog.caption:GetText()
    
    -- Validate caption
    if not new_caption or new_caption == "" then
      DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00Shagu|cffffffffScan:|cffffaaaa Error: Window name cannot be empty!")
      return
    end

    local filter = dialog.filter:GetText()
    local width = dialog.width:GetText()
    local height = dialog.height:GetText()
    local spacing = dialog.spacing:GetText()
    local maxrow = dialog.maxrow:GetText()
    local anchor = dialog.anchor:GetText()
    local scale = dialog.scale:GetText()
    local x = dialog.x:GetText()
    local y = dialog.y:GetText()

    -- New display options (with safe fallbacks)
    local bar_color_mode = (dialog.bar_color_mode and dialog.bar_color_mode.GetValue) and dialog.bar_color_mode.GetValue() or "reaction"
    local bar_texture = (dialog.bar_texture and dialog.bar_texture.GetTexturePath) and dialog.bar_texture.GetTexturePath() or "Interface\\TargetingFrame\\UI-StatusBar"
    local bar_alpha = dialog.bar_alpha:GetText()
    local background_texture = (dialog.background_texture and dialog.background_texture.GetValue) and dialog.background_texture.GetValue() or "default"
    local border_style = (dialog.border_style and dialog.border_style.GetValue) and dialog.border_style.GetValue() or "default"
    local text_position = (dialog.text_position and dialog.text_position.GetValue) and dialog.text_position.GetValue() or "left"
    local text_format = (dialog.text_format and dialog.text_format.GetValue) and dialog.text_format.GetValue() or "level_name"
    local text_size = dialog.text_size:GetText()
    local text_font = (dialog.text_font and dialog.text_font.GetFontPath) and dialog.text_font.GetFontPath() or utils.GetDefaultPfUIFont()
    local text_outline = (dialog.text_outline and dialog.text_outline.GetValue) and dialog.text_outline.GetValue() or "THINOUTLINE"
    local health_text_enabled = (dialog.health_text_enabled and dialog.health_text_enabled.GetValue) and dialog.health_text_enabled.GetValue() or "false"
    local health_text_format = (dialog.health_text_format and dialog.health_text_format.GetValue) and dialog.health_text_format.GetValue() or "percent"
    local health_text_position = (dialog.health_text_position and dialog.health_text_position.GetValue) and dialog.health_text_position.GetValue() or "right"
    local frame_shadow = (dialog.frame_shadow and dialog.frame_shadow.GetValue) and dialog.frame_shadow.GetValue() or "false"

    -- build new config
    local new_config = {
      filter = filter,
      width = tonumber(width) or config.width,
      height = tonumber(height) or config.height,
      spacing = tonumber(spacing) or config.spacing,
      maxrow = tonumber(maxrow) or config.maxrow,
      anchor = utils.IsValidAnchor(anchor) and anchor or config.anchor,
      scale = tonumber(scale) or config.scale,
      x = tonumber(x) or config.x,
      y = tonumber(y) or config.y,
      -- Display customization options
      bar_texture = bar_texture or config.bar_texture,
      bar_color_mode = bar_color_mode or config.bar_color_mode,
      bar_color_custom = config.bar_color_custom,
      bar_alpha = tonumber(bar_alpha) or config.bar_alpha,
      background_alpha = config.background_alpha,
      background_color = config.background_color,
      background_texture = background_texture or config.background_texture,
      border_style = border_style or config.border_style,
      border_color = config.border_color,
      text_font = text_font or config.text_font,
      text_size = tonumber(text_size) or config.text_size,
      text_outline = text_outline or config.text_outline,
      text_position = text_position or config.text_position,
      text_format = text_format or config.text_format,
      text_color = config.text_color,
      health_text_enabled = health_text_enabled == "true" or false,
      health_text_position = health_text_position or config.health_text_position,
      health_text_format = health_text_format or config.health_text_format,
      frame_shadow = frame_shadow == "true" or false,
      frame_glow = config.frame_glow
    }

    -- Handle window renaming
    if caption ~= new_caption then
      -- Check if new name already exists (and it's not the current window)
      if ShaguScan_db.config[new_caption] and ShaguScan_db.config[new_caption] ~= ShaguScan_db.config[caption] then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00Shagu|cffffffffScan:|cffffaaaa Error: Window '" .. new_caption .. "' already exists!")
        return
      end
      -- Delete old config only after successful validation
      ShaguScan_db.config[caption] = nil
    end
    
    -- Save the new/updated config
    ShaguScan_db.config[new_caption] = new_config
    
    -- Update test bar if it's currently visible
    if ShaguScan.testbars and ShaguScan.testbars.UpdateTestBar then
      ShaguScan.testbars.UpdateTestBar(new_config, new_caption)
    end
    
    -- Force refresh all real unit bars for this window
    if ShaguScan.ui and ShaguScan.ui.frames and ShaguScan.ui.frames[new_caption] then
      local root = ShaguScan.ui.frames[new_caption]
      for guid, frame in pairs(root.frames or {}) do
        if frame.config and frame.bar then
          frame.config = new_config
          
          -- Force texture update
          -- Apply all configuration changes using unified settings updater
          -- This replaces 110+ lines of repeated update code with pfUI-style modular updates
          if ShaguScan and ShaguScan.updater and ShaguScan.updater.ApplyConfigToFrame then
            ShaguScan.updater.ApplyConfigToFrame(frame, new_config)
          else
            -- Fallback to basic frame update if updater not available
            frame.config = new_config
            if frame.OnUpdate then
              frame.OnUpdate()
            end
          end
        end
      end
    end
    
    -- Success message
    DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00Shagu|cffffffffScan:|cffffffff Window '" .. new_caption .. "' saved successfully!")
    
    -- Refresh the main window list if it's open
    local mainWindow = getglobal("ShaguScanMainWindow")
    if mainWindow and mainWindow:IsShown() and mainWindow.panel1 then
      if ShaguScan.mainpanel and ShaguScan.mainpanel.RefreshWindowList then
        ShaguScan.mainpanel.RefreshWindowList(mainWindow.panel1)
      end
    end
    
    -- Don't close the dialog after saving - user can use X button to close
  end)

  -- Delete
  dialog.delete = CreateFrame("Button", nil, dialog, "GameMenuButtonTemplate")
  dialog.delete:SetWidth(80)
  dialog.delete:SetHeight(18)
  dialog.delete:SetFont(STANDARD_TEXT_FONT, 9)
  dialog.delete:SetPoint("BOTTOMLEFT", dialog, "BOTTOMLEFT", 12, 12)
  dialog.delete:SetText("Delete")
  
  -- Make delete button less prominent (grayed out style)
  dialog.delete:GetFontString():SetTextColor(0.7, 0.7, 0.7, 1)
  
  dialog.delete:SetScript("OnClick", function()
    -- Add confirmation dialog for better UX
    if dialog.deleteConfirm then
      -- Second click - actually delete
      ShaguScan_db.config[caption] = nil
      
      -- Refresh the main window list if it's open
      local mainWindow = getglobal("ShaguScanMainWindow")
      if mainWindow and mainWindow:IsShown() and mainWindow.panel1 then
        if ShaguScan.mainpanel and ShaguScan.mainpanel.RefreshWindowList then
          ShaguScan.mainpanel.RefreshWindowList(mainWindow.panel1)
        end
      end
      
      this:GetParent():Hide()
      DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00Shagu|cffffffffScan:|cffffaaaa Window '" .. caption .. "' deleted!")
    else
      -- First click - ask for confirmation
      dialog.deleteConfirm = true
      dialog.delete:SetText("Confirm Delete")
      dialog.delete:GetFontString():SetTextColor(1, 0.3, 0.3, 1) -- Red warning color
      
      -- Reset after 3 seconds using frame timer (WoW 1.12 compatible)
      dialog.deleteResetTime = GetTime() + 3
      
      if not dialog.deleteTimer then
        dialog.deleteTimer = CreateFrame("Frame")
        dialog.deleteTimer:SetScript("OnUpdate", function()
          if dialog.deleteResetTime and GetTime() >= dialog.deleteResetTime then
            dialog.deleteConfirm = nil
            dialog.deleteResetTime = nil
            dialog.delete:SetText("Delete")
            dialog.delete:GetFontString():SetTextColor(0.7, 0.7, 0.7, 1)
            this:SetScript("OnUpdate", nil) -- Stop timer
          end
        end)
      else
        -- Restart existing timer
        dialog.deleteTimer:SetScript("OnUpdate", function()
          if dialog.deleteResetTime and GetTime() >= dialog.deleteResetTime then
            dialog.deleteConfirm = nil
            dialog.deleteResetTime = nil
            dialog.delete:SetText("Delete")
            dialog.delete:GetFontString():SetTextColor(0.7, 0.7, 0.7, 1)
            this:SetScript("OnUpdate", nil) -- Stop timer
          end
        end)
      end
    end
  end)

  dialog.close = CreateFrame("Button", nil, dialog, "UIPanelCloseButton")
  dialog.close:SetWidth(20)
  dialog.close:SetHeight(20)
  dialog.close:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", 0, 0)
  dialog.close:SetScript("OnClick", function()
    this:GetParent():Hide()
  end)

  -- Caption (Title)
  dialog.caption = dialog:CreateTextBox(caption)
  dialog.caption:SetPoint("TOPLEFT", dialog, "TOPLEFT", 8, -18)
  dialog.caption:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -8, -18)
  dialog.caption:SetFont(STANDARD_TEXT_FONT, 10)
  dialog.caption:SetJustifyH("CENTER")
  dialog.caption:SetHeight(20)

  -- Backdrop (now inside scroll frame)
  local backdrop = CreateFrame("Frame", nil, scrollChild)
  backdrop:SetBackdrop(widgets.backdrop)
  backdrop:SetBackdropBorderColor(.2,.2,.2,1)
  backdrop:SetBackdropColor(.2,.2,.2,1)

  backdrop:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, 0)
  backdrop:SetWidth(1) -- Will be set dynamically
  backdrop:SetHeight(800) -- Initial height - will be adjusted dynamically

  backdrop.CreateTextBox = widgets.CreateTextBox
  backdrop.CreateLabel = widgets.CreateLabel
  backdrop.CreateSectionHeader = widgets.CreateSectionHeader
  backdrop.CreateDropdown = widgets.CreateDropdown
  backdrop.CreateFontDropdown = widgets.CreateFontDropdown
  backdrop.CreateStatusbarDropdown = widgets.CreateStatusbarDropdown

  backdrop.pos = 8
  
  -- Define consistent column positions for better alignment
  local LABEL_COL = 10    -- Label column position
  local INPUT_COL = 90    -- Input field column position (increased for better alignment)
  local SPACING = 18      -- Standard row spacing

  -- === BASIC SETTINGS SECTION ===
  local header1 = backdrop:CreateSectionHeader("Basic Settings")
  header1:SetPoint("TOPLEFT", backdrop, LABEL_COL, -backdrop.pos)
  backdrop.pos = backdrop.pos + 22

  -- Filter
  local label = backdrop:CreateLabel("Filter:")
  label:SetPoint("TOPLEFT", backdrop, LABEL_COL, -backdrop.pos)

  dialog.filter = backdrop:CreateTextBox(config.filter or "")
  dialog.filter:SetPoint("TOPLEFT", backdrop, "TOPLEFT", INPUT_COL, -backdrop.pos)
  dialog.filter:SetWidth(250)
  dialog.filter:SetScript("OnEnter", function()
    dialog.filter:ShowTooltip({
      "Unit Filters",
      "|cffaaaaaaA comma separated list of filters.",
      " ",
      { "|cffffffffplayer", "Player Characters" },
      { "|cffffffffnpc", "NPC Units" },
      { "|cffffffffinfight", "Infight Units" },
      { "|cffffffffdead", "Dead Units" },
      { "|cffffffffalive", "Living Units" },
      { "|cffffffffhorde", "Horde Units" },
      { "|cffffffffalliance", "Alliance Units" },
      { "|cffffffffhardcore", "Hardcore Players" },
      { "|cffffffffpve", "PvE Units" },
      { "|cffffffffpvp", "PvP Enabled Units" },
      { "|cfffffffficon", "Units With Raid Icons" },
      " ",
      "|cffffffffA complete list of filters can be found in the README."
    })
  end)

  dialog.filter:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  backdrop.pos = backdrop.pos + SPACING

  -- Spacer
  backdrop.pos = backdrop.pos + 9

  -- Width
  local label = backdrop:CreateLabel("Width:")
  label:SetPoint("TOPLEFT", backdrop, LABEL_COL, -backdrop.pos)

  dialog.width = backdrop:CreateTextBox(config.width or 75)
  dialog.width:SetPoint("TOPLEFT", backdrop, "TOPLEFT", INPUT_COL, -backdrop.pos)
  dialog.width:SetWidth(80)
  dialog.width:SetScript("OnEnter", function()
    dialog.width:ShowTooltip({
      "Health Bar Width",
      "|cffaaaaaaAn Integer Value in Pixels"
    })
  end)

  dialog.width:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  backdrop.pos = backdrop.pos + SPACING

  -- Height
  local label = backdrop:CreateLabel("Height:")
  label:SetPoint("TOPLEFT", backdrop, LABEL_COL, -backdrop.pos)

  dialog.height = backdrop:CreateTextBox(config.height or 12)
  dialog.height:SetPoint("TOPLEFT", backdrop, "TOPLEFT", INPUT_COL, -backdrop.pos)
  dialog.height:SetWidth(80)
  dialog.height:SetScript("OnEnter", function()
    dialog.height:ShowTooltip({
      "Health Bar Height",
      "|cffaaaaaaAn Integer Value in Pixels"
    })
  end)

  dialog.height:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  backdrop.pos = backdrop.pos + SPACING

  -- Spacing
  local label = backdrop:CreateLabel("Spacing:")
  label:SetPoint("TOPLEFT", backdrop, LABEL_COL, -backdrop.pos)

  dialog.spacing = backdrop:CreateTextBox(config.spacing or 4)
  dialog.spacing:SetPoint("TOPLEFT", backdrop, "TOPLEFT", INPUT_COL, -backdrop.pos)
  dialog.spacing:SetWidth(80)
  dialog.spacing:SetScript("OnEnter", function()
    dialog.spacing:ShowTooltip({
      "Spacing Between Health Bars",
      "|cffaaaaaaAn Integer Value in Pixels"
    })
  end)

  dialog.spacing:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  backdrop.pos = backdrop.pos + SPACING

  -- Max per Row
  local label = backdrop:CreateLabel("Max-Row:")
  label:SetPoint("TOPLEFT", backdrop, LABEL_COL, -backdrop.pos)

  dialog.maxrow = backdrop:CreateTextBox(config.maxrow or 20)
  dialog.maxrow:SetPoint("TOPLEFT", backdrop, "TOPLEFT", INPUT_COL, -backdrop.pos)
  dialog.maxrow:SetWidth(80)
  dialog.maxrow:SetScript("OnEnter", function()
    dialog.maxrow:ShowTooltip({
      "Maximum Entries Per Column",
      "|cffaaaaaaA new column will be created once exceeded"
    })
  end)

  dialog.maxrow:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  backdrop.pos = backdrop.pos + 18

  -- === LAYOUT & POSITIONING SECTION ===
  backdrop.pos = backdrop.pos + 15
  local header2 = backdrop:CreateSectionHeader("Layout & Positioning")
  header2:SetPoint("TOPLEFT", backdrop, LABEL_COL, -backdrop.pos)
  backdrop.pos = backdrop.pos + 22

  -- Anchor
  local label = backdrop:CreateLabel("Anchor:")
  label:SetPoint("TOPLEFT", backdrop, LABEL_COL, -backdrop.pos)

  dialog.anchor = backdrop:CreateTextBox(config.anchor or "CENTER")
  dialog.anchor:SetPoint("TOPLEFT", backdrop, "TOPLEFT", INPUT_COL, -backdrop.pos)
  dialog.anchor:SetWidth(120)
  dialog.anchor:SetScript("OnEnter", function()
    dialog.anchor:ShowTooltip({
      "Window Anchor",
      "|cffaaaaaaThe Anchor From Where Positions Are Calculated.",
      " ",
      {"TOP", "TOPLEFT"},
      {"TOPRIGHT", "CENTER"},
      {"LEFT", "RIGHT"},
      {"BOTTOM", "BOTTOMLEFT"},
      {"BOTTOMRIGHT", ""}
    })
  end)

  dialog.anchor:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  backdrop.pos = backdrop.pos + SPACING

  -- Scale
  local label = backdrop:CreateLabel("Scale:")
  label:SetPoint("TOPLEFT", backdrop, LABEL_COL, -backdrop.pos)

  dialog.scale = backdrop:CreateTextBox(utils.round(config.scale, 2))
  dialog.scale:SetPoint("TOPLEFT", backdrop, "TOPLEFT", INPUT_COL, -backdrop.pos)
  dialog.scale:SetWidth(80)
  dialog.scale:SetScript("OnEnter", function()
    dialog.scale:ShowTooltip({
      "Window Scale",
      "|cffaaaaaaA floating point number, 1 equals 100%"
    })
  end)

  dialog.scale:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  backdrop.pos = backdrop.pos + SPACING

  -- Position-X
  local label = backdrop:CreateLabel("X-Position:")
  label:SetPoint("TOPLEFT", backdrop, LABEL_COL, -backdrop.pos)

  dialog.x = backdrop:CreateTextBox(utils.round(config.x, 2))
  dialog.x:SetPoint("TOPLEFT", backdrop, "TOPLEFT", INPUT_COL, -backdrop.pos)
  dialog.x:SetWidth(80)
  dialog.x:SetScript("OnEnter", function()
    dialog.x:ShowTooltip({
      "X-Position of Window",
      "|cffaaaaaaA Number in Pixels"
    })
  end)

  dialog.x:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  backdrop.pos = backdrop.pos + SPACING

  -- Position-Y
  local label = backdrop:CreateLabel("Y-Position:")
  label:SetPoint("TOPLEFT", backdrop, LABEL_COL, -backdrop.pos)

  dialog.y = backdrop:CreateTextBox(utils.round(config.y, 2))
  dialog.y:SetPoint("TOPLEFT", backdrop, "TOPLEFT", INPUT_COL, -backdrop.pos)
  dialog.y:SetWidth(80)
  dialog.y:SetScript("OnEnter", function()
    dialog.y:ShowTooltip({
      "Y-Position of Window",
      "|cffaaaaaaA Number in Pixels"
    })
  end)

  dialog.y:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  backdrop.pos = backdrop.pos + SPACING

  -- Test Bar Button (moved up from bottom)
  dialog.test_bar = CreateFrame("Button", nil, backdrop, "GameMenuButtonTemplate")
  dialog.test_bar:SetWidth(200)
  dialog.test_bar:SetHeight(18)
  dialog.test_bar:SetFont(STANDARD_TEXT_FONT, 10)
  dialog.test_bar:SetPoint("TOPLEFT", backdrop, "TOPLEFT", LABEL_COL, -backdrop.pos)
  dialog.test_bar:SetText("Toggle Test Bar")
  dialog.test_bar:SetScript("OnClick", function()
    if ShaguScan.testbars and ShaguScan.testbars.CreateTestBar then
      ShaguScan.testbars.CreateTestBar(config, caption)
    end
  end)
  dialog.test_bar:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    GameTooltip:AddLine("Toggle Test Bar")
    GameTooltip:AddLine("|cffaaaaaaShows/hides a sample health bar with current visual settings")
    GameTooltip:Show()
  end)
  dialog.test_bar:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  backdrop.pos = backdrop.pos + 18

  -- === VISUAL CUSTOMIZATION SECTION ===
  backdrop.pos = backdrop.pos + 15
  local header3 = backdrop:CreateSectionHeader("Visual Customization")
  header3:SetPoint("TOPLEFT", backdrop, LABEL_COL, -backdrop.pos)
  backdrop.pos = backdrop.pos + 22

  -- Bar Color Mode
  local label = backdrop:CreateLabel("Bar Color:")
  label:SetPoint("TOPLEFT", backdrop, LABEL_COL, -backdrop.pos)

  dialog.bar_color_mode = backdrop:CreateDropdown({"reaction", "class", "custom"}, config.bar_color_mode or "reaction")
  dialog.bar_color_mode:SetPoint("TOPLEFT", backdrop, "TOPLEFT", INPUT_COL, -backdrop.pos)
  dialog.bar_color_mode:SetWidth(120)
  dialog.bar_color_mode.onChange = function()
    if ShaguScan.testbars and ShaguScan.testbars.UpdateTestBarFromDialog then
      ShaguScan.testbars.UpdateTestBarFromDialog(dialog, caption)
    end
  end
  dialog.bar_color_mode:SetScript("OnEnter", function()
    dialog.bar_color_mode:ShowTooltip({
      "Bar Color Mode",
      "|cffaaaaaaChoose how health bars are colored:",
      " ",
      { "|cffffffffreaction", "Hostile/Friendly/Neutral" },
      { "|cffffffffclass", "Player Class Colors" },
      { "|cffffffffcustom", "Custom Color" }
    })
  end)
  dialog.bar_color_mode:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  backdrop.pos = backdrop.pos + SPACING

  -- Statusbar Texture
  local label = backdrop:CreateLabel("Bar Texture:")
  label:SetPoint("TOPLEFT", backdrop, LABEL_COL, -backdrop.pos)

  -- Convert texture path to texture name for display
  local currentTextureName = "Default"
  local textureList = utils.GetPfUIStatusbarTextures()
  for i = 1, table.getn(textureList) do
    if textureList[i].path == config.bar_texture then
      currentTextureName = textureList[i].name
      break
    end
  end

  dialog.bar_texture = widgets.CreateStatusbarDropdown(backdrop, currentTextureName)
  dialog.bar_texture:SetPoint("TOPLEFT", backdrop, "TOPLEFT", INPUT_COL, -backdrop.pos)
  dialog.bar_texture:SetWidth(200)
  dialog.bar_texture.onChange = function()
    -- Update the config immediately when texture changes
    local texturePath = dialog.bar_texture.GetTexturePath()
    if texturePath and config then
      config.bar_texture = texturePath
    end
    
    -- Update test bar with new texture
    if ShaguScan.testbars and ShaguScan.testbars.UpdateTestBarFromDialog then
      ShaguScan.testbars.UpdateTestBarFromDialog(dialog, caption)
    end
  end
  dialog.bar_texture:SetScript("OnEnter", function()
    dialog.bar_texture:ShowTooltip({
      "Statusbar Texture",
      "|cffaaaaaaChoose the health bar texture:",
      " ",
      "|cffaaaaaaIncludes standard WoW textures",
      "|cffaaaaaaplus pfUI statusbar textures if available"
    })
  end)
  dialog.bar_texture:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  backdrop.pos = backdrop.pos + SPACING

  -- Background Texture
  local label = backdrop:CreateLabel("Background:")
  label:SetPoint("TOPLEFT", backdrop, LABEL_COL, -backdrop.pos)

  dialog.background_texture = backdrop:CreateDropdown({"none", "default", "gradient"}, config.background_texture or "default")
  dialog.background_texture:SetPoint("TOPLEFT", backdrop, "TOPLEFT", INPUT_COL, -backdrop.pos)
  dialog.background_texture:SetWidth(120)
  dialog.background_texture.onChange = function()
    if ShaguScan.testbars and ShaguScan.testbars.UpdateTestBarFromDialog then
      ShaguScan.testbars.UpdateTestBarFromDialog(dialog, caption)
    end
  end
  dialog.background_texture:SetScript("OnEnter", function()
    dialog.background_texture:ShowTooltip({
      "Background Texture",
      "|cffaaaaaaChoose the background style:",
      " ",
      { "|cffffffffnone", "No Background" },
      { "|cffffffffdefault", "Default Texture" }, 
      { "|cffffffffgradient", "Gradient Texture" }
    })
  end)
  dialog.background_texture:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  backdrop.pos = backdrop.pos + SPACING

  -- Bar Alpha (Statusbar Opacity)
  local label = backdrop:CreateLabel("Bar Alpha:")
  label:SetPoint("TOPLEFT", backdrop, LABEL_COL, -backdrop.pos)

  dialog.bar_alpha = backdrop:CreateTextBox(config.bar_alpha or 1.0)
  dialog.bar_alpha:SetPoint("TOPLEFT", backdrop, "TOPLEFT", INPUT_COL, -backdrop.pos)
  dialog.bar_alpha:SetWidth(80)
  dialog.bar_alpha:SetScript("OnEnter", function()
    dialog.bar_alpha:ShowTooltip({
      "Bar Alpha",
      "|cffaaaaaaTransparency of health bars (0.0-1.0):",
      " ",
      "|cffffffff0.0 = Fully Transparent",
      "|cffffffff1.0 = Fully Opaque"
    })
  end)
  dialog.bar_alpha:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  dialog.bar_alpha:SetScript("OnTextChanged", function()
    -- Update the config immediately when alpha changes
    local alpha = tonumber(dialog.bar_alpha:GetText())
    if alpha and alpha >= 0 and alpha <= 1 then
      config.bar_alpha = alpha
      -- Update test bar with new alpha
      if ShaguScan.testbars and ShaguScan.testbars.UpdateTestBarFromDialog then
        ShaguScan.testbars.UpdateTestBarFromDialog(dialog, caption)
      end
    end
  end)
  backdrop.pos = backdrop.pos + SPACING

  -- Background Alpha
  local label = backdrop:CreateLabel("Background Alpha:")
  label:SetPoint("TOPLEFT", backdrop, LABEL_COL, -backdrop.pos)

  dialog.background_alpha = backdrop:CreateTextBox(config.background_alpha or 0.9)
  dialog.background_alpha:SetPoint("TOPLEFT", backdrop, "TOPLEFT", INPUT_COL, -backdrop.pos)
  dialog.background_alpha:SetWidth(80)
  dialog.background_alpha:SetScript("OnEnter", function()
    dialog.background_alpha:ShowTooltip({
      "Background Alpha",
      "|cffaaaaaaTransparency of background (0.0-1.0):",
      " ",
      "|cffffffff0.0 = Fully Transparent",
      "|cffffffff1.0 = Fully Opaque"
    })
  end)
  dialog.background_alpha:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  dialog.background_alpha:SetScript("OnTextChanged", function()
    -- Update the config immediately when alpha changes
    local alpha = tonumber(dialog.background_alpha:GetText())
    if alpha and alpha >= 0 and alpha <= 1 and config then
      config.background_alpha = alpha
    end
    
    -- Update test bar with new alpha
    if ShaguScan.testbars and ShaguScan.testbars.UpdateTestBarFromDialog then
      ShaguScan.testbars.UpdateTestBarFromDialog(dialog, caption)
    end
  end)
  backdrop.pos = backdrop.pos + SPACING

  -- Border Style
  local label = backdrop:CreateLabel("Border:")
  label:SetPoint("TOPLEFT", backdrop, LABEL_COL, -backdrop.pos)

  dialog.border_style = backdrop:CreateDropdown({"none", "thin", "default", "thick", "glow"}, config.border_style or "default")
  dialog.border_style:SetPoint("TOPLEFT", backdrop, "TOPLEFT", INPUT_COL, -backdrop.pos)
  dialog.border_style:SetWidth(120)
  dialog.border_style.onChange = function()
    if ShaguScan.testbars and ShaguScan.testbars.UpdateTestBarFromDialog then
      ShaguScan.testbars.UpdateTestBarFromDialog(dialog, caption)
    end
  end
  dialog.border_style:SetScript("OnEnter", function()
    dialog.border_style:ShowTooltip({
      "Border Style",
      "|cffaaaaaaChoose the border appearance:",
      " ",
      { "|cffffffffnone", "No Border" },
      { "|cffffffffthin", "Thin Border" },
      { "|cffffffffdefault", "Default Border" },
      { "|cffffffffthick", "Thick Border" },
      { "|cffffffffglow", "Glow Border" }
    })
  end)
  dialog.border_style:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  backdrop.pos = backdrop.pos + SPACING

  -- Text Position
  local label = backdrop:CreateLabel("Text Pos:")
  label:SetPoint("TOPLEFT", backdrop, LABEL_COL, -backdrop.pos)

  dialog.text_position = backdrop:CreateDropdown({"left", "center", "right"}, config.text_position or "left")
  dialog.text_position:SetPoint("TOPLEFT", backdrop, "TOPLEFT", INPUT_COL, -backdrop.pos)
  dialog.text_position:SetWidth(120)
  dialog.text_position:SetScript("OnEnter", function()
    dialog.text_position:ShowTooltip({
      "Text Position",
      "|cffaaaaaaPosition of the main text:",
      " ",
      { "|cffffffffleft", "Left Aligned" },
      { "|cffffffffcenter", "Center Aligned" },
      { "|cffffffffright", "Right Aligned" }
    })
  end)
  dialog.text_position:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  dialog.text_position.onChange = function()
    if ShaguScan.testbars and ShaguScan.testbars.UpdateTestBarFromDialog then
      ShaguScan.testbars.UpdateTestBarFromDialog(dialog, caption)
    end
  end
  backdrop.pos = backdrop.pos + SPACING

  -- Text Format
  local label = backdrop:CreateLabel("Text Format:")
  label:SetPoint("TOPLEFT", backdrop, LABEL_COL, -backdrop.pos)

  dialog.text_format = backdrop:CreateDropdown({"level_name", "name_only", "level_only", "health_percent", "health_current"}, config.text_format or "level_name")
  dialog.text_format:SetPoint("TOPLEFT", backdrop, "TOPLEFT", INPUT_COL, -backdrop.pos)
  dialog.text_format:SetWidth(150)
  dialog.text_format:SetScript("OnEnter", function()
    dialog.text_format:ShowTooltip({
      "Text Format",
      "|cffaaaaaaWhat information to display:",
      " ",
      { "|cfffffffflevel_name", "Level + Name" },
      { "|cffffffffname_only", "Name Only" },
      { "|cfffffffflevel_only", "Level Only" },
      { "|cffffffffhealth_percent", "Health %" },
      { "|cffffffffhealth_current", "Current Health" }
    })
  end)
  dialog.text_format:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  dialog.text_format.onChange = function()
    if ShaguScan.testbars and ShaguScan.testbars.UpdateTestBarFromDialog then
      ShaguScan.testbars.UpdateTestBarFromDialog(dialog, caption)
    end
  end
  backdrop.pos = backdrop.pos + SPACING

  -- Text Font
  local label = backdrop:CreateLabel("Text Font:")
  label:SetPoint("TOPLEFT", backdrop, LABEL_COL, -backdrop.pos)

  -- Convert font path to font name for display
  local currentFontName = "Standard"
  local fontList = utils.GetPfUIFontList()
  for i = 1, table.getn(fontList) do
    -- Check both path and name to handle legacy configs
    if fontList[i].path == config.text_font or fontList[i].name == config.text_font then
      currentFontName = fontList[i].name
      break
    end
  end

  dialog.text_font = ShaguScan.fonts.CreateFontDropdown(backdrop, currentFontName)
  dialog.text_font:SetPoint("TOPLEFT", backdrop, "TOPLEFT", INPUT_COL, -backdrop.pos)
  dialog.text_font:SetWidth(150)
  dialog.text_font:SetScript("OnEnter", function()
    dialog.text_font:ShowTooltip({
      "Text Font",
      "|cffaaaaaaFont family for text display:",
      " ",
      "|cffaaaaaaIncludes standard WoW fonts",
      "|cffaaaaaaplus pfUI fonts if available"
    })
  end)
  dialog.text_font:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  dialog.text_font.onChange = function()
    -- Update the config immediately when font changes
    local fontPath = dialog.text_font.GetFontPath()
    if fontPath and config then
      config.text_font = fontPath
    end
    
    -- Update test bar with new font
    if ShaguScan.testbars and ShaguScan.testbars.UpdateTestBarFromDialog then
      ShaguScan.testbars.UpdateTestBarFromDialog(dialog, caption)
    end
  end
  backdrop.pos = backdrop.pos + SPACING

  -- Text Size
  local label = backdrop:CreateLabel("Text Size:")
  label:SetPoint("TOPLEFT", backdrop, LABEL_COL, -backdrop.pos)

  dialog.text_size = backdrop:CreateTextBox(config.text_size or 9)
  dialog.text_size:SetPoint("TOPLEFT", backdrop, "TOPLEFT", INPUT_COL, -backdrop.pos)
  dialog.text_size:SetWidth(60)
  dialog.text_size:SetScript("OnEnter", function()
    dialog.text_size:ShowTooltip({
      "Text Size",
      "|cffaaaaaaFont size for text display"
    })
  end)
  dialog.text_size:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  dialog.text_size:SetScript("OnTextChanged", function()
    -- Update the config immediately when text size changes
    local size = tonumber(dialog.text_size:GetText())
    if size and config then
      config.text_size = size
    end
    
    -- Update test bar with new text size
    if ShaguScan.testbars and ShaguScan.testbars.UpdateTestBarFromDialog then
      ShaguScan.testbars.UpdateTestBarFromDialog(dialog, caption)
    end
  end)
  backdrop.pos = backdrop.pos + SPACING

  -- Text Outline
  local label = backdrop:CreateLabel("Text Outline:")
  label:SetPoint("TOPLEFT", backdrop, LABEL_COL, -backdrop.pos)

  dialog.text_outline = backdrop:CreateDropdown({"", "THINOUTLINE", "OUTLINE", "THICKOUTLINE"}, config.text_outline or "THINOUTLINE")
  dialog.text_outline:SetPoint("TOPLEFT", backdrop, "TOPLEFT", INPUT_COL, -backdrop.pos)
  dialog.text_outline:SetWidth(140)
  dialog.text_outline:SetScript("OnEnter", function()
    dialog.text_outline:ShowTooltip({
      "Text Outline Style",
      "|cffaaaaaaOutline style for text readability:",
      " ",
      { "|cffffffff\"\"", "No Outline" },
      { "|cffffffffTHINOUTLINE", "Thin Outline (Default)" },
      { "|cffffffffOUTLINE", "Standard Outline" },
      { "|cffffffffTHICKOUTLINE", "Thick Outline" }
    })
  end)
  dialog.text_outline:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  dialog.text_outline.onChange = function()
    -- Update the config immediately when outline changes
    if config then
      config.text_outline = dialog.text_outline.GetValue()
    end
    
    -- Update test bar with new outline
    if ShaguScan.testbars and ShaguScan.testbars.UpdateTestBarFromDialog then
      ShaguScan.testbars.UpdateTestBarFromDialog(dialog, caption)
    end
  end
  backdrop.pos = backdrop.pos + 18

  -- === ADVANCED SETTINGS SECTION ===
  backdrop.pos = backdrop.pos + 15
  local header4 = backdrop:CreateSectionHeader("Advanced Settings")
  header4:SetPoint("TOPLEFT", backdrop, LABEL_COL, -backdrop.pos)
  backdrop.pos = backdrop.pos + 22

  -- Health Text Enabled
  local label = backdrop:CreateLabel("Health Text:")
  label:SetPoint("TOPLEFT", backdrop, LABEL_COL, -backdrop.pos)

  dialog.health_text_enabled = backdrop:CreateDropdown({"false", "true"}, config.health_text_enabled and "true" or "false")
  dialog.health_text_enabled:SetPoint("TOPLEFT", backdrop, "TOPLEFT", INPUT_COL, -backdrop.pos)
  dialog.health_text_enabled:SetWidth(80)
  dialog.health_text_enabled:SetScript("OnEnter", function()
    dialog.health_text_enabled:ShowTooltip({
      "Health Text Display",
      "|cffaaaaaaShow separate health text:",
      " ",
      { "|cfffffffftrue", "Enable Health Text" },
      { "|cfffffffffalse", "Disable Health Text" }
    })
  end)
  dialog.health_text_enabled:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  dialog.health_text_enabled.onChange = function()
    if ShaguScan.testbars and ShaguScan.testbars.UpdateTestBarFromDialog then
      ShaguScan.testbars.UpdateTestBarFromDialog(dialog, caption)
    end
  end
  backdrop.pos = backdrop.pos + SPACING

  -- Health Text Format
  local label = backdrop:CreateLabel("Health Format:")
  label:SetPoint("TOPLEFT", backdrop, LABEL_COL, -backdrop.pos)

  dialog.health_text_format = backdrop:CreateDropdown({"percent", "current", "current_max", "deficit"}, config.health_text_format or "percent")
  dialog.health_text_format:SetPoint("TOPLEFT", backdrop, "TOPLEFT", INPUT_COL, -backdrop.pos)
  dialog.health_text_format:SetWidth(120)
  dialog.health_text_format:SetScript("OnEnter", function()
    dialog.health_text_format:ShowTooltip({
      "Health Text Format",
      "|cffaaaaaaFormat for health text display:",
      " ",
      { "|cffffffffpercent", "Health Percentage" },
      { "|cffffffffcurrent", "Current Health" },
      { "|cffffffffcurrent_max", "Current/Max Health" },
      { "|cffffffffdeficit", "Health Deficit" }
    })
  end)
  dialog.health_text_format:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  dialog.health_text_format.onChange = function()
    if config then
      config.health_text_format = dialog.health_text_format.GetValue()
    end
    if ShaguScan.testbars and ShaguScan.testbars.UpdateTestBarFromDialog then
      ShaguScan.testbars.UpdateTestBarFromDialog(dialog, caption)
    end
  end
  backdrop.pos = backdrop.pos + SPACING

  -- Health Text Position
  local label = backdrop:CreateLabel("Health Position:")
  label:SetPoint("TOPLEFT", backdrop, LABEL_COL, -backdrop.pos)

  dialog.health_text_position = backdrop:CreateDropdown({"left", "center", "right"}, config.health_text_position or "right")
  dialog.health_text_position:SetPoint("TOPLEFT", backdrop, "TOPLEFT", INPUT_COL, -backdrop.pos)
  dialog.health_text_position:SetWidth(100)
  dialog.health_text_position:SetScript("OnEnter", function()
    dialog.health_text_position:ShowTooltip({
      "Health Text Position",
      "|cffaaaaaaPosition of health text on bar:",
      " ",
      { "|cffffffffleft", "Left Side" },
      { "|cffffffffcenter", "Center" },
      { "|cffffffffright", "Right Side" }
    })
  end)
  dialog.health_text_position:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  dialog.health_text_position.onChange = function()
    if config then
      config.health_text_position = dialog.health_text_position.GetValue()
    end
    if ShaguScan.testbars and ShaguScan.testbars.UpdateTestBarFromDialog then
      ShaguScan.testbars.UpdateTestBarFromDialog(dialog, caption)
    end
  end
  backdrop.pos = backdrop.pos + SPACING

  -- Frame Shadow
  local label = backdrop:CreateLabel("Frame Shadow:")
  label:SetPoint("TOPLEFT", backdrop, LABEL_COL, -backdrop.pos)

  dialog.frame_shadow = backdrop:CreateDropdown({"false", "true"}, config.frame_shadow and "true" or "false")
  dialog.frame_shadow:SetPoint("TOPLEFT", backdrop, "TOPLEFT", INPUT_COL, -backdrop.pos)
  dialog.frame_shadow:SetWidth(80)
  dialog.frame_shadow:SetScript("OnEnter", function()
    dialog.frame_shadow:ShowTooltip({
      "Frame Shadow",
      "|cffaaaaaaAdd pfUI-style shadow to frames:",
      " ",
      { "|cfffffffftrue", "Enable Shadows" },
      { "|cfffffffffalse", "Disable Shadows" }
    })
  end)
  dialog.frame_shadow:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  dialog.frame_shadow.onChange = function()
    if ShaguScan.testbars and ShaguScan.testbars.UpdateTestBarFromDialog then
      ShaguScan.testbars.UpdateTestBarFromDialog(dialog, caption)
    end
  end

  -- Set up scrolling - calculate final height and enable scroll bar (pfUI-style)
  local contentHeight = backdrop.pos + 5 -- Very minimal padding at the bottom
  backdrop:SetHeight(contentHeight)
  scrollChild:SetHeight(contentHeight)
  
  -- Update width now that backdrop is created
  UpdateScrollChildSize()
  
  -- pfUI-style scroll calculation
  local function UpdateScrollState()
    local visibleHeight = scrollFrame:GetHeight()
    local actualContentHeight = backdrop:GetHeight() or contentHeight
    local scrollRange = math.max(0, actualContentHeight - visibleHeight)
    
    scrollBar:SetMinMaxValues(0, scrollRange)
    scrollBar:SetValue(math.min(scrollBar:GetValue(), scrollRange))
    
    -- Calculate thumb size ratio (pfUI style)
    local totalHeight = actualContentHeight
    local ratio = visibleHeight / totalHeight
    
    if ratio < 1 and scrollRange > 0 then
      local thumbSize = math.max(20, math.floor(visibleHeight * ratio))
      scrollBar.thumb:SetHeight(thumbSize)
      scrollBar:Show()
    else
      scrollBar:Hide()
    end
  end
  
  -- Store function for potential updates
  dialog.UpdateScrollState = UpdateScrollState
  UpdateScrollState()
  
  -- Store references for scroll updates
  dialog.scrollFrame = scrollFrame
  dialog.scrollBar = scrollBar
  dialog.scrollChild = scrollChild
  dialog.contentHeight = contentHeight
  
  -- Add function to recalculate content height dynamically
  dialog.RecalculateScrollRange = function()
    -- Recalculate content height based on actual content
    local newContentHeight = backdrop.pos + 5
    backdrop:SetHeight(newContentHeight)
    scrollChild:SetHeight(newContentHeight)
    dialog.contentHeight = newContentHeight
    UpdateScrollState()
  end
  
  -- Add OnSizeChanged handler to detect when dialog is resized
  dialog:SetScript("OnSizeChanged", function()
    if dialog.UpdateScrollState then
      dialog.UpdateScrollState()
    end
  end)

end