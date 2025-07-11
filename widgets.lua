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

widgets.CreateTextBox = function(parent, text)
  local textbox = CreateFrame("EditBox", nil, parent)
  textbox.ShowTooltip = widgets.ShowTooltip

  textbox:SetTextColor(1,.8,.2,1)
  textbox:SetJustifyH("RIGHT")
  textbox:SetTextInsets(5,5,5,5)
  textbox:SetBackdrop(widgets.textborder)
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

widgets.CreateDropdown = function(parent, options, selectedValue)
  local dropdown = CreateFrame("Frame", nil, parent)
  dropdown:SetHeight(18)
  dropdown:SetBackdrop(widgets.textborder)
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
      dropdown.SetValue(this.option)
    end)
    button.option = option
    
    -- Hover effect with menu stability
    button:SetScript("OnEnter", function()
      this.text:SetTextColor(1, 1, 0, 1)
      -- Cancel any pending auto-hide when hovering over buttons
      if menu.leaveTime then
        menu.leaveTime = nil
        menu:SetScript("OnUpdate", nil)
      end
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
  
  -- Set up click-outside detection
  menu.clickFrame = CreateFrame("Frame", nil, UIParent)
  menu.clickFrame:SetFrameStrata("BACKGROUND")
  menu.clickFrame:SetAllPoints(UIParent)
  menu.clickFrame:EnableMouse(true)
  menu.clickFrame:SetScript("OnMouseDown", checkClickOutside)
  
  -- Clean up click frame when menu hides
  menu:SetScript("OnHide", function()
    if this.clickFrame then
      this.clickFrame:Hide()
      this.clickFrame = nil
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
  
  -- Auto-hide after longer delay when mouse leaves both dropdown and menu
  menu:SetScript("OnLeave", function()
    this.leaveTime = GetTime()
    this:SetScript("OnUpdate", function()
      if this.leaveTime and GetTime() - this.leaveTime > 1.5 then -- Increased from 0.5 to 1.5 seconds
        -- Check if mouse is over dropdown or menu (fallback for older WoW versions)
        local mouseOverDropdown = false
        local mouseOverMenu = false
        
        if MouseIsOver then
          mouseOverDropdown = MouseIsOver(dropdown)
          mouseOverMenu = MouseIsOver(this)
        else
          -- Manual check for 1.12.1 compatibility
          local x, y = GetCursorPosition()
          local scale = UIParent:GetEffectiveScale()
          x, y = x / scale, y / scale
          
          -- Check dropdown bounds
          local left, right, top, bottom = dropdown:GetLeft(), dropdown:GetRight(), dropdown:GetTop(), dropdown:GetBottom()
          mouseOverDropdown = (x >= left and x <= right and y >= bottom and y <= top)
          
          -- Check menu bounds
          left, right, top, bottom = this:GetLeft(), this:GetRight(), this:GetTop(), this:GetBottom()
          mouseOverMenu = (x >= left and x <= right and y >= bottom and y <= top)
        end
        
        -- Only hide if mouse is over neither dropdown nor menu
        if not mouseOverDropdown and not mouseOverMenu then
          this:Hide()
        end
        this.leaveTime = nil
        this:SetScript("OnUpdate", nil)
      end
    end)
  end)
  
  -- Cancel auto-hide if mouse returns to menu
  menu:SetScript("OnEnter", function()
    this.leaveTime = nil
    this:SetScript("OnUpdate", nil)
  end)
  
  -- Also cancel auto-hide if mouse returns to dropdown
  dropdown:SetScript("OnEnter", function()
    if dropdown.menu and dropdown.menu.leaveTime then
      dropdown.menu.leaveTime = nil
      dropdown.menu:SetScript("OnUpdate", nil)
    end
  end)
end

ShaguScan.widgets = widgets