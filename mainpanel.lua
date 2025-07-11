-- mainpanel.lua - Main control panel functionality
-- Extracted from settings.lua to reduce file size

local mainpanel = {}

-- Export the module immediately for proper loading order
ShaguScan.mainpanel = mainpanel

-- References to other modules
local utils = ShaguScan.utils
local widgets = ShaguScan.widgets

mainpanel.OpenMainWindow = function()
  -- Check if addon is disabled
  if ShaguScan.disabled then
    DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00Shagu|cffffffffScan:|cffffaaaa Addon is disabled (SuperWoW not detected)")
    return
  end

  -- Toggle Existing Dialog
  local existing = getglobal("ShaguScanMainWindow")
  if existing then
    if existing:IsShown() then existing:Hide() else existing:Show() end
    return
  end

  -- Initialize global settings if not existing
  if not ShaguScan_db.global_settings then
    ShaguScan_db.global_settings = {
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
      auto_cleanup_time = 30,
      max_units_per_window = 50,
      enable_sound_alerts = false,
      enable_minimap_button = true,
      debug_mode = false
    }
  end

  -- Main Dialog
  local dialog = CreateFrame("Frame", "ShaguScanMainWindow", UIParent)
  table.insert(UISpecialFrames, "ShaguScanMainWindow")

  dialog:SetFrameStrata("DIALOG")
  dialog:SetPoint("CENTER", 0, 0)
  dialog:SetWidth(500)
  dialog:SetHeight(650) -- Increased height for better content fit

  dialog:EnableMouse(true)
  dialog:RegisterForDrag("LeftButton")
  dialog:SetMovable(true)
  dialog:SetScript("OnDragStart", function() this:StartMoving() end)
  dialog:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)

  dialog:SetBackdrop(widgets.backdrop)
  dialog:SetBackdropColor(.1, .1, .1, 1)
  dialog:SetBackdropBorderColor(.3, .3, .3, 1)

  -- Title
  dialog.title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  dialog.title:SetPoint("TOP", dialog, "TOP", 0, -15)
  dialog.title:SetText("ShaguScan - Main Control Panel")
  dialog.title:SetTextColor(1, 1, 1, 1)

  -- Close button
  dialog.close = CreateFrame("Button", nil, dialog, "UIPanelCloseButton")
  dialog.close:SetWidth(20)
  dialog.close:SetHeight(20)
  dialog.close:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", 0, 0)
  dialog.close:SetScript("OnClick", function()
    this:GetParent():Hide()
  end)

  -- Tab system
  dialog.tab1 = CreateFrame("Button", nil, dialog, "GameMenuButtonTemplate")
  dialog.tab1:SetWidth(120)
  dialog.tab1:SetHeight(20)
  dialog.tab1:SetPoint("TOPLEFT", dialog, "TOPLEFT", 10, -40)
  dialog.tab1:SetText("Scan Windows")
  dialog.tab1:SetFont(STANDARD_TEXT_FONT, 10)
  dialog.tab1.active = true

  dialog.tab2 = CreateFrame("Button", nil, dialog, "GameMenuButtonTemplate")
  dialog.tab2:SetWidth(120)
  dialog.tab2:SetHeight(20)
  dialog.tab2:SetPoint("LEFT", dialog.tab1, "RIGHT", 5, 0)
  dialog.tab2:SetText("Global Settings")
  dialog.tab2:SetFont(STANDARD_TEXT_FONT, 10)
  dialog.tab2.active = false

  -- Create content panels
  dialog.panel1 = mainpanel.CreateScanWindowPanel(dialog)
  dialog.panel2 = mainpanel.CreateGlobalSettingsPanel(dialog)

  -- Tab switching logic
  dialog.tab1:SetScript("OnClick", function()
    dialog.tab1.active = true
    dialog.tab2.active = false
    dialog.panel1:Show()
    dialog.panel2:Hide()
    mainpanel.UpdateTabAppearance(dialog)
  end)

  dialog.tab2:SetScript("OnClick", function()
    dialog.tab1.active = false
    dialog.tab2.active = true
    dialog.panel1:Hide()
    dialog.panel2:Show()
    mainpanel.UpdateTabAppearance(dialog)
  end)

  -- Show initial tab
  dialog.panel1:Show()
  dialog.panel2:Hide()
  mainpanel.UpdateTabAppearance(dialog)

  dialog:Show()
end

mainpanel.UpdateTabAppearance = function(dialog)
  if dialog.tab1.active then
    dialog.tab1:SetBackdropBorderColor(1, 1, 1, 1)
    dialog.tab1:SetBackdropColor(0.3, 0.3, 0.3, 1)
  else
    dialog.tab1:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
    dialog.tab1:SetBackdropColor(0.1, 0.1, 0.1, 1)
  end

  if dialog.tab2.active then
    dialog.tab2:SetBackdropBorderColor(1, 1, 1, 1)
    dialog.tab2:SetBackdropColor(0.3, 0.3, 0.3, 1)
  else
    dialog.tab2:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
    dialog.tab2:SetBackdropColor(0.1, 0.1, 0.1, 1)
  end
end

mainpanel.CreateScanWindowPanel = function(parent)
  local panel = CreateFrame("Frame", nil, parent)
  panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -70)
  panel:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -10, 10)

  panel:SetBackdrop(widgets.backdrop)
  panel:SetBackdropColor(.2, .2, .2, 1)
  panel:SetBackdropBorderColor(.3, .3, .3, 1)

  -- Title
  local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOP", panel, "TOP", 0, -10)
  title:SetText("Scan Windows")
  title:SetTextColor(1, 1, 0, 1)

  -- Create New Window Button
  panel.createNew = CreateFrame("Button", nil, panel, "GameMenuButtonTemplate")
  panel.createNew:SetWidth(150)
  panel.createNew:SetHeight(25)
  panel.createNew:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -35)
  panel.createNew:SetText("Create New Window")
  panel.createNew:SetFont(STANDARD_TEXT_FONT, 10)
  panel.createNew:SetScript("OnClick", function()
    mainpanel.CreateNewScanWindow()
  end)

  -- Window List Scroll Frame
  panel.scrollFrame = CreateFrame("ScrollFrame", nil, panel)
  panel.scrollFrame:SetPoint("TOPLEFT", panel.createNew, "BOTTOMLEFT", 0, -10)
  panel.scrollFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -25, 10)

  panel.scrollChild = CreateFrame("Frame", nil, panel.scrollFrame)
  panel.scrollChild:SetWidth(1)
  panel.scrollChild:SetHeight(1)
  panel.scrollFrame:SetScrollChild(panel.scrollChild)

  -- Scroll bar
  panel.scrollBar = CreateFrame("Slider", nil, panel.scrollFrame)
  panel.scrollBar:SetPoint("TOPLEFT", panel.scrollFrame, "TOPRIGHT", 5, 0)
  panel.scrollBar:SetPoint("BOTTOMLEFT", panel.scrollFrame, "BOTTOMRIGHT", 5, 0)
  panel.scrollBar:SetWidth(15)
  panel.scrollBar:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 8,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
  })
  panel.scrollBar:SetBackdropColor(0, 0, 0, 0.5)
  panel.scrollBar:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

  -- Populate window list
  mainpanel.RefreshWindowList(panel)

  return panel
end

mainpanel.RefreshWindowList = function(panel)
  -- Clear existing buttons
  if panel.windowButtons then
    for i, button in ipairs(panel.windowButtons) do
      button:Hide()
    end
  end
  panel.windowButtons = {}

  -- Create buttons for each scan window
  local yOffset = -10
  for caption, config in pairs(ShaguScan_db.config) do
    local button = CreateFrame("Frame", nil, panel.scrollChild)
    button:SetWidth(400)
    button:SetHeight(30)
    button:SetPoint("TOPLEFT", panel.scrollChild, "TOPLEFT", 5, yOffset)

    button:SetBackdrop(widgets.backdrop)
    button:SetBackdropColor(0.1, 0.1, 0.1, 1)
    button:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    -- Window name
    button.name = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    button.name:SetPoint("LEFT", button, "LEFT", 10, 0)
    button.name:SetText(caption)
    button.name:SetTextColor(1, 1, 1, 1)

    -- Filter info
    button.filter = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.filter:SetPoint("LEFT", button.name, "RIGHT", 20, 0)
    button.filter:SetText("|cffaaaaaa" .. (config.filter or ""))
    button.filter:SetTextColor(0.7, 0.7, 0.7, 1)

    -- Edit button
    button.edit = CreateFrame("Button", nil, button, "GameMenuButtonTemplate")
    button.edit:SetWidth(60)
    button.edit:SetHeight(20)
    button.edit:SetPoint("RIGHT", button, "RIGHT", -70, 0)
    button.edit:SetText("Edit")
    button.edit:SetFont(STANDARD_TEXT_FONT, 8)
    button.edit:SetScript("OnClick", function()
      ShaguScan.dialogs.OpenConfig(this.caption)
    end)
    button.edit.caption = caption

    -- Delete button
    button.delete = CreateFrame("Button", nil, button, "GameMenuButtonTemplate")
    button.delete:SetWidth(60)
    button.delete:SetHeight(20)
    button.delete:SetPoint("RIGHT", button, "RIGHT", -5, 0)
    button.delete:SetText("Delete")
    button.delete:SetFont(STANDARD_TEXT_FONT, 8)
    button.delete:SetScript("OnClick", function()
      mainpanel.DeleteScanWindow(this.caption, panel)
    end)
    button.delete.caption = caption

    table.insert(panel.windowButtons, button)
    yOffset = yOffset - 35
  end

  -- Update scroll child height
  panel.scrollChild:SetHeight(math.max(1, math.abs(yOffset)))
end

mainpanel.CreateNewScanWindow = function()
  -- Create a simple dialog to get window name
  local dialog = CreateFrame("Frame", "ShaguScanNewWindowDialog", UIParent)
  dialog:SetFrameStrata("FULLSCREEN_DIALOG")
  dialog:SetFrameLevel(100)
  dialog:SetPoint("CENTER", 0, 0)
  dialog:SetWidth(300)
  dialog:SetHeight(120)
  dialog:EnableMouse(true)
  dialog:SetBackdrop(widgets.backdrop)
  dialog:SetBackdropColor(.1, .1, .1, 1)
  dialog:SetBackdropBorderColor(.3, .3, .3, 1)

  -- Title
  local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOP", dialog, "TOP", 0, -15)
  title:SetText("Create New Scan Window")
  title:SetTextColor(1, 1, 1, 1)

  -- Input box
  local input = CreateFrame("EditBox", nil, dialog)
  input:SetPoint("CENTER", dialog, "CENTER", 0, 5)
  input:SetWidth(250)
  input:SetHeight(20)
  input:SetBackdrop(widgets.textborder)
  input:SetBackdropColor(.1, .1, .1, 1)
  input:SetBackdropBorderColor(.3, .3, .3, 1)
  input:SetFont(STANDARD_TEXT_FONT, 10)
  input:SetTextColor(1, 1, 1, 1)
  input:SetTextInsets(5, 5, 5, 5)
  input:SetAutoFocus(true)
  input:SetText("My Scanner")
  input:HighlightText()

  -- Create button
  local create = CreateFrame("Button", nil, dialog, "GameMenuButtonTemplate")
  create:SetWidth(80)
  create:SetHeight(20)
  create:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -10, 10)
  create:SetText("Create")
  create:SetFont(STANDARD_TEXT_FONT, 10)
  create:SetScript("OnClick", function()
    local name = input:GetText()
    if name and name ~= "" then
      ShaguScan.dialogs.OpenConfig(name)
      dialog:Hide()
    end
  end)

  -- Cancel button
  local cancel = CreateFrame("Button", nil, dialog, "GameMenuButtonTemplate")
  cancel:SetWidth(80)
  cancel:SetHeight(20)
  cancel:SetPoint("BOTTOMLEFT", dialog, "BOTTOMLEFT", 10, 10)
  cancel:SetText("Cancel")
  cancel:SetFont(STANDARD_TEXT_FONT, 10)
  cancel:SetScript("OnClick", function()
    dialog:Hide()
  end)

  -- Enter key handler
  input:SetScript("OnEnterPressed", function()
    create:Click()
  end)

  -- Escape key handler
  input:SetScript("OnEscapePressed", function()
    dialog:Hide()
  end)

  dialog:Show()
end

mainpanel.DeleteScanWindow = function(caption, panel)
  -- Confirmation dialog
  local dialog = CreateFrame("Frame", "ShaguScanDeleteDialog", UIParent)
  dialog:SetFrameStrata("FULLSCREEN_DIALOG")
  dialog:SetFrameLevel(100)
  dialog:SetPoint("CENTER", 0, 0)
  dialog:SetWidth(300)
  dialog:SetHeight(100)
  dialog:EnableMouse(true)
  dialog:SetBackdrop(widgets.backdrop)
  dialog:SetBackdropColor(.1, .1, .1, 1)
  dialog:SetBackdropBorderColor(.3, .3, .3, 1)

  -- Message
  local message = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  message:SetPoint("TOP", dialog, "TOP", 0, -20)
  message:SetText("Delete '" .. caption .. "'?")
  message:SetTextColor(1, 1, 1, 1)

  -- Delete button
  local delete = CreateFrame("Button", nil, dialog, "GameMenuButtonTemplate")
  delete:SetWidth(80)
  delete:SetHeight(20)
  delete:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -10, 10)
  delete:SetText("Delete")
  delete:SetFont(STANDARD_TEXT_FONT, 10)
  delete:SetScript("OnClick", function()
    ShaguScan_db.config[caption] = nil
    mainpanel.RefreshWindowList(panel)
    dialog:Hide()
    DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00Shagu|cffffffffScan:|cffffaaaa Window '" .. caption .. "' deleted!")
  end)

  -- Cancel button
  local cancel = CreateFrame("Button", nil, dialog, "GameMenuButtonTemplate")
  cancel:SetWidth(80)
  cancel:SetHeight(20)
  cancel:SetPoint("BOTTOMLEFT", dialog, "BOTTOMLEFT", 10, 10)
  cancel:SetText("Cancel")
  cancel:SetFont(STANDARD_TEXT_FONT, 10)
  cancel:SetScript("OnClick", function()
    dialog:Hide()
  end)

  dialog:Show()
end

mainpanel.CreateGlobalSettingsPanel = function(parent)
  -- This is the existing OpenMainConfig content, but as a panel
  local panel = CreateFrame("Frame", nil, parent)
  panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -70)
  panel:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -10, 50)

  panel:SetBackdrop(widgets.backdrop)
  panel:SetBackdropColor(.2, .2, .2, 1)
  panel:SetBackdropBorderColor(.3, .3, .3, 1)

  -- Save Shortcuts
  local global_config = ShaguScan_db.global_settings

  -- Assign functions to panel
  panel.CreateTextBox = widgets.CreateTextBox
  panel.CreateLabel = widgets.CreateLabel
  panel.CreateDropdown = widgets.CreateDropdown
  panel.CreateFontDropdown = widgets.CreateFontDropdown

  panel.pos = 15

  -- Section: General Settings
  local section1 = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  section1:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -panel.pos)
  section1:SetText("General Settings")
  section1:SetTextColor(1, 1, 0, 1)
  panel.pos = panel.pos + 20

  -- Auto Cleanup Time
  local label = panel:CreateLabel("Cleanup Time:")
  label:SetPoint("TOPLEFT", panel, 10, -panel.pos)

  panel.auto_cleanup_time = panel:CreateTextBox(global_config.auto_cleanup_time)
  panel.auto_cleanup_time:SetPoint("TOPLEFT", panel, "TOPLEFT", 120, -panel.pos)
  panel.auto_cleanup_time:SetWidth(100)
  panel.pos = panel.pos + 25

  -- Max Units Per Window
  local label = panel:CreateLabel("Max Units:")
  label:SetPoint("TOPLEFT", panel, 10, -panel.pos)

  panel.max_units_per_window = panel:CreateTextBox(global_config.max_units_per_window)
  panel.max_units_per_window:SetPoint("TOPLEFT", panel, "TOPLEFT", 120, -panel.pos)
  panel.max_units_per_window:SetWidth(100)
  panel.pos = panel.pos + 25

  -- Debug Mode
  local label = panel:CreateLabel("Debug Mode:")
  label:SetPoint("TOPLEFT", panel, 10, -panel.pos)

  panel.debug_mode = panel:CreateDropdown({"false", "true"}, global_config.debug_mode and "true" or "false")
  panel.debug_mode:SetPoint("TOPLEFT", panel, "TOPLEFT", 120, -panel.pos)
  panel.debug_mode:SetWidth(100)
  panel.pos = panel.pos + 35

  -- Hide Window Headers
  local label = panel:CreateLabel("Hide Window Headers:")
  label:SetPoint("TOPLEFT", panel, 10, -panel.pos)

  panel.hide_window_headers = panel:CreateDropdown({"false", "true"}, global_config.hide_window_headers and "true" or "false")
  panel.hide_window_headers:SetPoint("TOPLEFT", panel, "TOPLEFT", 120, -panel.pos)
  panel.hide_window_headers:SetWidth(100)
  panel.pos = panel.pos + 35

  -- Section: Default Template
  local section2 = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  section2:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -panel.pos)
  section2:SetText("Default Template (for new windows)")
  section2:SetTextColor(1, 1, 0, 1)
  panel.pos = panel.pos + 20

  -- Template Bar Color Mode
  local label = panel:CreateLabel("Bar Color:")
  label:SetPoint("TOPLEFT", panel, 10, -panel.pos)

  panel.template_bar_color_mode = panel:CreateDropdown({"reaction", "class", "custom"}, global_config.default_template.bar_color_mode)
  panel.template_bar_color_mode:SetPoint("TOPLEFT", panel, "TOPLEFT", 120, -panel.pos)
  panel.template_bar_color_mode:SetWidth(100)
  panel.pos = panel.pos + 25

  -- Template Border Style
  local label = panel:CreateLabel("Border:")
  label:SetPoint("TOPLEFT", panel, 10, -panel.pos)

  panel.template_border_style = panel:CreateDropdown({"none", "thin", "default", "thick", "glow"}, global_config.default_template.border_style)
  panel.template_border_style:SetPoint("TOPLEFT", panel, "TOPLEFT", 120, -panel.pos)
  panel.template_border_style:SetWidth(100)
  panel.pos = panel.pos + 25

  -- Template Text Format
  local label = panel:CreateLabel("Text Format:")
  label:SetPoint("TOPLEFT", panel, 10, -panel.pos)

  panel.template_text_format = panel:CreateDropdown({"level_name", "name_only", "level_only", "health_percent", "health_current"}, global_config.default_template.text_format)
  panel.template_text_format:SetPoint("TOPLEFT", panel, "TOPLEFT", 120, -panel.pos)
  panel.template_text_format:SetWidth(100)
  panel.pos = panel.pos + 25

  -- Template Text Font
  local label = panel:CreateLabel("Text Font:")
  label:SetPoint("TOPLEFT", panel, 10, -panel.pos)

  -- Convert font path to font name for display
  local templateFontName = "Standard"
  local templateFontList = ShaguScan.utils.GetPfUIFontList()
  for i = 1, table.getn(templateFontList) do
    if templateFontList[i].path == global_config.default_template.text_font then
      templateFontName = templateFontList[i].name
      break
    end
  end

  panel.template_text_font = widgets.CreateFontDropdown(panel, templateFontName)
  panel.template_text_font:SetPoint("TOPLEFT", panel, "TOPLEFT", 120, -panel.pos)
  panel.template_text_font:SetWidth(100)
  panel.pos = panel.pos + 25

  -- Template Frame Shadow
  local label = panel:CreateLabel("Frame Shadow:")
  label:SetPoint("TOPLEFT", panel, 10, -panel.pos)

  panel.template_frame_shadow = panel:CreateDropdown({"false", "true"}, global_config.default_template.frame_shadow and "true" or "false")
  panel.template_frame_shadow:SetPoint("TOPLEFT", panel, "TOPLEFT", 120, -panel.pos)
  panel.template_frame_shadow:SetWidth(100)
  panel.pos = panel.pos + 35

  -- Save Button
  panel.save = CreateFrame("Button", nil, parent, "GameMenuButtonTemplate")
  panel.save:SetWidth(96)
  panel.save:SetHeight(20)
  panel.save:SetFont(STANDARD_TEXT_FONT, 10)
  panel.save:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -10, 10)
  panel.save:SetText("Save Settings")
  panel.save:SetScript("OnClick", function()
    -- Save general settings
    global_config.auto_cleanup_time = tonumber(panel.auto_cleanup_time:GetText()) or global_config.auto_cleanup_time
    global_config.max_units_per_window = tonumber(panel.max_units_per_window:GetText()) or global_config.max_units_per_window
    global_config.debug_mode = panel.debug_mode.GetValue() == "true"
    global_config.hide_window_headers = panel.hide_window_headers.GetValue() == "true"

    -- Update header visibility immediately
    if ShaguScan.ui and ShaguScan.ui.UpdateHeaderVisibility then
      ShaguScan.ui.UpdateHeaderVisibility()
    end

    -- Save template settings
    global_config.default_template.bar_color_mode = panel.template_bar_color_mode.GetValue() or global_config.default_template.bar_color_mode
    global_config.default_template.border_style = panel.template_border_style.GetValue() or global_config.default_template.border_style
    global_config.default_template.text_format = panel.template_text_format.GetValue() or global_config.default_template.text_format
    global_config.default_template.text_font = panel.template_text_font.GetFontPath() or global_config.default_template.text_font
    global_config.default_template.frame_shadow = panel.template_frame_shadow.GetValue() == "true"

    DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00Shagu|cffffffffScan:|cffffaaaa Settings saved!")
  end)

  -- Apply Template Button
  panel.apply_template = CreateFrame("Button", nil, parent, "GameMenuButtonTemplate")
  panel.apply_template:SetWidth(120)
  panel.apply_template:SetHeight(20)
  panel.apply_template:SetFont(STANDARD_TEXT_FONT, 10)
  panel.apply_template:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 10, 10)
  panel.apply_template:SetText("Apply Template to All")
  panel.apply_template:SetScript("OnClick", function()
    mainpanel.ApplyTemplateToAll()
    DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00Shagu|cffffffffScan:|cffffaaaa Template applied to all windows!")
  end)

  return panel
end

mainpanel.ApplyTemplateToAll = function()
  local template = ShaguScan_db.global_settings.default_template
  for caption, config in pairs(ShaguScan_db.config) do
    -- Apply template values to existing windows
    config.bar_color_mode = template.bar_color_mode
    config.bar_color_custom = utils.DeepCopy(template.bar_color_custom)
    config.background_alpha = template.background_alpha
    config.background_color = utils.DeepCopy(template.background_color)
    config.background_texture = template.background_texture
    config.border_style = template.border_style
    config.border_color = utils.DeepCopy(template.border_color)
    config.text_font = template.text_font
    config.text_size = template.text_size
    config.text_outline = template.text_outline
    config.text_position = template.text_position
    config.text_format = template.text_format
    config.text_color = utils.DeepCopy(template.text_color)
    config.health_text_enabled = template.health_text_enabled
    config.health_text_position = template.health_text_position
    config.health_text_format = template.health_text_format
    config.frame_shadow = template.frame_shadow
    config.frame_glow = template.frame_glow
  end
end