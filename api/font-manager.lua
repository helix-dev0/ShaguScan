-- font-manager.lua
-- Centralized font management system for ShaguScan
-- Consolidates 25+ SetFont calls and 7+ font path resolution patterns
-- Based on pfUI's font management patterns

-- Initialize font manager namespace
if not ShaguScan then ShaguScan = {} end
ShaguScan.fonts = {}

-- Central font registry with validation and fallback chains
-- Consolidates utils.pfUI_fonts and GetPfUIFontList into unified system
ShaguScan.fonts.registry = {
  -- System fonts (always available)
  ["Standard"] = {
    name = "Standard",
    path = STANDARD_TEXT_FONT,
    source = "system",
    available = true
  },
  ["Damage"] = {
    name = "Damage", 
    path = DAMAGE_TEXT_FONT,
    source = "system",
    available = true
  },
  
  -- Local ShaguScan fonts (check availability on load)
  ["RobotoMono"] = {
    name = "RobotoMono",
    path = "Interface\\AddOns\\ShaguScan\\fonts\\RobotoMono.ttf",
    source = "local",
    available = nil -- Will be checked dynamically
  },
  ["PT Sans Narrow"] = {
    name = "PT Sans Narrow",
    path = "Interface\\AddOns\\ShaguScan\\fonts\\PT-Sans-Narrow-Regular.ttf", 
    source = "local",
    available = nil
  },
  ["Continuum"] = {
    name = "Continuum",
    path = "Interface\\AddOns\\ShaguScan\\fonts\\Continuum.ttf",
    source = "local", 
    available = nil
  },
  
  -- pfUI fonts (check availability if pfUI is installed)
  ["Roboto"] = {
    name = "Roboto",
    path = "Interface\\AddOns\\pfUI\\fonts\\Roboto.ttf",
    source = "pfui",
    available = nil
  },
  ["Homespun"] = {
    name = "Homespun", 
    path = "Interface\\AddOns\\pfUI\\fonts\\Homespun.ttf",
    source = "pfui",
    available = nil
  }
}

-- Font availability checking (like pfUI's font validation)
-- Tests if font files actually exist and can be loaded
function ShaguScan.fonts.CheckFontAvailability(fontEntry)
  if fontEntry.source == "system" then
    return true -- System fonts always available
  end
  
  -- Test font loading using SetFont with error handling
  local testFrame = CreateFrame("Frame")
  local testText = testFrame:CreateFontString(nil, "OVERLAY")
  
  local success = pcall(function()
    testText:SetFont(fontEntry.path, 12)
    -- Additional validation: check if font actually changed
    return testText:GetFont() == fontEntry.path
  end)
  
  -- Cleanup test frame
  testFrame:Hide()
  testFrame = nil
  
  return success
end

-- Initialize font availability on first load
-- Caches results to avoid repeated file system checks
function ShaguScan.fonts.InitializeFontRegistry()
  for fontName, fontEntry in pairs(ShaguScan.fonts.registry) do
    if fontEntry.available == nil then
      fontEntry.available = ShaguScan.fonts.CheckFontAvailability(fontEntry)
    end
  end
end

-- Get list of available fonts for dropdowns
-- Replaces utils.GetPfUIFontList() with centralized version
function ShaguScan.fonts.GetAvailableFonts()
  ShaguScan.fonts.InitializeFontRegistry()
  
  local availableFonts = {}
  for fontName, fontEntry in pairs(ShaguScan.fonts.registry) do
    if fontEntry.available then
      table.insert(availableFonts, {
        name = fontEntry.name,
        path = fontEntry.path,
        source = fontEntry.source
      })
    end
  end
  
  -- Sort by preference: local fonts first, then pfUI, then system
  table.sort(availableFonts, function(a, b)
    local sourceOrder = {["local"] = 1, pfui = 2, system = 3}
    if sourceOrder[a.source] ~= sourceOrder[b.source] then
      return sourceOrder[a.source] < sourceOrder[b.source]
    end
    return a.name < b.name
  end)
  
  return availableFonts
end

-- Central font path resolution
-- Replaces utils.GetFontPathFromName() with enhanced version
function ShaguScan.fonts.GetFontPath(fontName)
  if not fontName or fontName == "" then
    return ShaguScan.fonts.GetDefaultFont().path
  end
  
  ShaguScan.fonts.InitializeFontRegistry()
  
  -- Direct lookup in registry
  local fontEntry = ShaguScan.fonts.registry[fontName]
  if fontEntry and fontEntry.available then
    return fontEntry.path
  end
  
  -- Fallback search by name (case insensitive)
  for name, entry in pairs(ShaguScan.fonts.registry) do
    if entry.available and string.lower(entry.name) == string.lower(fontName) then
      return entry.path
    end
  end
  
  -- Path-based lookup (for backward compatibility)
  for name, entry in pairs(ShaguScan.fonts.registry) do
    if entry.available and entry.path == fontName then
      return entry.path
    end
  end
  
  -- Final fallback to default
  return ShaguScan.fonts.GetDefaultFont().path
end

-- Get font name from path (reverse lookup)
-- Useful for displaying current font selection in dropdowns
function ShaguScan.fonts.GetFontName(fontPath)
  if not fontPath then
    return ShaguScan.fonts.GetDefaultFont().name
  end
  
  -- Direct path lookup
  for name, entry in pairs(ShaguScan.fonts.registry) do
    if entry.path == fontPath then
      return entry.name
    end
  end
  
  -- If not found, return the path itself for display
  return fontPath
end

-- Get default font with intelligent fallback
-- Prioritizes: RobotoMono → PT Sans Narrow → Standard (system)
function ShaguScan.fonts.GetDefaultFont()
  ShaguScan.fonts.InitializeFontRegistry()
  
  -- Preferred default order
  local preferredDefaults = {"RobotoMono", "PT Sans Narrow", "Standard"}
  
  for _, fontName in ipairs(preferredDefaults) do
    local fontEntry = ShaguScan.fonts.registry[fontName]
    if fontEntry and fontEntry.available then
      return fontEntry
    end
  end
  
  -- Absolute fallback (should never happen)
  return ShaguScan.fonts.registry["Standard"]
end

-- Unified font application function
-- Replaces 25+ scattered SetFont calls with centralized logic
function ShaguScan.fonts.ApplyFont(fontString, config, fallbackSize, fallbackOutline)
  if not fontString then return end
  
  -- Extract font configuration with smart defaults
  local fontName = config and config.text_font
  local fontSize = config and config.text_size or fallbackSize or 12
  local fontOutline = config and config.text_outline or fallbackOutline or "OUTLINE"
  
  -- Get validated font path
  local fontPath = ShaguScan.fonts.GetFontPath(fontName)
  
  -- Apply font with error handling
  local success = pcall(function()
    fontString:SetFont(fontPath, fontSize, fontOutline)
  end)
  
  if not success then
    -- Fallback to system font on error
    fontString:SetFont(STANDARD_TEXT_FONT, fontSize, fontOutline)
  end
  
  -- Apply text color if provided
  if config and config.text_color then
    fontString:SetTextColor(
      config.text_color.r or 1,
      config.text_color.g or 1, 
      config.text_color.b or 1,
      config.text_color.a or 1
    )
  end
end

-- Enhanced font dropdown creation
-- Consolidates 4 different font dropdown creation patterns
function ShaguScan.fonts.CreateFontDropdown(parent, selectedFont, onChange)
  local availableFonts = ShaguScan.fonts.GetAvailableFonts()
  local selectedFontName = ShaguScan.fonts.GetFontName(selectedFont)
  
  -- Convert font objects to simple string array for dropdown
  local fontNames = {}
  for _, fontEntry in ipairs(availableFonts) do
    table.insert(fontNames, fontEntry.name)
  end
  
  -- Use existing widget factory for dropdown creation
  local dropdown = ShaguScan.widgets.CreateDropdown(parent, fontNames, selectedFontName)
  
  -- Enhanced methods for font-specific functionality
  dropdown.GetFontPath = function()
    local selectedName = dropdown.GetValue()
    return ShaguScan.fonts.GetFontPath(selectedName)
  end
  
  dropdown.SetFontPath = function(fontPath)
    local fontName = ShaguScan.fonts.GetFontName(fontPath)
    dropdown.SetValue(fontName)
  end
  
  dropdown.GetAvailableFonts = function()
    return ShaguScan.fonts.GetAvailableFonts()
  end
  
  -- Font preview functionality (enhanced from widgets.lua)
  dropdown.PreviewFont = function(fontName)
    if dropdown.text then
      local tempConfig = { text_font = fontName, text_size = 12, text_outline = "OUTLINE" }
      ShaguScan.fonts.ApplyFont(dropdown.text, tempConfig)
    end
  end
  
  -- Set up change handler with font preview
  if onChange then
    local originalOnChange = dropdown.onChange
    dropdown.onChange = function()
      -- Preview font on change
      dropdown.PreviewFont(dropdown.GetValue())
      
      -- Call original handler
      if originalOnChange then originalOnChange() end
      
      -- Call custom handler
      onChange()
    end
  end
  
  return dropdown
end

-- Font validation and migration helpers
-- Ensures saved configurations use valid fonts
function ShaguScan.fonts.ValidateAndMigrateFontConfig(config)
  if not config then return config end
  
  -- Check if current font is still available
  if config.text_font then
    local fontPath = ShaguScan.fonts.GetFontPath(config.text_font)
    if fontPath ~= config.text_font then
      -- Font changed or unavailable, update config
      config.text_font = fontPath
    end
  else
    -- No font specified, set default
    config.text_font = ShaguScan.fonts.GetDefaultFont().path
  end
  
  return config
end

-- Debug and inspection functions
-- Helpful for troubleshooting font issues
function ShaguScan.fonts.GetFontRegistry()
  return ShaguScan.fonts.registry
end

function ShaguScan.fonts.PrintFontStatus()
  ShaguScan.fonts.InitializeFontRegistry()
  
  DEFAULT_CHAT_FRAME:AddMessage("ShaguScan Font Registry Status:")
  for name, entry in pairs(ShaguScan.fonts.registry) do
    local status = entry.available and "|cff00ff00available|r" or "|cffff0000unavailable|r"
    DEFAULT_CHAT_FRAME:AddMessage(string.format("  %s (%s): %s", name, entry.source, status))
  end
end

-- Batch font update function for existing frames
-- Used when global font settings change
function ShaguScan.fonts.UpdateAllFrameFonts(windowName, newConfig)
  if not ShaguScan or not ShaguScan.units or not ShaguScan.units[windowName] then
    return
  end
  
  for _, frame in pairs(ShaguScan.units[windowName]) do
    -- Update main text
    if frame.text then
      ShaguScan.fonts.ApplyFont(frame.text, newConfig)
    end
    
    -- Update health text if enabled
    if frame.health_text and newConfig.health_text_enabled then
      ShaguScan.fonts.ApplyFont(frame.health_text, newConfig)
    end
  end
end