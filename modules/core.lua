if ShaguScan.disabled then return end

local core = CreateFrame("Frame", nil, WorldFrame)
ShaguScan.core = core

core.guids = {}
core.lastScan = 0
core.lastCleanup = 0

core.add = function(unit)
  local exists, guid = UnitExists(unit)
  if exists and guid then
    core.guids[guid] = GetTime()
  end
end

-- Proactive scanning for nearby enemy players
core.scanNearby = function()
  -- Throttle scanning to prevent spam (max once per 0.2 seconds)
  local now = GetTime()
  if now - core.lastScan < 0.2 then return end
  core.lastScan = now
  
  -- Scan party/raid members for enemy detection
  for i = 1, GetNumPartyMembers() do
    local unit = "party" .. i
    if UnitExists(unit) then
      core.add(unit)
      -- Also scan party member targets (often enemies)
      local target = unit .. "target"
      if UnitExists(target) then
        core.add(target)
      end
    end
  end
  
  -- Scan raid members for enemy detection  
  for i = 1, GetNumRaidMembers() do
    local unit = "raid" .. i
    if UnitExists(unit) then
      core.add(unit)
      -- Also scan raid member targets (often enemies)
      local target = unit .. "target"
      if UnitExists(target) then
        core.add(target)
      end
    end
  end
  
  -- Scan pet targets (pets often target enemies)
  if UnitExists("pet") then
    core.add("pet")
    if UnitExists("pettarget") then
      core.add("pettarget")
    end
  end
  
  -- Scan party/raid pet targets
  for i = 1, GetNumPartyMembers() do
    local pet = "partypet" .. i
    if UnitExists(pet) then
      core.add(pet)
      if UnitExists(pet .. "target") then
        core.add(pet .. "target")
      end
    end
  end
end

-- Clean up old GUIDs for performance
core.cleanup = function()
  -- Only cleanup every 5 seconds
  local now = GetTime()
  if now - core.lastCleanup < 5 then return end
  core.lastCleanup = now
  
  -- Get cleanup time from global settings (default 30 seconds for enemy detection)
  local cleanup_time = 15 -- Shorter for more responsive enemy detection
  if ShaguScan_db and ShaguScan_db.global_settings and ShaguScan_db.global_settings.auto_cleanup_time then
    cleanup_time = math.min(ShaguScan_db.global_settings.auto_cleanup_time, 30) -- Cap at 30 seconds for enemies
  end
  
  -- Remove old GUIDs
  for guid, time in pairs(core.guids) do
    if now - time > cleanup_time then
      core.guids[guid] = nil
    end
  end
end

-- High priority events for enemy detection
core:RegisterEvent("UPDATE_MOUSEOVER_UNIT")    -- Mouseover detection
core:RegisterEvent("PLAYER_TARGET_CHANGED")    -- Target changes
core:RegisterEvent("PLAYER_ENTERING_WORLD")    -- World entry

-- Combat and PvP events (critical for enemy detection)
core:RegisterEvent("UNIT_COMBAT")              -- Combat detection
core:RegisterEvent("PLAYER_REGEN_DISABLED")    -- Entering combat
core:RegisterEvent("PLAYER_REGEN_ENABLED")     -- Leaving combat
core:RegisterEvent("UNIT_FLAGS")               -- PvP flag changes
core:RegisterEvent("UNIT_FACTION")             -- Faction changes

-- Stealth detection events (critical for rogue/druid detection)
core:RegisterEvent("UNIT_AURA")                -- Stealth buffs/debuffs
core:RegisterEvent("SPELLCAST_START")          -- Stealth casting
core:RegisterEvent("SPELLCAST_STOP")           -- Stealth breaking
core:RegisterEvent("SPELLCAST_FAILED")         -- Failed stealth
core:RegisterEvent("SPELLCAST_INTERRUPTED")    -- Interrupted stealth

-- Unit updates (arg1 = unit)
core:RegisterEvent("UNIT_HEALTH")              -- Health changes
core:RegisterEvent("UNIT_NAME_UPDATE")         -- Name updates

-- Party/Raid events for scanning targets
core:RegisterEvent("PARTY_MEMBERS_CHANGED")    -- Party changes
core:RegisterEvent("RAID_ROSTER_UPDATE")       -- Raid changes

core:SetScript("OnEvent", function()
  if event == "UPDATE_MOUSEOVER_UNIT" then
    this.add("mouseover")
  elseif event == "PLAYER_ENTERING_WORLD" then
    this.add("player")
    -- Scan nearby when entering world
    this.scanNearby()
  elseif event == "PLAYER_TARGET_CHANGED" then
    this.add("target")
  elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
    -- Combat state change - scan for enemies
    this.scanNearby()
  elseif event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
    -- Group changed - scan new targets
    this.scanNearby()
  elseif event == "SPELLCAST_START" or event == "SPELLCAST_STOP" or event == "SPELLCAST_FAILED" or event == "SPELLCAST_INTERRUPTED" then
    -- Stealth-related spell events - scan aggressively
    this.add("target")
    this.scanNearby()
  elseif arg1 then
    -- Unit-specific events (arg1 = unit)
    this.add(arg1)
    -- If it's a target-related or stealth event, also scan nearby
    if event == "UNIT_COMBAT" or event == "UNIT_FLAGS" or event == "UNIT_AURA" then
      this.scanNearby()
    end
  end
end)

ShaguScan.core = core
