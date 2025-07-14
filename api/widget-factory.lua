-- widget-factory.lua
-- Centralized UI widget creation system for ShaguScan
-- Eliminates 200+ lines of repeated UI creation code throughout the codebase
-- Based on pfUI's widget factory patterns

-- Initialize factory namespace
if not ShaguScan then ShaguScan = {} end
ShaguScan.factory = {}

-- Create styled button with consistent appearance and behavior
-- Replaces 14+ instances of GameMenuButtonTemplate creation
-- Following pfUI's button creation patterns
function ShaguScan.factory.CreateStyledButton(parent, text, width, height, onClick)
  local button = CreateFrame("Button", nil, parent, "GameMenuButtonTemplate")
  button:SetWidth(width or 100)
  button:SetHeight(height or 20)
  button:SetText(text or "")
  
  if onClick then
    button:SetScript("OnClick", onClick)
  end
  
  -- Apply consistent styling (following pfUI patterns)
  if widgets and widgets.backdrop then
    button:SetBackdrop(widgets.backdrop)
    button:SetBackdropColor(0.1, 0.1, 0.1, 1)
    button:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
  end
  
  return button
end

-- Create statusbar with configuration
-- Replaces repeated statusbar creation in ui.lua and testbars.lua (8+ instances)
-- Following pfUI's statusbar creation patterns
function ShaguScan.factory.CreateStatusBarWithConfig(parent, config, guid)
  local bar = CreateFrame("StatusBar", nil, parent)
  
  -- Apply texture (like pfUI's SetStatusBarTexture pattern)
  local texture = config.bar_texture or "Interface\\TargetingFrame\\UI-StatusBar"
  bar:SetStatusBarTexture(texture)
  
  -- Create background texture for missing health
  local bg = bar:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints(bar)
  bg:SetTexture(texture)
  bg:SetVertexColor(0.8, 0.1, 0.1, config.background_alpha or 0.8)
  bar.bg = bg
  
  -- Set initial values
  bar:SetMinMaxValues(0, 100)
  bar:SetValue(100)
  
  -- Apply alpha (both methods for WoW 1.12 compatibility)
  local alpha = config.bar_alpha or 1
  bar:SetAlpha(alpha)
  
  -- Store config reference (like pfUI's frame.config pattern)
  bar.config = config
  bar.guid = guid
  
  return bar
end

-- Create backdrop frame with consistent styling
-- Replaces 20+ instances of backdrop creation across files
-- Following pfUI's backdrop application patterns
function ShaguScan.factory.CreateBackdropFrame(parent, backdropType, width, height, colors)
  local frame = CreateFrame("Frame", nil, parent)
  
  if width then frame:SetWidth(width) end
  if height then frame:SetHeight(height) end
  
  -- Apply backdrop based on type (following pfUI's backdrop system)
  local backdrop
  if backdropType == "dialog" then
    backdrop = {
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true, tileSize = 16, edgeSize = 12,
      insets = { left = 2, right = 2, top = 2, bottom = 2 }
    }
  elseif backdropType == "textborder" then
    backdrop = widgets and widgets.textborder
  else
    backdrop = widgets and widgets.backdrop
  end
  
  if backdrop then
    frame:SetBackdrop(backdrop)
    
    -- Apply colors (like pfUI's color application)
    if colors then
      frame:SetBackdropColor(colors.bg.r or 0.1, colors.bg.g or 0.1, colors.bg.b or 0.1, colors.bg.a or 1)
      frame:SetBackdropBorderColor(colors.border.r or 0.3, colors.border.g or 0.3, colors.border.b or 0.3, colors.border.a or 1)
    else
      frame:SetBackdropColor(0.1, 0.1, 0.1, 1)
      frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    end
  end
  
  return frame
end

-- Create font string with configuration
-- Replaces 16+ instances of CreateFontString with font setup
-- Following pfUI's text creation patterns
function ShaguScan.factory.CreateConfigFontString(parent, config, layer, template)
  local text = parent:CreateFontString(nil, layer or "OVERLAY", template or "GameFontWhite")
  
  -- Apply font configuration using centralized font manager (with fallback)
  if config and ShaguScan.fonts and ShaguScan.fonts.ApplyFont then
    ShaguScan.fonts.ApplyFont(text, config)
  elseif config then
    -- Fallback font application when font manager isn't available
    local fontSize = config.text_size or 12
    local fontOutline = config.text_outline or "OUTLINE"
    text:SetFont(STANDARD_TEXT_FONT, fontSize, fontOutline)
    if config.text_color then
      text:SetTextColor(config.text_color.r or 1, config.text_color.g or 1, config.text_color.b or 1, config.text_color.a or 1)
    end
  end
  
  return text
end

-- Create scrollable container
-- Replaces repeated scroll frame creation in dialogs.lua and mainpanel.lua
-- Following pfUI's scroll container patterns
function ShaguScan.factory.CreateScrollableContainer(parent, width, height)
  local scrollFrame = CreateFrame("ScrollFrame", nil, parent)
  scrollFrame:SetWidth(width or 400)
  scrollFrame:SetHeight(height or 300)
  
  -- Create scroll child
  local scrollChild = CreateFrame("Frame", nil, scrollFrame)
  scrollChild:SetWidth(width or 400)
  scrollChild:SetHeight(1) -- Will be resized as content is added
  scrollFrame:SetScrollChild(scrollChild)
  
  -- Create scroll bar (like pfUI's scrollbar styling)
  local scrollBar = CreateFrame("Slider", nil, scrollFrame)
  scrollBar:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", -5, -16)
  scrollBar:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", -5, 16)
  scrollBar:SetWidth(16)
  scrollBar:SetOrientation("VERTICAL")
  scrollBar:SetMinMaxValues(0, 1)
  scrollBar:SetValue(0)
  scrollBar:SetValueStep(0.1)
  
  -- Apply backdrop to scrollbar
  if widgets and widgets.backdrop then
    scrollBar:SetBackdrop(widgets.backdrop)
    scrollBar:SetBackdropColor(0, 0, 0, 0.5)
    scrollBar:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
  end
  
  -- Scroll bar functionality (following WoW patterns)
  scrollBar:SetScript("OnValueChanged", function()
    local value = this:GetValue()
    local maxScroll = math.max(0, scrollChild:GetHeight() - scrollFrame:GetHeight())
    scrollFrame:SetVerticalScroll(value * maxScroll)
  end)
  
  scrollFrame.scrollBar = scrollBar
  scrollFrame.scrollChild = scrollChild
  
  return scrollFrame
end

-- Create font dropdown with unified behavior
-- Consolidates font dropdown creation from widgets.lua, dialogs.lua, mainpanel.lua
-- Following pfUI's dropdown creation patterns
function ShaguScan.factory.CreateFontDropdown(parent, selectedFont, onChange)
  -- Use centralized font manager for dropdown creation
  return ShaguScan.fonts.CreateFontDropdown(parent, selectedFont, onChange)
end

-- Create health bar with text (complete unit bar)
-- Consolidates the complex bar creation from ui.lua
-- Following pfUI's unitframe creation patterns
function ShaguScan.factory.CreateHealthBar(parent, config, guid, unitName)
  -- Create main frame
  local frame = CreateFrame("Frame", nil, parent)
  frame:SetWidth(config.bar_width or 200)
  frame:SetHeight(config.bar_height or 18)
  
  -- Create statusbar using factory
  local bar = ShaguScan.factory.CreateStatusBarWithConfig(frame, config, guid)
  bar:SetAllPoints(frame)
  frame.bar = bar
  
  -- Create main text
  local text = ShaguScan.factory.CreateConfigFontString(frame, config)
  text:SetPoint("LEFT", bar, "LEFT", 2, 0)
  text:SetJustifyH("LEFT")
  text:SetText(unitName or "Unknown")
  frame.text = text
  
  -- Create health text if enabled
  if config.health_text_enabled then
    local healthText = ShaguScan.factory.CreateConfigFontString(frame, config)
    healthText:SetPoint("RIGHT", bar, "RIGHT", -2, 0)
    healthText:SetJustifyH("RIGHT")
    frame.health_text = healthText
  end
  
  -- Apply border if configured
  if config.border_style and config.border_style ~= "none" then
    local backdrop = utils.GetBorderBackdrop(config)
    if backdrop then
      frame:SetBackdrop(backdrop)
      if config.border_color then
        frame:SetBackdropBorderColor(
          config.border_color.r or 1,
          config.border_color.g or 1, 
          config.border_color.b or 1,
          config.border_color.a or 1
        )
      end
      frame.border = true
    end
  end
  
  -- Store references for settings updater
  frame.config = config
  frame.guid = guid
  
  return frame
end

-- Create dialog window with standard layout
-- Unifies dialog creation from dialogs.lua and mainpanel.lua
-- Following pfUI's dialog patterns
function ShaguScan.factory.CreateDialog(title, width, height, closable, frameName)
  local dialog = CreateFrame("Frame", frameName, UIParent)
  dialog:SetWidth(width or 420)
  dialog:SetHeight(height or 620)
  dialog:SetFrameStrata("DIALOG")
  dialog:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  
  -- Apply backdrop (following pfUI's backdrop system)
  local backdrop = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
  }
  dialog:SetBackdrop(backdrop)
  dialog:SetBackdropColor(0.1, 0.1, 0.1, 1)
  dialog:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
  
  -- Make draggable (like pfUI dialogs)
  dialog:EnableMouse(true)
  dialog:SetMovable(true)
  dialog:RegisterForDrag("LeftButton")
  dialog:SetScript("OnDragStart", function() this:StartMoving() end)
  dialog:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
  
  -- Create title bar
  if title then
    local titleText = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("TOP", dialog, "TOP", 0, -10)
    titleText:SetText(title)
    dialog.title = titleText
  end
  
  -- Create close button if requested
  if closable then
    local closeButton = CreateFrame("Button", nil, dialog, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -5, -5)
    closeButton:SetFrameLevel(dialog:GetFrameLevel() + 10) -- Ensure it's above other content
    dialog.closeButton = closeButton
  end
  
  return dialog
end

-- Create section header for dialog organization
-- Standardizes section headers across dialog and mainpanel
-- Following pfUI's section organization patterns
function ShaguScan.factory.CreateSectionHeader(parent, text, yOffset)
  local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  header:SetText(text or "Section")
  header:SetTextColor(1, 0.8, 0, 1) -- Gold color like pfUI headers
  header:SetJustifyH("LEFT")
  
  if yOffset then
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
  end
  
  return header
end

-- Batch create standard dialog buttons (Save, Delete, Close, etc.)
-- Eliminates repeated button creation in dialogs
-- Following pfUI's action button patterns
function ShaguScan.factory.CreateDialogButtons(parent, buttonConfigs)
  local buttons = {}
  local totalWidth = 0
  
  -- Calculate total width needed
  for i = 1, table.getn(buttonConfigs) do
    totalWidth = totalWidth + (buttonConfigs[i].width or 100) + 10
  end
  
  -- Create buttons with automatic positioning
  local currentX = -(totalWidth / 2) + 50
  for i = 1, table.getn(buttonConfigs) do
    local config = buttonConfigs[i]
    local button = ShaguScan.factory.CreateStyledButton(
      parent, 
      config.text, 
      config.width or 100, 
      config.height or 24, 
      config.onClick
    )
    
    button:SetPoint("BOTTOM", parent, "BOTTOM", currentX, 10)
    currentX = currentX + (config.width or 100) + 10
    
    buttons[config.name or ("button" .. i)] = button
  end
  
  return buttons
end