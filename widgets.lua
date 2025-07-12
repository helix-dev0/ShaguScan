local widgets = {}

if ShaguScan.disabled then 
  ShaguScan.widgets = widgets
  return 
end

-- Backdrop definitions
widgets.backdrop = {
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  tile = true, tileSize = 16, edgeSize = 12,
  insets = { left = 2, right = 2, top = 2, bottom = 2 }
}

widgets.textborder = {
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  tile = true, tileSize = 16, edgeSize = 8,
  insets = { left = 2, right = 2, top = 2, bottom = 2 }
}

widgets.ShowTooltip = function(parent, strings)
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

widgets.CreateLabel = function(parent, text)
  local label = parent:CreateFontString(nil, 'HIGH', 'GameFontWhite')
  label:SetFont(STANDARD_TEXT_FONT, 9)
  label:SetText(text)
  label:SetHeight(18)
  return label
end

widgets.CreateSectionHeader = function(parent, text)
  -- Create container frame for header with underline
  local container = CreateFrame("Frame", nil, parent)
  container:SetHeight(24)
  container:SetWidth(350) -- Set explicit width to ensure visibility
  
  -- Main header text
  local header = container:CreateFontString(nil, 'HIGH', 'GameFontNormalLarge')
  header:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
  header:SetText(text)
  header:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -2)
  
  -- Use pfUI accent color for headers
  if utils and utils.GetPfUIColors then
    local success, pfui_colors = pcall(utils.GetPfUIColors)
    if success and pfui_colors and pfui_colors.accent then
      header:SetTextColor(pfui_colors.accent.r, pfui_colors.accent.g, pfui_colors.accent.b, pfui_colors.accent.a)
    else
      header:SetTextColor(0.2, 1, 0.8, 1) -- Bright teal fallback
    end
  else
    header:SetTextColor(0.2, 1, 0.8, 1) -- Bright teal fallback
  end
  
  -- Add subtle underline for better visual separation
  local underline = container:CreateTexture(nil, "BACKGROUND")
  underline:SetHeight(1)
  underline:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
  underline:SetPoint("TOPRIGHT", container, "TOPRIGHT", -20, -18)
  underline:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
  underline:SetVertexColor(0.3, 0.8, 0.6, 0.8) -- Subtle teal underline
  
  return container
end

widgets.CreateTextBox = function(parent, text)
  local textbox = CreateFrame("EditBox", nil, parent)
  textbox.ShowTooltip = widgets.ShowTooltip

  -- Use pfUI text color (with fallback if utils not loaded yet)
  if utils and utils.GetPfUIColors then
    local pfui_colors = utils.GetPfUIColors()
    textbox:SetTextColor(pfui_colors.text.r, pfui_colors.text.g, pfui_colors.text.b, pfui_colors.text.a)
  else
    textbox:SetTextColor(1, 1, 1, 1) -- White fallback
  end
  textbox:SetJustifyH("RIGHT")
  textbox:SetTextInsets(5,5,5,5)
  textbox:SetBackdrop(widgets.textborder)
  -- Use pfUI-inspired colors (with fallback if utils not loaded yet)
  if utils and utils.GetPfUIColors then
    local pfui_colors = utils.GetPfUIColors()
    textbox:SetBackdropColor(pfui_colors.background.r, pfui_colors.background.g, pfui_colors.background.b, pfui_colors.background.a)
    textbox:SetBackdropBorderColor(pfui_colors.border.r, pfui_colors.border.g, pfui_colors.border.b, pfui_colors.border.a)
  else
    textbox:SetBackdropColor(0.06, 0.06, 0.06, 0.9) -- pfUI dark background fallback
    textbox:SetBackdropBorderColor(0.2, 0.2, 0.2, 1) -- pfUI border fallback
  end

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

widgets.CreateDropdown = function(parent, options, selectedValue)
  local dropdown = CreateFrame("Frame", nil, parent)
  dropdown:SetHeight(18)
  dropdown:SetBackdrop(widgets.textborder)
  -- Use pfUI-inspired colors (with fallback if utils not loaded yet)
  if utils and utils.GetPfUIColors then
    local pfui_colors = utils.GetPfUIColors()
    dropdown:SetBackdropColor(pfui_colors.background.r, pfui_colors.background.g, pfui_colors.background.b, pfui_colors.background.a)
    dropdown:SetBackdropBorderColor(pfui_colors.border.r, pfui_colors.border.g, pfui_colors.border.b, pfui_colors.border.a)
  else
    dropdown:SetBackdropColor(0.06, 0.06, 0.06, 0.9) -- pfUI dark background fallback
    dropdown:SetBackdropBorderColor(0.2, 0.2, 0.2, 1) -- pfUI border fallback
  end
  dropdown:EnableMouse(true)
  
  -- Current value display
  dropdown.text = dropdown:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  dropdown.text:SetPoint("LEFT", dropdown, "LEFT", 5, 0)
  dropdown.text:SetFont(STANDARD_TEXT_FONT, 9)
  -- Use pfUI text color for dropdown text (with fallback if utils not loaded yet)
  if utils and utils.GetPfUIColors then
    local pfui_colors = utils.GetPfUIColors()
    dropdown.text:SetTextColor(pfui_colors.text.r, pfui_colors.text.g, pfui_colors.text.b, pfui_colors.text.a)
  else
    dropdown.text:SetTextColor(1, 1, 1, 1) -- White fallback
  end
  dropdown.text:SetText(selectedValue or options[1])
  
  -- Dropdown arrow
  dropdown.arrow = dropdown:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  dropdown.arrow:SetPoint("RIGHT", dropdown, "RIGHT", -5, 0)
  dropdown.arrow:SetFont(STANDARD_TEXT_FONT, 9)
  -- Use pfUI text color for dropdown arrow (with fallback if utils not loaded yet)
  if utils and utils.GetPfUIColors then
    local pfui_colors = utils.GetPfUIColors()
    dropdown.arrow:SetTextColor(pfui_colors.text.r, pfui_colors.text.g, pfui_colors.text.b, pfui_colors.text.a)
  else
    dropdown.arrow:SetTextColor(0.8, 0.8, 0.8, 1) -- pfUI text fallback
  end
  dropdown.arrow:SetText("▼")
  
  -- Store options and current value
  dropdown.options = options
  dropdown.selectedValue = selectedValue or options[1]
  
  -- Add tooltip support
  dropdown.ShowTooltip = widgets.ShowTooltip
  
  -- Click handler to show/hide menu
  dropdown:SetScript("OnMouseDown", function()
    if this.menu and this.menu:IsVisible() then
      this.menu:Hide()
    else
      widgets.ShowDropdownMenu(this)
    end
  end)
  
  -- Function to get current value
  dropdown.GetValue = function() return dropdown.selectedValue end
  
  -- Function to set value
  dropdown.SetValue = function(value)
    dropdown.selectedValue = value
    dropdown.text:SetText(value)
    if dropdown.menu then dropdown.menu:Hide() end
    
    -- Call onChange callback if it exists
    if dropdown.onChange then
      dropdown.onChange(value)
    end
  end
  
  return dropdown
end

widgets.CreateFontDropdown = function(parent, selectedValue)
  -- Get font list from utils
  local fontList = ShaguScan.utils.GetPfUIFontList()
  local fontOptions = {}
  
  -- Create options array with font names
  for i = 1, table.getn(fontList) do
    fontOptions[i] = fontList[i].name
  end
  
  -- Create the dropdown
  local dropdown = widgets.CreateDropdown(parent, fontOptions, selectedValue)
  
  -- Store font data for retrieval
  dropdown.fontList = fontList
  
  -- Override GetValue to return font path instead of name
  dropdown.GetFontPath = function()
    local selectedName = dropdown.selectedValue
    for i = 1, table.getn(dropdown.fontList) do
      if dropdown.fontList[i].name == selectedName then
        return dropdown.fontList[i].path
      end
    end
    return STANDARD_TEXT_FONT -- fallback
  end
  
  -- Override SetValue to accept font path and convert to name
  dropdown.SetFontPath = function(fontPath)
    local fontName = "Standard" -- default
    for i = 1, table.getn(dropdown.fontList) do
      if dropdown.fontList[i].path == fontPath then
        fontName = dropdown.fontList[i].name
        break
      end
    end
    dropdown.SetValue(fontName)
    
    -- Call onChange callback if it exists (after setting the value)
    if dropdown.onChange then
      dropdown.onChange(fontName)
    end
  end
  
  -- Override the regular ShowDropdownMenu to add font preview
  local originalShowMenu = dropdown.ShowDropdownMenu or function() widgets.ShowDropdownMenu(dropdown) end
  dropdown.ShowDropdownMenu = function()
    originalShowMenu()
    
    -- Apply font styling to each menu item after menu is created
    if dropdown.menu then
      -- Get all child frames (buttons) from the menu
      local children = { dropdown.menu:GetChildren() }
      for i = 1, table.getn(children) do
        local button = children[i]
        if button and button.text and dropdown.fontList[i] then
          local fontInfo = dropdown.fontList[i]
          if fontInfo.preview and fontInfo.path then
            -- Apply the actual font for preview with error handling
            local success = pcall(button.text.SetFont, button.text, fontInfo.path, 10, "OUTLINE")
            if not success then
              -- Fallback to standard font if custom font fails
              button.text:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
            end
          end
        end
      end
    end
  end
  
  return dropdown
end

widgets.CreateStatusbarDropdown = function(parent, selectedValue)
  -- Get statusbar texture list from utils
  local textureList = ShaguScan.utils.GetPfUIStatusbarTextures()
  local textureOptions = {}
  
  -- Create options array with texture names
  for i = 1, table.getn(textureList) do
    textureOptions[i] = textureList[i].name
  end
  
  -- Create the dropdown
  local dropdown = widgets.CreateDropdown(parent, textureOptions, selectedValue)
  
  -- Store texture data for retrieval
  dropdown.textureList = textureList
  
  -- Override GetValue to return texture path instead of name
  dropdown.GetTexturePath = function()
    local selectedName = dropdown.selectedValue
    for i = 1, table.getn(dropdown.textureList) do
      if dropdown.textureList[i].name == selectedName then
        return dropdown.textureList[i].path
      end
    end
    return "Interface\\TargetingFrame\\UI-StatusBar" -- fallback
  end
  
  -- Override SetValue to accept texture path and convert to name
  dropdown.SetTexturePath = function(texturePath)
    local textureName = "Default" -- default
    for i = 1, table.getn(dropdown.textureList) do
      if dropdown.textureList[i].path == texturePath then
        textureName = dropdown.textureList[i].name
        break
      end
    end
    dropdown.SetValue(textureName)
    
    -- Call onChange callback if it exists (after setting the value)
    if dropdown.onChange then
      dropdown.onChange(textureName)
    end
  end
  
  return dropdown
end

widgets.ShowDropdownMenu = function(dropdown)
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
  menu:SetBackdrop(widgets.backdrop)
  -- Use pfUI-inspired colors with slightly brighter border for menu (with fallback if utils not loaded yet)
  if utils and utils.GetPfUIColors then
    local pfui_colors = utils.GetPfUIColors()
    menu:SetBackdropColor(pfui_colors.background.r, pfui_colors.background.g, pfui_colors.background.b, pfui_colors.background.a)
    menu:SetBackdropBorderColor(pfui_colors.border.r + 0.1, pfui_colors.border.g + 0.1, pfui_colors.border.b + 0.1, pfui_colors.border.a)
  else
    menu:SetBackdropColor(0.06, 0.06, 0.06, 0.9) -- pfUI dark background fallback
    menu:SetBackdropBorderColor(0.3, 0.3, 0.3, 1) -- slightly brighter border fallback
  end
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
    -- Use pfUI text color for button text (with fallback if utils not loaded yet)
    if utils and utils.GetPfUIColors then
      local pfui_colors = utils.GetPfUIColors()
      button.text:SetTextColor(pfui_colors.text.r, pfui_colors.text.g, pfui_colors.text.b, pfui_colors.text.a)
    else
      button.text:SetTextColor(0.8, 0.8, 0.8, 1) -- pfUI text fallback
    end
    button.text:SetText(option)
    
    -- Highlight current selection
    if option == dropdown.selectedValue then
      -- Use pfUI accent color for selected option (with fallback if utils not loaded yet)
      if utils and utils.GetPfUIColors then
        local pfui_colors = utils.GetPfUIColors()
        button.text:SetTextColor(pfui_colors.accent.r, pfui_colors.accent.g, pfui_colors.accent.b, pfui_colors.accent.a)
      else
        button.text:SetTextColor(0.2, 1, 0.8, 1) -- pfUI teal fallback
      end
    end
    
    -- Click handler
    button:SetScript("OnClick", function()
      dropdown.SetValue(this.option)
    end)
    button.option = option
    
    -- Hover effect with menu stability
    button:SetScript("OnEnter", function()
      -- Use pfUI accent color for hover (with fallback if utils not loaded yet)
      if utils and utils.GetPfUIColors then
        local pfui_colors = utils.GetPfUIColors()
        this.text:SetTextColor(pfui_colors.accent.r, pfui_colors.accent.g, pfui_colors.accent.b, pfui_colors.accent.a)
      else
        this.text:SetTextColor(0.2, 1, 0.8, 1) -- pfUI teal fallback
      end
      -- Cancel any pending auto-hide when hovering over buttons
      if menu.leaveTime then
        menu.leaveTime = nil
        menu:SetScript("OnUpdate", nil)
      end
    end)
    
    button:SetScript("OnLeave", function()
      if utils and utils.GetPfUIColors then
        local pfui_colors = utils.GetPfUIColors()
        if this.option == dropdown.selectedValue then
          -- Use pfUI accent color for selected option
          this.text:SetTextColor(pfui_colors.accent.r, pfui_colors.accent.g, pfui_colors.accent.b, pfui_colors.accent.a)
        else
          -- Use pfUI text color for regular options
          this.text:SetTextColor(pfui_colors.text.r, pfui_colors.text.g, pfui_colors.text.b, pfui_colors.text.a)
        end
      else
        if this.option == dropdown.selectedValue then
          this.text:SetTextColor(0.2, 1, 0.8, 1) -- pfUI teal fallback
        else
          this.text:SetTextColor(0.8, 0.8, 0.8, 1) -- pfUI text fallback
        end
      end
    end)
  end
  
  -- Store menu reference
  dropdown.menu = menu
  menu:Show()
  
  -- Add click-outside-to-close functionality
  local function checkClickOutside()
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    x, y = x / scale, y / scale
    
    -- Check if click is outside both dropdown and menu
    local clickedDropdown = false
    local clickedMenu = false
    
    -- Check dropdown bounds
    local left, right, top, bottom = dropdown:GetLeft(), dropdown:GetRight(), dropdown:GetTop(), dropdown:GetBottom()
    if left and right and top and bottom then
      clickedDropdown = (x >= left and x <= right and y >= bottom and y <= top)
    end
    
    -- Check menu bounds
    left, right, top, bottom = menu:GetLeft(), menu:GetRight(), menu:GetTop(), menu:GetBottom()
    if left and right and top and bottom then
      clickedMenu = (x >= left and x <= right and y >= bottom and y <= top)
    end
    
    -- Hide menu if clicked outside both
    if not clickedDropdown and not clickedMenu then
      menu:Hide()
    end
  end
  
  -- Click detection only within the parent dialog
  local dialogParent = dropdown:GetParent()
  if dialogParent then
    menu.clickFrame = CreateFrame("Frame", nil, dialogParent)
    menu.clickFrame:SetFrameStrata("BACKGROUND")
    menu.clickFrame:SetAllPoints(dialogParent)
    menu.clickFrame:EnableMouse(true)
    menu.clickFrame:SetScript("OnMouseDown", function()
      checkClickOutside()
    end)
    
    -- Clean up click frame when menu hides
    menu:SetScript("OnHide", function()
      if this.clickFrame then
        this.clickFrame:Hide()
        this.clickFrame = nil
      end
    end)
  end
  
  -- Also auto-hide after delay as backup
  menu.hideTimer = GetTime() + 5.0
  menu:SetScript("OnUpdate", function()
    if GetTime() > this.hideTimer then
      this:Hide()
      this:SetScript("OnUpdate", nil)
    end
  end)
  
  -- Reset timer when mouse enters menu or dropdown
  menu:SetScript("OnEnter", function()
    this.hideTimer = GetTime() + 5.0
  end)
  
  dropdown:SetScript("OnEnter", function()
    if dropdown.menu then
      dropdown.menu.hideTimer = GetTime() + 5.0
    end
  end)
  
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
  
end

ShaguScan.widgets = widgets