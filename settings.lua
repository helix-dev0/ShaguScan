if ShaguScan.disabled then return end

local utils = ShaguScan.utils

local settings = {}

SLASH_SHAGUSCAN1, SLASH_SHAGUSCAN2, SLASH_SHAGUSCAN3 = "/scan", "/sscan", "/shaguscan"

SlashCmdList["SHAGUSCAN"] = function(input)
  if input and input ~= '' then
    -- Direct access to specific window config (advanced usage)
    settings.OpenConfig(input)
  else
    -- Show main window/settings (default behavior)
    settings.OpenMainWindow()
  end
end

settings.backdrop = {
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  tile = true, tileSize = 16, edgeSize = 12,
  insets = { left = 2, right = 2, top = 2, bottom = 2 }
}

settings.textborder = {
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  tile = true, tileSize = 16, edgeSize = 8,
  insets = { left = 2, right = 2, top = 2, bottom = 2 }
}

settings.CreateLabel = function(parent, text)
  local label = parent:CreateFontString(nil, 'HIGH', 'GameFontWhite')
  label:SetFont(STANDARD_TEXT_FONT, 9)
  label:SetText(text)
  label:SetHeight(18)
  return label
end

settings.CreateTextBox = function(parent, text)
  local textbox = CreateFrame("EditBox", nil, parent)
  textbox.ShowTooltip = settings.ShowTooltip

  textbox:SetTextColor(1,.8,.2,1)
  textbox:SetJustifyH("RIGHT")
  textbox:SetTextInsets(5,5,5,5)
  textbox:SetBackdrop(settings.textborder)
  textbox:SetBackdropColor(.1,.1,.1,1)
  textbox:SetBackdropBorderColor(.2,.2,.2,1)

  textbox:SetHeight(18)

  textbox:SetFontObject(GameFontNormal)
  textbox:SetFont(STANDARD_TEXT_FONT, 9)
  textbox:SetAutoFocus(false)
  textbox:SetText((text or ""))

  textbox:SetScript("OnEscapePressed", function(self)
    this:ClearFocus()
  end)

  return textbox
end

settings.CreateDropdown = function(parent, options, selectedValue)
  local dropdown = CreateFrame("Frame", nil, parent)
  dropdown:SetHeight(18)
  dropdown:SetBackdrop(settings.textborder)
  dropdown:SetBackdropColor(.1,.1,.1,1)
  dropdown:SetBackdropBorderColor(.2,.2,.2,1)
  dropdown:EnableMouse(true)
  
  -- Current value display
  dropdown.text = dropdown:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  dropdown.text:SetPoint("LEFT", dropdown, "LEFT", 5, 0)
  dropdown.text:SetFont(STANDARD_TEXT_FONT, 9)
  dropdown.text:SetTextColor(1, .8, .2, 1)
  dropdown.text:SetText(selectedValue or options[1])
  
  -- Dropdown arrow
  dropdown.arrow = dropdown:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  dropdown.arrow:SetPoint("RIGHT", dropdown, "RIGHT", -5, 0)
  dropdown.arrow:SetFont(STANDARD_TEXT_FONT, 9)
  dropdown.arrow:SetTextColor(0.7, 0.7, 0.7, 1)
  dropdown.arrow:SetText("▼")
  
  -- Store options and current value
  dropdown.options = options
  dropdown.selectedValue = selectedValue or options[1]
  
  -- Add tooltip support
  dropdown.ShowTooltip = settings.ShowTooltip
  
  -- Click handler to show/hide menu
  dropdown:SetScript("OnMouseDown", function()
    if this.menu and this.menu:IsVisible() then
      this.menu:Hide()
    else
      settings.ShowDropdownMenu(this)
    end
  end)
  
  -- Function to get current value
  dropdown.GetValue = function(self) return self.selectedValue end
  
  -- Function to set value
  dropdown.SetValue = function(self, value)
    self.selectedValue = value
    self.text:SetText(value)
    if self.menu then self.menu:Hide() end
  end
  
  return dropdown
end

settings.ShowDropdownMenu = function(dropdown)
  -- Hide existing menu if any
  if dropdown.menu then
    dropdown.menu:Hide()
  end
  
  -- Create menu frame
  local menu = CreateFrame("Frame", nil, UIParent)
  menu:SetFrameStrata("TOOLTIP")
  
  -- Calculate menu dimensions
  local menuWidth = math.max(dropdown:GetWidth(), 100)
  local menuHeight = math.min(table.getn(dropdown.options) * 18 + 4, 200) -- Max 200 pixels high
  menu:SetWidth(menuWidth)
  menu:SetHeight(menuHeight)
  
  -- Position menu with screen boundary checks
  local dropdownLeft = dropdown:GetLeft()
  local dropdownBottom = dropdown:GetBottom()
  local screenWidth = GetScreenWidth()
  local screenHeight = GetScreenHeight()
  
  -- Check if menu fits below dropdown
  if dropdownBottom - menuHeight < 0 then
    -- Position above dropdown
    menu:SetPoint("BOTTOMLEFT", dropdown, "TOPLEFT", 0, 2)
  else
    -- Position below dropdown
    menu:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)
  end
  
  -- Check if menu fits within screen width
  if dropdownLeft + menuWidth > screenWidth then
    -- Align to right edge of dropdown
    menu:ClearAllPoints()
    if dropdownBottom - menuHeight < 0 then
      menu:SetPoint("BOTTOMRIGHT", dropdown, "TOPRIGHT", 0, 2)
    else
      menu:SetPoint("TOPRIGHT", dropdown, "BOTTOMRIGHT", 0, -2)
    end
  end
  menu:SetBackdrop(settings.backdrop)
  menu:SetBackdropColor(.1,.1,.1,1)
  menu:SetBackdropBorderColor(.3,.3,.3,1)
  menu:EnableMouse(true)
  
  -- Create option buttons
  for i = 1, table.getn(dropdown.options) do
    local option = dropdown.options[i]
    local button = CreateFrame("Button", nil, menu)
    button:SetPoint("TOPLEFT", menu, "TOPLEFT", 2, -(i-1)*18 - 2)
    button:SetWidth(menu:GetWidth() - 4)
    button:SetHeight(18)
    
    -- Button text
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    button.text:SetPoint("LEFT", button, "LEFT", 3, 0)
    button.text:SetFont(STANDARD_TEXT_FONT, 9)
    button.text:SetTextColor(1, 1, 1, 1)
    button.text:SetText(option)
    
    -- Highlight current selection
    if option == dropdown.selectedValue then
      button.text:SetTextColor(1, 1, 0, 1)
    end
    
    -- Click handler
    button:SetScript("OnClick", function()
      dropdown:SetValue(this.option)
    end)
    button.option = option
    
    -- Hover effect
    button:SetScript("OnEnter", function()
      this.text:SetTextColor(1, 1, 0, 1)
    end)
    
    button:SetScript("OnLeave", function()
      if this.option == dropdown.selectedValue then
        this.text:SetTextColor(1, 1, 0, 1)
      else
        this.text:SetTextColor(1, 1, 1, 1)
      end
    end)
  end
  
  -- Store menu reference
  dropdown.menu = menu
  menu:Show()
  
  -- Hide menu when clicking elsewhere or pressing ESC
  menu:SetScript("OnKeyDown", function()
    if arg1 == "ESCAPE" then
      menu:Hide()
    end
  end)
  
  -- Enable keyboard input for ESC handling
  menu:EnableKeyboard(true)
  menu:SetScript("OnShow", function()
    this:SetFocus()
  end)
  
  -- Auto-hide after delay when mouse leaves both dropdown and menu
  menu:SetScript("OnLeave", function()
    this.leaveTime = GetTime()
    this:SetScript("OnUpdate", function()
      if this.leaveTime and GetTime() - this.leaveTime > 0.5 then
        -- Check if mouse is over dropdown (fallback for older WoW versions)
        local mouseOver = false
        if MouseIsOver then
          mouseOver = MouseIsOver(dropdown)
        else
          -- Manual check for 1.12.1 compatibility
          local x, y = GetCursorPosition()
          local scale = UIParent:GetEffectiveScale()
          x, y = x / scale, y / scale
          local left, right, top, bottom = dropdown:GetLeft(), dropdown:GetRight(), dropdown:GetTop(), dropdown:GetBottom()
          mouseOver = (x >= left and x <= right and y >= bottom and y <= top)
        end
        
        if not mouseOver then
          this:Hide()
        end
        this.leaveTime = nil
        this:SetScript("OnUpdate", nil)
      end
    end)
  end)
  
  -- Cancel auto-hide if mouse returns
  menu:SetScript("OnEnter", function()
    this.leaveTime = nil
    this:SetScript("OnUpdate", nil)
  end)
end

settings.ShowTooltip = function(parent, strings)
  GameTooltip:SetOwner(parent, "ANCHOR_RIGHT")
  for id, entry in pairs(strings) do
    if type(entry) == "table" then
      GameTooltip:AddDoubleLine(entry[1], entry[2])
    else
      GameTooltip:AddLine(entry)
    end
  end
  GameTooltip:Show()
end

settings.OpenConfig = function(caption)
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

  -- Create defconfig if new config
  if not ShaguScan_db.config[caption] then
    -- Get template from global settings
    local template = ShaguScan_db.global_settings and ShaguScan_db.global_settings.default_template or {}
    
    -- Create new config with template values
    ShaguScan_db.config[caption] = {
      filter = "npc,infight,alive",
      scale = 1, anchor = "CENTER", x = 0, y = 0, width = 75, height = 12, spacing = 4, maxrow = 20,
      -- Display customization options from template
      bar_texture = template.bar_texture or "Interface\\TargetingFrame\\UI-StatusBar",
      bar_color_mode = template.bar_color_mode or "reaction",
      bar_color_custom = utils.DeepCopy(template.bar_color_custom) or {r=1, g=0.8, b=0.2, a=1},
      background_alpha = template.background_alpha or 0.8,
      background_color = utils.DeepCopy(template.background_color) or {r=0, g=0, b=0, a=1},
      border_style = template.border_style or "default",
      border_color = utils.DeepCopy(template.border_color) or {r=0.2, g=0.2, b=0.2, a=1},
      text_font = template.text_font or STANDARD_TEXT_FONT,
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

  -- Main Dialog
  local dialog = CreateFrame("Frame", "ShaguScanConfigDialog"..caption, UIParent)
  table.insert(UISpecialFrames, "ShaguScanConfigDialog"..caption)

  -- Save Shortcuts
  local config = ShaguScan_db.config[caption]
  local caption = caption

  dialog:SetFrameStrata("DIALOG")
  dialog:SetPoint("CENTER", 0, 0)
  dialog:SetWidth(320)
  dialog:SetHeight(480)

  dialog:EnableMouse(true)
  dialog:RegisterForDrag("LeftButton")
  dialog:SetMovable(true)
  dialog:SetScript("OnDragStart", function() this:StartMoving() end)
  dialog:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)

  dialog:SetBackdrop(settings.backdrop)
  dialog:SetBackdropColor(.2, .2, .2, 1)
  dialog:SetBackdropBorderColor(.2, .2, .2, 1)

  -- Assign functions to dialog
  dialog.CreateTextBox = settings.CreateTextBox
  dialog.CreateLabel = settings.CreateLabel
  dialog.CreateDropdown = settings.CreateDropdown

  -- Save & Reload
  dialog.save = CreateFrame("Button", nil, dialog, "GameMenuButtonTemplate")
  dialog.save:SetWidth(96)
  dialog.save:SetHeight(18)
  dialog.save:SetFont(STANDARD_TEXT_FONT, 10)
  dialog.save:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -8, 8)
  dialog.save:SetText("Save")
  dialog.save:SetScript("OnClick", function()
    local new_caption = dialog.caption:GetText()

    local filter = dialog.filter:GetText()
    local width = dialog.width:GetText()
    local height = dialog.height:GetText()
    local spacing = dialog.spacing:GetText()
    local maxrow = dialog.maxrow:GetText()
    local anchor = dialog.anchor:GetText()
    local scale = dialog.scale:GetText()
    local x = dialog.x:GetText()
    local y = dialog.y:GetText()

    -- New display options
    local bar_color_mode = dialog.bar_color_mode.GetValue()
    local border_style = dialog.border_style.GetValue()
    local text_position = dialog.text_position.GetValue()
    local text_format = dialog.text_format.GetValue()
    local text_size = dialog.text_size:GetText()
    local health_text_enabled = dialog.health_text_enabled.GetValue()
    local frame_shadow = dialog.frame_shadow.GetValue()

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
      bar_texture = config.bar_texture,
      bar_color_mode = bar_color_mode or config.bar_color_mode,
      bar_color_custom = config.bar_color_custom,
      background_alpha = config.background_alpha,
      background_color = config.background_color,
      border_style = border_style or config.border_style,
      border_color = config.border_color,
      text_font = config.text_font,
      text_size = tonumber(text_size) or config.text_size,
      text_outline = config.text_outline,
      text_position = text_position or config.text_position,
      text_format = text_format or config.text_format,
      text_color = config.text_color,
      health_text_enabled = health_text_enabled == "true" or false,
      health_text_position = config.health_text_position,
      health_text_format = config.health_text_format,
      frame_shadow = frame_shadow == "true" or false,
      frame_glow = config.frame_glow
    }

    ShaguScan_db.config[caption] = nil
    ShaguScan_db.config[new_caption] = new_config
    this:GetParent():Hide()
  end)

  -- Delete
  dialog.delete = CreateFrame("Button", nil, dialog, "GameMenuButtonTemplate")
  dialog.delete:SetWidth(96)
  dialog.delete:SetHeight(18)
  dialog.delete:SetFont(STANDARD_TEXT_FONT, 10)
  dialog.delete:SetPoint("BOTTOMLEFT", dialog, "BOTTOMLEFT", 8, 8)
  dialog.delete:SetText("Delete")
  dialog.delete:SetScript("OnClick", function()
    ShaguScan_db.config[caption] = nil
    this:GetParent():Hide()
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

  -- Backdrop
  local backdrop = CreateFrame("Frame", nil, dialog)
  backdrop:SetBackdrop(settings.backdrop)
  backdrop:SetBackdropBorderColor(.2,.2,.2,1)
  backdrop:SetBackdropColor(.2,.2,.2,1)

  backdrop:SetPoint("TOPLEFT", dialog, "TOPLEFT", 8, -40)
  backdrop:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -8, 28)

  backdrop.CreateTextBox = settings.CreateTextBox
  backdrop.CreateLabel = settings.CreateLabel
  backdrop.CreateDropdown = settings.CreateDropdown

  backdrop.pos = 8

  -- Filter
  local label = backdrop:CreateLabel("Filter:")
  label:SetPoint("TOPLEFT", backdrop, 10, -backdrop.pos)

  dialog.filter = backdrop:CreateTextBox(config.filter)
  dialog.filter:SetPoint("TOPLEFT", backdrop, "TOPLEFT", 60, -backdrop.pos)
  dialog.filter:SetPoint("TOPRIGHT", backdrop, "TOPRIGHT", -8, -backdrop.pos)
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

  backdrop.pos = backdrop.pos + 18

  -- Spacer
  backdrop.pos = backdrop.pos + 9

  -- Width
  local label = backdrop:CreateLabel("Width:")
  label:SetPoint("TOPLEFT", backdrop, 10, -backdrop.pos)

  dialog.width = backdrop:CreateTextBox(config.width)
  dialog.width:SetPoint("TOPLEFT", backdrop, "TOPLEFT", 60, -backdrop.pos)
  dialog.width:SetPoint("TOPRIGHT", backdrop, "TOPRIGHT", -8, -backdrop.pos)
  dialog.width:SetScript("OnEnter", function()
    dialog.width:ShowTooltip({
      "Health Bar Width",
      "|cffaaaaaaAn Integer Value in Pixels"
    })
  end)

  dialog.width:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  backdrop.pos = backdrop.pos + 18

  -- Height
  local label = backdrop:CreateLabel("Height:")
  label:SetPoint("TOPLEFT", backdrop, 10, -backdrop.pos)

  dialog.height = backdrop:CreateTextBox(config.height)
  dialog.height:SetPoint("TOPLEFT", backdrop, "TOPLEFT", 60, -backdrop.pos)
  dialog.height:SetPoint("TOPRIGHT", backdrop, "TOPRIGHT", -8, -backdrop.pos)
  dialog.height:SetScript("OnEnter", function()
    dialog.height:ShowTooltip({
      "Health Bar Height",
      "|cffaaaaaaAn Integer Value in Pixels"
    })
  end)

  dialog.height:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  backdrop.pos = backdrop.pos + 18

  -- Spacing
  local label = backdrop:CreateLabel("Spacing:")
  label:SetPoint("TOPLEFT", backdrop, 10, -backdrop.pos)

  dialog.spacing = backdrop:CreateTextBox(config.spacing)
  dialog.spacing:SetPoint("TOPLEFT", backdrop, "TOPLEFT", 60, -backdrop.pos)
  dialog.spacing:SetPoint("TOPRIGHT", backdrop, "TOPRIGHT", -8, -backdrop.pos)
  dialog.spacing:SetScript("OnEnter", function()
    dialog.spacing:ShowTooltip({
      "Spacing Between Health Bars",
      "|cffaaaaaaAn Integer Value in Pixels"
    })
  end)

  dialog.spacing:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  backdrop.pos = backdrop.pos + 18

  -- Max per Row
  local label = backdrop:CreateLabel("Max-Row:")
  label:SetPoint("TOPLEFT", backdrop, 10, -backdrop.pos)

  dialog.maxrow = backdrop:CreateTextBox(config.maxrow)
  dialog.maxrow:SetPoint("TOPLEFT", backdrop, "TOPLEFT", 60, -backdrop.pos)
  dialog.maxrow:SetPoint("TOPRIGHT", backdrop, "TOPRIGHT", -8, -backdrop.pos)
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

  -- Spacer
  backdrop.pos = backdrop.pos + 9

  -- Anchor
  local label = backdrop:CreateLabel("Anchor:")
  label:SetPoint("TOPLEFT", backdrop, 10, -backdrop.pos)

  dialog.anchor = backdrop:CreateTextBox(config.anchor)
  dialog.anchor:SetPoint("TOPLEFT", backdrop, "TOPLEFT", 60, -backdrop.pos)
  dialog.anchor:SetPoint("TOPRIGHT", backdrop, "TOPRIGHT", -8, -backdrop.pos)
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

  backdrop.pos = backdrop.pos + 18

  -- Scale
  local label = backdrop:CreateLabel("Scale:")
  label:SetPoint("TOPLEFT", backdrop, 10, -backdrop.pos)

  dialog.scale = backdrop:CreateTextBox(utils.round(config.scale, 2))
  dialog.scale:SetPoint("TOPLEFT", backdrop, "TOPLEFT", 60, -backdrop.pos)
  dialog.scale:SetPoint("TOPRIGHT", backdrop, "TOPRIGHT", -8, -backdrop.pos)
  dialog.scale:SetScript("OnEnter", function()
    dialog.scale:ShowTooltip({
      "Window Scale",
      "|cffaaaaaaA floating point number, 1 equals 100%"
    })
  end)

  dialog.scale:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  backdrop.pos = backdrop.pos + 18

  -- Position-X
  local label = backdrop:CreateLabel("X-Position:")
  label:SetPoint("TOPLEFT", backdrop, 10, -backdrop.pos)

  dialog.x = backdrop:CreateTextBox(utils.round(config.x, 2))
  dialog.x:SetPoint("TOPLEFT", backdrop, "TOPLEFT", 60, -backdrop.pos)
  dialog.x:SetPoint("TOPRIGHT", backdrop, "TOPRIGHT", -8, -backdrop.pos)
  dialog.x:SetScript("OnEnter", function()
    dialog.x:ShowTooltip({
      "X-Position of Window",
      "|cffaaaaaaA Number in Pixels"
    })
  end)

  dialog.x:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  backdrop.pos = backdrop.pos + 18

  -- Position-Y
  local label = backdrop:CreateLabel("Y-Position:")
  label:SetPoint("TOPLEFT", backdrop, 10, -backdrop.pos)

  dialog.y = backdrop:CreateTextBox(utils.round(config.y, 2))
  dialog.y:SetPoint("TOPLEFT", backdrop, "TOPLEFT", 60, -backdrop.pos)
  dialog.y:SetPoint("TOPRIGHT", backdrop, "TOPRIGHT", -8, -backdrop.pos)
  dialog.y:SetScript("OnEnter", function()
    dialog.y:ShowTooltip({
      "Y-Position of Window",
      "|cffaaaaaaA Number in Pixels"
    })
  end)

  dialog.y:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  backdrop.pos = backdrop.pos + 18

  -- Spacer
  backdrop.pos = backdrop.pos + 9

  -- Bar Color Mode
  local label = backdrop:CreateLabel("Bar Color:")
  label:SetPoint("TOPLEFT", backdrop, 10, -backdrop.pos)

  dialog.bar_color_mode = backdrop:CreateDropdown({"reaction", "class", "custom"}, config.bar_color_mode)
  dialog.bar_color_mode:SetPoint("TOPLEFT", backdrop, "TOPLEFT", 60, -backdrop.pos)
  dialog.bar_color_mode:SetPoint("TOPRIGHT", backdrop, "TOPRIGHT", -8, -backdrop.pos)
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
  backdrop.pos = backdrop.pos + 18

  -- Border Style
  local label = backdrop:CreateLabel("Border:")
  label:SetPoint("TOPLEFT", backdrop, 10, -backdrop.pos)

  dialog.border_style = backdrop:CreateDropdown({"none", "thin", "default", "thick", "glow"}, config.border_style)
  dialog.border_style:SetPoint("TOPLEFT", backdrop, "TOPLEFT", 60, -backdrop.pos)
  dialog.border_style:SetPoint("TOPRIGHT", backdrop, "TOPRIGHT", -8, -backdrop.pos)
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
  backdrop.pos = backdrop.pos + 18

  -- Text Position
  local label = backdrop:CreateLabel("Text Pos:")
  label:SetPoint("TOPLEFT", backdrop, 10, -backdrop.pos)

  dialog.text_position = backdrop:CreateDropdown({"left", "center", "right"}, config.text_position)
  dialog.text_position:SetPoint("TOPLEFT", backdrop, "TOPLEFT", 60, -backdrop.pos)
  dialog.text_position:SetPoint("TOPRIGHT", backdrop, "TOPRIGHT", -8, -backdrop.pos)
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
  backdrop.pos = backdrop.pos + 18

  -- Text Format
  local label = backdrop:CreateLabel("Text Format:")
  label:SetPoint("TOPLEFT", backdrop, 10, -backdrop.pos)

  dialog.text_format = backdrop:CreateDropdown({"level_name", "name_only", "level_only", "health_percent", "health_current"}, config.text_format)
  dialog.text_format:SetPoint("TOPLEFT", backdrop, "TOPLEFT", 60, -backdrop.pos)
  dialog.text_format:SetPoint("TOPRIGHT", backdrop, "TOPRIGHT", -8, -backdrop.pos)
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
  backdrop.pos = backdrop.pos + 18

  -- Text Size
  local label = backdrop:CreateLabel("Text Size:")
  label:SetPoint("TOPLEFT", backdrop, 10, -backdrop.pos)

  dialog.text_size = backdrop:CreateTextBox(config.text_size)
  dialog.text_size:SetPoint("TOPLEFT", backdrop, "TOPLEFT", 60, -backdrop.pos)
  dialog.text_size:SetPoint("TOPRIGHT", backdrop, "TOPRIGHT", -8, -backdrop.pos)
  dialog.text_size:SetScript("OnEnter", function()
    dialog.text_size:ShowTooltip({
      "Text Size",
      "|cffaaaaaaFont size for text display"
    })
  end)
  dialog.text_size:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  backdrop.pos = backdrop.pos + 18

  -- Health Text Enabled
  local label = backdrop:CreateLabel("Health Text:")
  label:SetPoint("TOPLEFT", backdrop, 10, -backdrop.pos)

  dialog.health_text_enabled = backdrop:CreateDropdown({"false", "true"}, config.health_text_enabled and "true" or "false")
  dialog.health_text_enabled:SetPoint("TOPLEFT", backdrop, "TOPLEFT", 60, -backdrop.pos)
  dialog.health_text_enabled:SetPoint("TOPRIGHT", backdrop, "TOPRIGHT", -8, -backdrop.pos)
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
  backdrop.pos = backdrop.pos + 18

  -- Frame Shadow
  local label = backdrop:CreateLabel("Frame Shadow:")
  label:SetPoint("TOPLEFT", backdrop, 10, -backdrop.pos)

  dialog.frame_shadow = backdrop:CreateDropdown({"false", "true"}, config.frame_shadow and "true" or "false")
  dialog.frame_shadow:SetPoint("TOPLEFT", backdrop, "TOPLEFT", 60, -backdrop.pos)
  dialog.frame_shadow:SetPoint("TOPRIGHT", backdrop, "TOPRIGHT", -8, -backdrop.pos)
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
  backdrop.pos = backdrop.pos + 18

  -- Spacer
  backdrop.pos = backdrop.pos + 9

  -- Test Bar Button
  dialog.test_bar = CreateFrame("Button", nil, backdrop, "GameMenuButtonTemplate")
  dialog.test_bar:SetWidth(200)
  dialog.test_bar:SetHeight(18)
  dialog.test_bar:SetFont(STANDARD_TEXT_FONT, 10)
  dialog.test_bar:SetPoint("TOPLEFT", backdrop, "TOPLEFT", 10, -backdrop.pos)
  dialog.test_bar:SetText("Show Test Bar")
  dialog.test_bar:SetScript("OnClick", function()
    settings.CreateTestBar(config, caption)
  end)
  dialog.test_bar:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    GameTooltip:AddLine("Test Bar Preview")
    GameTooltip:AddLine("|cffaaaaaaShows a sample health bar with current visual settings")
    GameTooltip:Show()
  end)
  dialog.test_bar:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

end

settings.CreateTestBar = function(config, caption)
  -- Merge config with defaults
  config = utils.MergeConfigDefaults(config)
  
  -- Create or show existing test bar
  local testBarName = "ShaguScanTestBar" .. caption
  local existing = getglobal(testBarName)
  if existing then
    if existing:IsShown() then 
      existing:Hide() 
    else 
      existing:Show() 
    end
    return
  end
  
  -- Create test bar container
  local testFrame = CreateFrame("Frame", testBarName, UIParent)
  testFrame:SetWidth(config.width + 20)
  testFrame:SetHeight(config.height + 40)
  testFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  testFrame:SetFrameStrata("HIGH")
  testFrame:EnableMouse(true)
  testFrame:SetMovable(true)
  testFrame:RegisterForDrag("LeftButton")
  testFrame:SetScript("OnDragStart", function() this:StartMoving() end)
  testFrame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
  
  -- Background
  testFrame:SetBackdrop(settings.backdrop)
  testFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
  testFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
  
  -- Title
  local title = testFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", testFrame, "TOP", 0, -8)
  title:SetText("Test Bar - " .. caption)
  title:SetTextColor(1, 1, 1, 1)
  
  -- Close button
  local closeBtn = CreateFrame("Button", nil, testFrame, "UIPanelCloseButton")
  closeBtn:SetPoint("TOPRIGHT", testFrame, "TOPRIGHT", -2, -2)
  closeBtn:SetWidth(16)
  closeBtn:SetHeight(16)
  closeBtn:SetScript("OnClick", function() testFrame:Hide() end)
  
  -- Create test health bar using the same function as normal bars
  local testGuid = "test_unit_" .. GetTime()
  local testBar = ShaguScan.ui.CreateBar(testFrame, testGuid, config)
  testBar:SetPoint("CENTER", testFrame, "CENTER", 0, -5)
  testBar:SetWidth(config.width)
  testBar:SetHeight(config.height)
  
  -- Set up test data
  testBar.test_mode = true
  testBar.test_health = 75
  testBar.test_max_health = 100
  testBar.test_name = "Test Enemy"
  testBar.test_level = 60
  testBar.test_class = "WARRIOR"
  testBar.test_reaction = 2 -- Hostile
  
  -- Override the BarUpdate function for test mode
  local originalUpdate = testBar:GetScript("OnUpdate")
  testBar:SetScript("OnUpdate", function()
    if this.test_mode then
      -- Set test values
      this.bar:SetMinMaxValues(0, this.test_max_health)
      this.bar:SetValue(this.test_health)
      
      -- Set test colors
      local hex, r, g, b, a = utils.GetBarColor("player", this.config) -- Use player as test
      this.bar:SetStatusBarColor(r, g, b, a)
      
      -- Set test text
      local text = utils.FormatMainText("player", this.config.text_format, this.config)
      if this.config.text_format == "level_name" then
        text = "|cffff0000" .. this.test_level .. "|r " .. this.test_name
      elseif this.config.text_format == "name_only" then
        text = this.test_name
      elseif this.config.text_format == "level_only" then
        text = "|cffff0000" .. this.test_level .. "|r"
      elseif this.config.text_format == "health_percent" then
        text = floor(this.test_health / this.test_max_health * 100) .. "%"
      elseif this.config.text_format == "health_current" then
        text = this.test_health
      end
      this.text:SetText(text)
      
      -- Set test health text
      if this.config.health_text_enabled and this.health_text then
        local health_text = ""
        if this.config.health_text_format == "percent" then
          health_text = floor(this.test_health / this.test_max_health * 100) .. "%"
        elseif this.config.health_text_format == "current" then
          health_text = this.test_health
        elseif this.config.health_text_format == "current_max" then
          health_text = this.test_health .. "/" .. this.test_max_health
        elseif this.config.health_text_format == "deficit" then
          local deficit = this.test_max_health - this.test_health
          health_text = deficit > 0 and "-" .. deficit or ""
        end
        this.health_text:SetText(health_text)
        this.health_text:Show()
      elseif this.health_text then
        this.health_text:Hide()
      end
      
      -- Set test border color
      if this.border then
        local border_color = this.config.border_color
        this.border:SetBackdropBorderColor(border_color.r, border_color.g, border_color.b, border_color.a)
      end
    else
      -- Use original update function if it exists
      if originalUpdate then
        originalUpdate()
      end
    end
  end)
  
  -- Instructions
  local instructions = testFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  instructions:SetPoint("BOTTOM", testFrame, "BOTTOM", 0, 8)
  instructions:SetText("|cffaaaaaaClick and drag to move • Close when done")
  instructions:SetJustifyH("CENTER")
  
  testFrame:Show()
end

settings.OpenMainWindow = function()
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
  dialog:SetHeight(600)

  dialog:EnableMouse(true)
  dialog:RegisterForDrag("LeftButton")
  dialog:SetMovable(true)
  dialog:SetScript("OnDragStart", function() this:StartMoving() end)
  dialog:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)

  dialog:SetBackdrop(settings.backdrop)
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
  dialog.panel1 = settings.CreateScanWindowPanel(dialog)
  dialog.panel2 = settings.CreateGlobalSettingsPanel(dialog)

  -- Tab switching logic
  dialog.tab1:SetScript("OnClick", function()
    dialog.tab1.active = true
    dialog.tab2.active = false
    dialog.panel1:Show()
    dialog.panel2:Hide()
    settings.UpdateTabAppearance(dialog)
  end)

  dialog.tab2:SetScript("OnClick", function()
    dialog.tab1.active = false
    dialog.tab2.active = true
    dialog.panel1:Hide()
    dialog.panel2:Show()
    settings.UpdateTabAppearance(dialog)
  end)

  -- Show initial tab
  dialog.panel1:Show()
  dialog.panel2:Hide()
  settings.UpdateTabAppearance(dialog)

  dialog:Show()
end

settings.UpdateTabAppearance = function(dialog)
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

settings.CreateScanWindowPanel = function(parent)
  local panel = CreateFrame("Frame", nil, parent)
  panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -70)
  panel:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -10, 10)
  
  panel:SetBackdrop(settings.backdrop)
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
    settings.CreateNewScanWindow()
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
  settings.RefreshWindowList(panel)

  return panel
end

settings.RefreshWindowList = function(panel)
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
    
    button:SetBackdrop(settings.backdrop)
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
      settings.OpenConfig(this.caption)
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
      settings.DeleteScanWindow(this.caption, panel)
    end)
    button.delete.caption = caption

    table.insert(panel.windowButtons, button)
    yOffset = yOffset - 35
  end

  -- Update scroll child height
  panel.scrollChild:SetHeight(math.max(1, math.abs(yOffset)))
end

settings.CreateNewScanWindow = function()
  -- Create a simple dialog to get window name
  local dialog = CreateFrame("Frame", "ShaguScanNewWindowDialog", UIParent)
  dialog:SetFrameStrata("FULLSCREEN_DIALOG")
  dialog:SetFrameLevel(100)
  dialog:SetPoint("CENTER", 0, 0)
  dialog:SetWidth(300)
  dialog:SetHeight(120)
  dialog:EnableMouse(true)
  dialog:SetBackdrop(settings.backdrop)
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
  input:SetBackdrop(settings.textborder)
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
      settings.OpenConfig(name)
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

settings.DeleteScanWindow = function(caption, panel)
  -- Confirmation dialog
  local dialog = CreateFrame("Frame", "ShaguScanDeleteDialog", UIParent)
  dialog:SetFrameStrata("FULLSCREEN_DIALOG")
  dialog:SetFrameLevel(100)
  dialog:SetPoint("CENTER", 0, 0)
  dialog:SetWidth(300)
  dialog:SetHeight(100)
  dialog:EnableMouse(true)
  dialog:SetBackdrop(settings.backdrop)
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
    settings.RefreshWindowList(panel)
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

settings.CreateGlobalSettingsPanel = function(parent)
  -- This is the existing OpenMainConfig content, but as a panel
  local panel = CreateFrame("Frame", nil, parent)
  panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -70)
  panel:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -10, 50)
  
  panel:SetBackdrop(settings.backdrop)
  panel:SetBackdropColor(.2, .2, .2, 1)
  panel:SetBackdropBorderColor(.3, .3, .3, 1)

  -- Save Shortcuts
  local global_config = ShaguScan_db.global_settings

  -- Assign functions to panel
  panel.CreateTextBox = settings.CreateTextBox
  panel.CreateLabel = settings.CreateLabel
  panel.CreateDropdown = settings.CreateDropdown

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
    
    -- Save template settings
    global_config.default_template.bar_color_mode = panel.template_bar_color_mode.GetValue() or global_config.default_template.bar_color_mode
    global_config.default_template.border_style = panel.template_border_style.GetValue() or global_config.default_template.border_style
    global_config.default_template.text_format = panel.template_text_format.GetValue() or global_config.default_template.text_format
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
    settings.ApplyTemplateToAll()
    DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00Shagu|cffffffffScan:|cffffaaaa Template applied to all windows!")
  end)

  return panel
end

settings.OpenMainConfig = function()
  -- Toggle Existing Dialog
  local existing = getglobal("ShaguScanMainConfigDialog")
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
  local dialog = CreateFrame("Frame", "ShaguScanMainConfigDialog", UIParent)
  table.insert(UISpecialFrames, "ShaguScanMainConfigDialog")

  -- Save Shortcuts
  local global_config = ShaguScan_db.global_settings

  dialog:SetFrameStrata("DIALOG")
  dialog:SetPoint("CENTER", 0, 0)
  dialog:SetWidth(400)
  dialog:SetHeight(500)

  dialog:EnableMouse(true)
  dialog:RegisterForDrag("LeftButton")
  dialog:SetMovable(true)
  dialog:SetScript("OnDragStart", function() this:StartMoving() end)
  dialog:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)

  dialog:SetBackdrop(settings.backdrop)
  dialog:SetBackdropColor(.2, .2, .2, 1)
  dialog:SetBackdropBorderColor(.2, .2, .2, 1)

  -- Assign functions to dialog
  dialog.CreateTextBox = settings.CreateTextBox
  dialog.CreateLabel = settings.CreateLabel
  dialog.CreateDropdown = settings.CreateDropdown

  -- Title
  dialog.title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  dialog.title:SetPoint("TOP", dialog, "TOP", 0, -15)
  dialog.title:SetText("ShaguScan - Main Settings")
  dialog.title:SetTextColor(1, 1, 1, 1)

  -- Close button
  dialog.close = CreateFrame("Button", nil, dialog, "UIPanelCloseButton")
  dialog.close:SetWidth(20)
  dialog.close:SetHeight(20)
  dialog.close:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", 0, 0)
  dialog.close:SetScript("OnClick", function()
    this:GetParent():Hide()
  end)

  -- Backdrop
  local backdrop = CreateFrame("Frame", nil, dialog)
  backdrop:SetBackdrop(settings.backdrop)
  backdrop:SetBackdropBorderColor(.2,.2,.2,1)
  backdrop:SetBackdropColor(.2,.2,.2,1)

  backdrop:SetPoint("TOPLEFT", dialog, "TOPLEFT", 8, -40)
  backdrop:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -8, 40)

  backdrop.CreateTextBox = settings.CreateTextBox
  backdrop.CreateLabel = settings.CreateLabel
  backdrop.CreateDropdown = settings.CreateDropdown

  backdrop.pos = 8

  -- Section: General Settings
  local section1 = backdrop:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  section1:SetPoint("TOPLEFT", backdrop, "TOPLEFT", 10, -backdrop.pos)
  section1:SetText("General Settings")
  section1:SetTextColor(1, 1, 0, 1)
  backdrop.pos = backdrop.pos + 20

  -- Auto Cleanup Time
  local label = backdrop:CreateLabel("Cleanup Time:")
  label:SetPoint("TOPLEFT", backdrop, 10, -backdrop.pos)

  dialog.auto_cleanup_time = backdrop:CreateTextBox(global_config.auto_cleanup_time)
  dialog.auto_cleanup_time:SetPoint("TOPLEFT", backdrop, "TOPLEFT", 120, -backdrop.pos)
  dialog.auto_cleanup_time:SetPoint("TOPRIGHT", backdrop, "TOPRIGHT", -8, -backdrop.pos)
  dialog.auto_cleanup_time:SetScript("OnEnter", function()
    dialog.auto_cleanup_time:ShowTooltip({
      "Unit Cleanup Time",
      "|cffaaaaaaTime in seconds to keep old units in memory"
    })
  end)
  dialog.auto_cleanup_time:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  backdrop.pos = backdrop.pos + 18

  -- Max Units Per Window
  local label = backdrop:CreateLabel("Max Units:")
  label:SetPoint("TOPLEFT", backdrop, 10, -backdrop.pos)

  dialog.max_units_per_window = backdrop:CreateTextBox(global_config.max_units_per_window)
  dialog.max_units_per_window:SetPoint("TOPLEFT", backdrop, "TOPLEFT", 120, -backdrop.pos)
  dialog.max_units_per_window:SetPoint("TOPRIGHT", backdrop, "TOPRIGHT", -8, -backdrop.pos)
  dialog.max_units_per_window:SetScript("OnEnter", function()
    dialog.max_units_per_window:ShowTooltip({
      "Maximum Units Per Window",
      "|cffaaaaaaMaximum number of units to display per scan window"
    })
  end)
  dialog.max_units_per_window:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  backdrop.pos = backdrop.pos + 18

  -- Debug Mode
  local label = backdrop:CreateLabel("Debug Mode:")
  label:SetPoint("TOPLEFT", backdrop, 10, -backdrop.pos)

  dialog.debug_mode = backdrop:CreateDropdown({"false", "true"}, global_config.debug_mode and "true" or "false")
  dialog.debug_mode:SetPoint("TOPLEFT", backdrop, "TOPLEFT", 120, -backdrop.pos)
  dialog.debug_mode:SetPoint("TOPRIGHT", backdrop, "TOPRIGHT", -8, -backdrop.pos)
  dialog.debug_mode:SetScript("OnEnter", function()
    dialog.debug_mode:ShowTooltip({
      "Debug Mode",
      "|cffaaaaaaEnable debug messages in chat"
    })
  end)
  dialog.debug_mode:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  backdrop.pos = backdrop.pos + 18

  -- Spacer
  backdrop.pos = backdrop.pos + 15

  -- Section: Default Template
  local section2 = backdrop:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  section2:SetPoint("TOPLEFT", backdrop, "TOPLEFT", 10, -backdrop.pos)
  section2:SetText("Default Template (for new windows)")
  section2:SetTextColor(1, 1, 0, 1)
  backdrop.pos = backdrop.pos + 20

  -- Template Bar Color Mode
  local label = backdrop:CreateLabel("Bar Color:")
  label:SetPoint("TOPLEFT", backdrop, 10, -backdrop.pos)

  dialog.template_bar_color_mode = backdrop:CreateDropdown({"reaction", "class", "custom"}, global_config.default_template.bar_color_mode)
  dialog.template_bar_color_mode:SetPoint("TOPLEFT", backdrop, "TOPLEFT", 120, -backdrop.pos)
  dialog.template_bar_color_mode:SetPoint("TOPRIGHT", backdrop, "TOPRIGHT", -8, -backdrop.pos)
  backdrop.pos = backdrop.pos + 18

  -- Template Border Style
  local label = backdrop:CreateLabel("Border:")
  label:SetPoint("TOPLEFT", backdrop, 10, -backdrop.pos)

  dialog.template_border_style = backdrop:CreateDropdown({"none", "thin", "default", "thick", "glow"}, global_config.default_template.border_style)
  dialog.template_border_style:SetPoint("TOPLEFT", backdrop, "TOPLEFT", 120, -backdrop.pos)
  dialog.template_border_style:SetPoint("TOPRIGHT", backdrop, "TOPRIGHT", -8, -backdrop.pos)
  backdrop.pos = backdrop.pos + 18

  -- Template Text Format
  local label = backdrop:CreateLabel("Text Format:")
  label:SetPoint("TOPLEFT", backdrop, 10, -backdrop.pos)

  dialog.template_text_format = backdrop:CreateDropdown({"level_name", "name_only", "level_only", "health_percent", "health_current"}, global_config.default_template.text_format)
  dialog.template_text_format:SetPoint("TOPLEFT", backdrop, "TOPLEFT", 120, -backdrop.pos)
  dialog.template_text_format:SetPoint("TOPRIGHT", backdrop, "TOPRIGHT", -8, -backdrop.pos)
  backdrop.pos = backdrop.pos + 18

  -- Template Frame Shadow
  local label = backdrop:CreateLabel("Frame Shadow:")
  label:SetPoint("TOPLEFT", backdrop, 10, -backdrop.pos)

  dialog.template_frame_shadow = backdrop:CreateDropdown({"false", "true"}, global_config.default_template.frame_shadow and "true" or "false")
  dialog.template_frame_shadow:SetPoint("TOPLEFT", backdrop, "TOPLEFT", 120, -backdrop.pos)
  dialog.template_frame_shadow:SetPoint("TOPRIGHT", backdrop, "TOPRIGHT", -8, -backdrop.pos)
  backdrop.pos = backdrop.pos + 18

  -- Spacer
  backdrop.pos = backdrop.pos + 15

  -- Save Button
  dialog.save = CreateFrame("Button", nil, dialog, "GameMenuButtonTemplate")
  dialog.save:SetWidth(96)
  dialog.save:SetHeight(18)
  dialog.save:SetFont(STANDARD_TEXT_FONT, 10)
  dialog.save:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -8, 8)
  dialog.save:SetText("Save")
  dialog.save:SetScript("OnClick", function()
    -- Save general settings
    global_config.auto_cleanup_time = tonumber(dialog.auto_cleanup_time:GetText()) or global_config.auto_cleanup_time
    global_config.max_units_per_window = tonumber(dialog.max_units_per_window:GetText()) or global_config.max_units_per_window
    global_config.debug_mode = dialog.debug_mode.GetValue() == "true"
    
    -- Save template settings
    global_config.default_template.bar_color_mode = dialog.template_bar_color_mode.GetValue() or global_config.default_template.bar_color_mode
    global_config.default_template.border_style = dialog.template_border_style.GetValue() or global_config.default_template.border_style
    global_config.default_template.text_format = dialog.template_text_format.GetValue() or global_config.default_template.text_format
    global_config.default_template.frame_shadow = dialog.template_frame_shadow.GetValue() == "true"
    
    DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00Shagu|cffffffffScan:|cffffaaaa Main settings saved!")
    this:GetParent():Hide()
  end)

  -- Apply Template Button
  dialog.apply_template = CreateFrame("Button", nil, dialog, "GameMenuButtonTemplate")
  dialog.apply_template:SetWidth(120)
  dialog.apply_template:SetHeight(18)
  dialog.apply_template:SetFont(STANDARD_TEXT_FONT, 10)
  dialog.apply_template:SetPoint("BOTTOMLEFT", dialog, "BOTTOMLEFT", 8, 8)
  dialog.apply_template:SetText("Apply Template to All")
  dialog.apply_template:SetScript("OnClick", function()
    settings.ApplyTemplateToAll()
    DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00Shagu|cffffffffScan:|cffffaaaa Template applied to all scan windows!")
  end)

  dialog:Show()
end

settings.ApplyTemplateToAll = function()
  if not ShaguScan_db.global_settings or not ShaguScan_db.global_settings.default_template then
    DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00Shagu|cffffffffScan:|cffffaaaa Error: No template available!")
    return
  end
  
  local template = ShaguScan_db.global_settings.default_template
  for caption, config in pairs(ShaguScan_db.config) do
    -- Apply template settings to all existing windows
    for key, value in pairs(template) do
      config[key] = utils.DeepCopy(value)
    end
  end
end

ShaguScan.settings = settings
