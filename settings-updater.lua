-- settings-updater.lua
-- Unified settings update system for ShaguScan
-- Replaces 50+ lines of repeated update code throughout the codebase
-- Based on pfUI's modular UpdateConfig patterns

-- Initialize updater namespace
if not ShaguScan then ShaguScan = {} end
ShaguScan.updater = {}

-- Main function to apply configuration changes to existing frames
-- This replaces the repeated update logic in dialogs.lua save function
-- Follows pfUI's pattern of updating frames in-place rather than recreating them
function ShaguScan.updater.ApplyConfigToFrame(frame, newConfig)
  if not frame or not newConfig then return end
  
  -- Update frame config reference (like pfUI's frame.config pattern)
  frame.config = newConfig
  
  -- Apply all visual updates through specialized functions
  -- This modular approach follows pfUI's UpdateConfig pattern
  ShaguScan.updater.UpdateBarAppearance(frame, newConfig)
  ShaguScan.updater.UpdateTextSettings(frame, newConfig)
  ShaguScan.updater.UpdateBorderSettings(frame, newConfig)
  ShaguScan.updater.UpdateBackgroundSettings(frame, newConfig)
  ShaguScan.updater.UpdateEffects(frame, newConfig)
  
  -- Trigger frame refresh if available
  if frame.OnUpdate then
    frame.OnUpdate()
  end
end

-- Update statusbar appearance (texture, color, alpha)
-- Follows pfUI's pattern of updating bar properties in-place
function ShaguScan.updater.UpdateBarAppearance(frame, config)
  if not frame.bar then return end
  
  -- Texture updates (like pfUI's SetStatusBarTexture pattern)
  if config.bar_texture and config.bar_texture ~= "" then
    frame.bar:SetStatusBarTexture(config.bar_texture)
    -- Update background texture to match
    if frame.bar.bg then
      frame.bar.bg:SetTexture(config.bar_texture)
    end
  end
  
  -- Color updates (like pfUI's color application pattern)
  if config.bar_color_mode == "custom" and config.bar_color_custom then
    frame.bar:SetStatusBarColor(
      config.bar_color_custom.r, 
      config.bar_color_custom.g, 
      config.bar_color_custom.b, 
      config.bar_alpha or 1
    )
  end
  
  -- Alpha updates (both SetStatusBarColor alpha and SetAlpha for WoW 1.12)
  local alpha = config.bar_alpha or 1
  frame.bar:SetAlpha(alpha)
  
  -- Background alpha (preserve red for missing health like pfUI's backdrop pattern)
  if frame.bar.bg then
    frame.bar.bg:SetVertexColor(0.8, 0.1, 0.1, config.background_alpha or 0.8)
  end
end

-- Update text settings (font, color, position)
-- Handles both main text and health text with unified logic
function ShaguScan.updater.UpdateTextSettings(frame, config)
  -- Update main text
  ShaguScan.updater.UpdateSingleText(frame.text, config, config.text_position, frame)
  
  -- Handle health text creation/removal/updates
  if config.health_text_enabled then
    -- Create health text if it doesn't exist
    if not frame.health_text then
      frame.health_text = frame:CreateFontString(nil, "OVERLAY")
    end
    frame.health_text:Show()
    ShaguScan.updater.UpdateSingleText(frame.health_text, config, config.health_text_position, frame)
  elseif frame.health_text then
    -- Hide health text if disabled
    frame.health_text:Hide()
  end
end

-- Helper function to update a single text object
-- Eliminates repeated text update code throughout the codebase
-- Follows pfUI's pattern of centralized text property updates
function ShaguScan.updater.UpdateSingleText(textObj, config, position, parentFrame)
  if not textObj or not parentFrame then return end
  
  -- Font updates (using existing GetFontPathFromName helper)
  local fontPath = utils.GetFontPathFromName(config.text_font)
  if fontPath then
    textObj:SetFont(fontPath, config.text_size or 12, config.text_outline or "OUTLINE")
  else
    textObj:SetFont(STANDARD_TEXT_FONT, config.text_size or 12, config.text_outline or "OUTLINE")
  end
  
  -- Color updates (like pfUI's SetTextColor pattern)
  if config.text_color then
    textObj:SetTextColor(
      config.text_color.r or 1, 
      config.text_color.g or 1, 
      config.text_color.b or 1, 
      config.text_color.a or 1
    )
  end
  
  -- Position updates (following pfUI's ClearAllPoints pattern)
  textObj:ClearAllPoints()
  if position == "center" then
    textObj:SetPoint("CENTER", parentFrame.bar, "CENTER", 0, 0)
    textObj:SetJustifyH("CENTER")
  elseif position == "right" then
    textObj:SetPoint("RIGHT", parentFrame.bar, "RIGHT", -2, 0)
    textObj:SetJustifyH("RIGHT")
  else -- left (default)
    textObj:SetPoint("LEFT", parentFrame.bar, "LEFT", 2, 0)
    textObj:SetJustifyH("LEFT")
  end
end

-- Update border settings
-- Follows pfUI's SetBackdrop and SetBackdropBorderColor pattern
function ShaguScan.updater.UpdateBorderSettings(frame, config)
  if not frame.border then return end
  
  -- Get backdrop configuration
  local backdrop = utils.GetBorderBackdrop(config)
  if backdrop then
    -- Update backdrop (like pfUI's backdrop updates)
    frame:SetBackdrop(backdrop)
    
    -- Update border color (following pfUI's color application pattern)
    if config.border_color then
      frame:SetBackdropBorderColor(
        config.border_color.r or 1,
        config.border_color.g or 1, 
        config.border_color.b or 1,
        config.border_color.a or 1
      )
    end
  else
    -- Remove border if none specified
    frame:SetBackdrop(nil)
  end
end

-- Update background settings
-- Handles background texture and alpha updates
function ShaguScan.updater.UpdateBackgroundSettings(frame, config)
  if not frame.bar or not frame.bar.bg then return end
  
  -- Background alpha (like pfUI's backdrop alpha pattern)
  local bgAlpha = config.background_alpha or 0.8
  
  -- Background color (preserve red for missing health)
  if config.background_color then
    frame.bar.bg:SetVertexColor(
      config.background_color.r or 0.8,
      config.background_color.g or 0.1, 
      config.background_color.b or 0.1,
      bgAlpha
    )
  else
    -- Default red background for missing health
    frame.bar.bg:SetVertexColor(0.8, 0.1, 0.1, bgAlpha)
  end
end

-- Update special effects (glow, shadow)
-- Follows pfUI's effect application patterns
function ShaguScan.updater.UpdateEffects(frame, config)
  -- Frame glow effect
  if config.frame_glow and frame.glow then
    frame.glow:Show()
  elseif frame.glow then
    frame.glow:Hide()
  end
  
  -- Frame shadow effect  
  if config.frame_shadow and frame.shadow then
    frame.shadow:Show()
  elseif frame.shadow then
    frame.shadow:Hide()
  end
end

-- Batch update function for multiple frames
-- Useful for applying template changes to all windows
-- Follows pfUI's batch update patterns
function ShaguScan.updater.ApplyConfigToAllFrames(windowName, newConfig)
  if not ShaguScan or not ShaguScan.units or not ShaguScan.units[windowName] then
    return
  end
  
  -- Apply to all unit frames in this window
  for _, frame in pairs(ShaguScan.units[windowName]) do
    ShaguScan.updater.ApplyConfigToFrame(frame, newConfig)
  end
end

-- Utility function to parse color strings (like pfUI's color parsing)
-- Handles both table format and string format colors
function ShaguScan.updater.ParseColor(colorData)
  if type(colorData) == "table" then
    return colorData.r or 1, colorData.g or 1, colorData.b or 1, colorData.a or 1
  elseif type(colorData) == "string" then
    -- Parse comma-separated color string (like pfUI)
    local r, g, b, a = string.split(",", colorData)
    return tonumber(r) or 1, tonumber(g) or 1, tonumber(b) or 1, tonumber(a) or 1
  else
    return 1, 1, 1, 1 -- default white
  end
end

-- Debug function to validate frame updates
-- Helps ensure all configuration changes are applied correctly
function ShaguScan.updater.ValidateFrameConfig(frame, expectedConfig)
  if not frame or not expectedConfig then return false end
  
  -- Basic validation that frame has expected properties
  local valid = true
  
  if frame.config ~= expectedConfig then
    print("ShaguScan Debug: Frame config reference mismatch")
    valid = false
  end
  
  if expectedConfig.bar_texture and frame.bar and frame.bar:GetTexture() ~= expectedConfig.bar_texture then
    print("ShaguScan Debug: Bar texture not applied correctly")
    valid = false
  end
  
  return valid
end