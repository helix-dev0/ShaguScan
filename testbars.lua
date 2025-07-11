-- testbars.lua - Test bar functionality for preview and configuration
-- Extracted from settings.lua to reduce file size

local testbars = {}

-- Export the module immediately for proper loading order
ShaguScan.testbars = testbars

-- References to other modules
local utils = ShaguScan.utils

testbars.UpdateTestBar = function(config, caption)
  -- Find the scan window
  local scanWindow = getglobal("ShaguScan" .. caption)
  if not scanWindow then return end
  
  -- Find existing test bar
  local children = { scanWindow:GetChildren() }
  for i = 1, table.getn(children) do
    local child = children[i]
    if child.isTestBar and child:IsShown() then
      -- Update the test bar configuration
      child.config = config
      
      -- Apply texture immediately
      if config.bar_texture and child.bar then
        child.bar:SetStatusBarTexture(config.bar_texture)
        -- Debug: Print texture path being applied
        if ShaguScan_db.global_settings and ShaguScan_db.global_settings.debug_mode then
          DEFAULT_CHAT_FRAME:AddMessage("ShaguScan: Applied texture: " .. tostring(config.bar_texture))
        end
      end
      
      -- Force an immediate update to reflect new settings
      if child.test_mode and child:GetScript("OnUpdate") then
        -- Delay the update to avoid combat feedback conflicts
        child.update_pending = true
      end
      break
    end
  end
end

testbars.UpdateTestBarFromDialog = function(dialog, caption)
  -- Build current config from dialog values
  local config = ShaguScan_db.config[caption] or {}
  
  -- Update config with current dialog values
  if dialog.bar_color_mode and dialog.bar_color_mode.GetValue then
    config.bar_color_mode = dialog.bar_color_mode.GetValue()
  end
  if dialog.bar_texture and dialog.bar_texture.GetTexturePath then
    config.bar_texture = dialog.bar_texture.GetTexturePath()
  end
  if dialog.background_texture and dialog.background_texture.GetValue then
    config.background_texture = dialog.background_texture.GetValue()
  end
  if dialog.border_style and dialog.border_style.GetValue then
    config.border_style = dialog.border_style.GetValue()
  end
  if dialog.text_position and dialog.text_position.GetValue then
    config.text_position = dialog.text_position.GetValue()
  end
  if dialog.text_format and dialog.text_format.GetValue then
    config.text_format = dialog.text_format.GetValue()
  end
  if dialog.text_size and dialog.text_size.GetText then
    config.text_size = tonumber(dialog.text_size:GetText()) or config.text_size
  end
  if dialog.text_font and dialog.text_font.GetFontPath then
    config.text_font = dialog.text_font.GetFontPath()
  end
  if dialog.health_text_enabled and dialog.health_text_enabled.GetValue then
    config.health_text_enabled = dialog.health_text_enabled.GetValue() == "true"
  end
  if dialog.frame_shadow and dialog.frame_shadow.GetValue then
    config.frame_shadow = dialog.frame_shadow.GetValue() == "true"
  end
  
  -- Update test bar with new config
  testbars.UpdateTestBar(config, caption)
  
  -- Also update any real unit bars for this window if they exist
  if ShaguScan.ui and ShaguScan.ui.frames and ShaguScan.ui.frames[caption] then
    local root = ShaguScan.ui.frames[caption]
    for guid, frame in pairs(root.frames or {}) do
      if frame.config and frame.bar then
        frame.config = config
        -- Force texture update
        if config.bar_texture then
          frame.bar:SetStatusBarTexture(config.bar_texture)
        end
        -- Force font update
        if frame.text and config.text_font then
          frame.text:SetFont(config.text_font, config.text_size or 9, config.text_outline or "THINOUTLINE")
        end
        if frame.health_text and config.text_font then
          frame.health_text:SetFont(config.text_font, config.text_size or 9, config.text_outline or "THINOUTLINE")
        end
      end
    end
  end
end

testbars.CreateTestBar = function(config, caption)
  -- Merge config with defaults
  config = utils.MergeConfigDefaults(config)
  
  -- Find or create the actual scan window
  local scanWindow = getglobal("ShaguScan" .. caption)
  if not scanWindow then
    -- Create the scan window if it doesn't exist
    scanWindow = ShaguScan.ui.CreateRoot(UIParent, caption)
    
    -- Store reference to avoid config issues
    ShaguScan_db.config[caption] = config
    
    -- Position and configure the scan window
    scanWindow:SetPoint(config.anchor, UIParent, config.anchor, config.x, config.y)
    scanWindow:SetWidth(config.width + 20)
    scanWindow:SetHeight(config.height + 40)
    scanWindow:SetScale(config.scale)
    
    -- Apply background styling with pfUI integration (ensure it's visible)
    local bg_alpha = math.max(config.background_alpha, 0.5) -- Make background at least 50% visible for test
    if bg_alpha > 0 then
      if pfUI and pfUI.api and pfUI.api.CreateBackdrop then
        -- Use pfUI's backdrop system for test window
        local success = pcall(pfUI.api.CreateBackdrop, scanWindow, nil, true)
        if success and scanWindow.backdrop then
          scanWindow.backdrop:SetBackdropColor(config.background_color.r, config.background_color.g, config.background_color.b, bg_alpha)
          scanWindow.backdrop:SetBackdropBorderColor(config.border_color.r, config.border_color.g, config.border_color.b, config.border_color.a)
        end
      else
        -- Fallback to regular backdrop
        local backdrop = {
          bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
          tile = true, tileSize = 16, 
          insets = { left = 2, right = 2, top = 2, bottom = 2 }
        }
        
        local borderBackdrop = utils.GetBorderBackdrop(config)
        if borderBackdrop then
          backdrop.edgeFile = borderBackdrop.edgeFile
          backdrop.edgeSize = borderBackdrop.edgeSize
          backdrop.insets = borderBackdrop.insets
        end
        
        scanWindow:SetBackdrop(backdrop)
        scanWindow:SetBackdropColor(config.background_color.r, config.background_color.g, config.background_color.b, bg_alpha)
        if borderBackdrop then
          scanWindow:SetBackdropBorderColor(config.border_color.r, config.border_color.g, config.border_color.b, config.border_color.a)
        end
      end
    end
    
    -- Add frame effects if enabled
    if config.frame_shadow then
      utils.CreateFrameShadow(scanWindow, config)
    end
    if config.frame_glow then
      utils.CreateFrameGlow(scanWindow, config)
    end
    
    scanWindow:Show()
  end
  
  -- Check if test bar already exists
  local testBarName = "test_unit_preview"
  local existingTestBar = nil
  
  -- Find existing test bar
  local children = { scanWindow:GetChildren() }
  for i = 1, table.getn(children) do
    local child = children[i]
    if child.isTestBar then
      existingTestBar = child
      break
    end
  end
  
  -- Toggle test bar
  if existingTestBar then
    if existingTestBar:IsShown() then
      existingTestBar:Hide()
    else
      -- Update existing test bar configuration before showing
      existingTestBar.config = config
      
      -- Apply texture immediately to existing test bar
      if config.bar_texture and existingTestBar.bar then
        existingTestBar.bar:SetStatusBarTexture(config.bar_texture)
      end
      
      existingTestBar:Show()
      
      -- Force an immediate update to reflect new settings
      if existingTestBar.test_mode then
        existingTestBar:GetScript("OnUpdate")()
      end
    end
    return
  end
  
  -- Create a single test bar within the scan window
  local testBar = ShaguScan.ui.CreateBar(scanWindow, testBarName, config)
  testBar.isTestBar = true
  testBar:SetPoint("TOP", scanWindow, "TOP", 0, -20)
  testBar:SetWidth(config.width)
  testBar:SetHeight(config.height)
  
  -- Disable combat feedback for test bars to prevent errors
  testBar:UnregisterEvent("UNIT_COMBAT")
  testBar:SetScript("OnEvent", nil)
  
  -- Ensure the correct texture is applied immediately
  if config.bar_texture and testBar.bar then
    testBar.bar:SetStatusBarTexture(config.bar_texture)
  end
  
  -- Force test bar to be visible with proper values
  if testBar.bar then
    testBar.bar:SetMinMaxValues(0, 100)
    testBar.bar:SetValue(60)
    testBar.bar:SetStatusBarColor(0.2, 0.8, 0.2, 1) -- Bright green
    testBar.bar:Show()
  end
  
  -- Set up test data
  testBar.test_mode = true
  testBar.test_health = 60  -- 60% health so you can see both filled and empty portions
  testBar.test_max_health = 100
  testBar.test_name = "Test Enemy Player"
  testBar.test_level = 60
  testBar.test_classification = "normal"
  -- Use player's actual class for test bar
  local _, playerClass = UnitClass("player")
  testBar.test_class = playerClass or "WARRIOR"  -- Fallback to warrior if UnitClass fails
  testBar.test_reaction = 2  -- Hostile for reaction colors
  
  -- Override the update function to show test data
  local originalUpdate = testBar:GetScript("OnUpdate")
  testBar:SetScript("OnUpdate", function()
    if this.test_mode then
      -- Handle delayed updates to avoid combat feedback conflicts
      if this.update_pending then
        this.update_pending = nil
        -- Update frame configuration if needed
        if this.config then
          -- Apply new font settings
          if this.text and this.config.text_font then
            this.text:SetFont(this.config.text_font, this.config.text_size, this.config.text_outline)
          end
          -- Apply new statusbar texture settings
          if this.bar and this.config.bar_texture then
            this.bar:SetStatusBarTexture(this.config.bar_texture)
          end
          -- Background settings are handled by parent frame, not statusbar
        end
      end
      -- ALWAYS set test values in test mode - override any normal bar updates
      if this.bar then
        -- Force test values every frame to override any interference
        this.bar:SetMinMaxValues(0, this.test_max_health or 100)
        this.bar:SetValue(this.test_health or 60)
        
        -- Apply statusbar texture (force apply every frame in test mode)
        if config.bar_texture then
          this.bar:SetStatusBarTexture(config.bar_texture)
        end
        
        -- Set test colors using proper color calculation (ensure visibility)
        local r, g, b, a = 0.2, 0.8, 0.2, 1 -- Bright green default
        if config.bar_color_mode == "custom" then
          r, g, b, a = config.bar_color_custom.r, config.bar_color_custom.g, config.bar_color_custom.b, config.bar_color_custom.a
        elseif config.bar_color_mode == "reaction" then
          -- Use reaction colors (hostile = red)
          if this.test_reaction == 2 then -- Hostile
            r, g, b = 1, 0.2, 0.2 -- Red
          elseif this.test_reaction == 4 then -- Friendly
            r, g, b = 0.2, 1, 0.2 -- Green
          else -- Neutral
            r, g, b = 1, 1, 0.2 -- Yellow
          end
        elseif config.bar_color_mode == "class" then
          -- Use class colors with proper fallbacks
          local class = this.test_class or "WARRIOR"
          if RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] then
            r, g, b = RAID_CLASS_COLORS[class].r, RAID_CLASS_COLORS[class].g, RAID_CLASS_COLORS[class].b
          else
            -- Fallback class colors
            if class == "WARRIOR" then r, g, b = 0.78, 0.61, 0.43
            elseif class == "PALADIN" then r, g, b = 0.96, 0.55, 0.73
            elseif class == "HUNTER" then r, g, b = 0.67, 0.83, 0.45
            elseif class == "ROGUE" then r, g, b = 1, 0.96, 0.41
            elseif class == "PRIEST" then r, g, b = 1, 1, 1
            elseif class == "SHAMAN" then r, g, b = 0, 0.44, 0.87
            elseif class == "MAGE" then r, g, b = 0.41, 0.8, 0.94
            elseif class == "WARLOCK" then r, g, b = 0.58, 0.51, 0.79
            elseif class == "DRUID" then r, g, b = 1, 0.49, 0.04
            else r, g, b = 0.78, 0.61, 0.43 -- Default to warrior
            end
          end
          
          -- Debug for test bars
          if ShaguScan_db.global_settings and ShaguScan_db.global_settings.debug_mode then
            DEFAULT_CHAT_FRAME:AddMessage("ShaguScan: Test bar class color (" .. tostring(class) .. "): " .. tostring(r) .. ", " .. tostring(g) .. ", " .. tostring(b))
          end
        end
        
        -- Force alpha to 1.0 for visibility and apply colors
        this.bar:SetStatusBarColor(r, g, b, 1.0)
        
        -- Debug: Print what we're setting
        if ShaguScan_db.global_settings and ShaguScan_db.global_settings.debug_mode then
          DEFAULT_CHAT_FRAME:AddMessage("ShaguScan: Test bar color: " .. tostring(r) .. ", " .. tostring(g) .. ", " .. tostring(b) .. " | Health: " .. tostring(this.test_health) .. "/" .. tostring(this.test_max_health))
        end
      end
      
      -- Set test text
      if this.text then
        -- Apply font settings
        local font = config.text_font or STANDARD_TEXT_FONT
        local size = config.text_size or 9
        local outline = config.text_outline or "THINOUTLINE"
        this.text:SetFont(font, size, outline)
        
        local text = ""
        local current_health = this.test_health or 60
        local max_health = this.test_max_health or 100
        if config.text_format == "level_name" then
          text = "|cffff0000" .. this.test_level .. "|r " .. this.test_name
        elseif config.text_format == "name_only" then
          text = this.test_name
        elseif config.text_format == "level_only" then
          text = "|cffff0000" .. this.test_level .. "|r"
        elseif config.text_format == "health_percent" then
          text = floor(current_health / max_health * 100) .. "%"
        elseif config.text_format == "health_current" then
          text = current_health
        end
        this.text:SetText(text)
      end
      
      -- Set test health text
      if config.health_text_enabled and this.health_text then
        -- Apply font settings to health text
        local font = config.text_font or STANDARD_TEXT_FONT
        local size = config.text_size or 9
        local outline = config.text_outline or "THINOUTLINE"
        this.health_text:SetFont(font, size, outline)
        
        local health_text = ""
        local current_health = this.test_health or 60
        local max_health = this.test_max_health or 100
        if config.health_text_format == "percent" then
          health_text = floor(current_health / max_health * 100) .. "%"
        elseif config.health_text_format == "current" then
          health_text = current_health
        elseif config.health_text_format == "current_max" then
          health_text = current_health .. "/" .. max_health
        elseif config.health_text_format == "deficit" then
          local deficit = max_health - current_health
          health_text = deficit > 0 and "-" .. deficit or ""
        end
        this.health_text:SetText(health_text)
        this.health_text:Show()
      elseif this.health_text then
        this.health_text:Hide()
      end
      -- In test mode, skip the original update function entirely
      return
    else
      -- Use original update function if it exists
      if originalUpdate then
        originalUpdate()
      end
    end
  end)
  
  testBar:Show()
end