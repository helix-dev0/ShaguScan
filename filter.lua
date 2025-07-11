if ShaguScan.disabled then return end

local filter = { }

filter.player = function(unit)
  return UnitIsPlayer(unit)
end

filter.npc = function(unit)
  return not UnitIsPlayer(unit)
end

filter.infight = function(unit)
  return UnitAffectingCombat(unit)
end

filter.dead = function(unit)
  return UnitIsDead(unit)
end

filter.alive = function(unit)
  return not UnitIsDead(unit)
end

filter.horde = function(unit)
  return UnitFactionGroup(unit) == "Horde"
end

filter.alliance = function(unit)
  return UnitFactionGroup(unit) == "Alliance"
end

filter.hardcore = function(unit)
  local pvpName = UnitPVPName(unit)
  return pvpName and string.find(pvpName, "Still Alive")
end

filter.pve = function(unit)
  return not UnitIsPVP(unit)
end

filter.pvp = function(unit)
  return UnitIsPVP(unit)
end

filter.icon = function(unit)
  return GetRaidTargetIndex(unit) ~= nil
end

filter.normal = function(unit)
  return UnitClassification(unit) == "normal"
end

filter.elite = function(unit)
  local elite = UnitClassification(unit)
  return elite == "elite" or elite == "rareelite"
end

filter.rare = function(unit)
  local elite = UnitClassification(unit)
  return elite == "rare" or elite == "rareelite"
end

filter.rareelite = function(unit)
  return UnitClassification(unit) == "rareelite"
end

filter.worldboss = function(unit)
  return UnitClassification(unit) == "worldboss"
end

filter.hostile = function(unit)
  return UnitIsEnemy("player", unit)
end

filter.neutral = function(unit)
  return not UnitIsEnemy("player", unit) and not UnitIsFriend("player", unit)
end

filter.friendly = function(unit)
  return UnitIsFriend("player", unit)
end

filter.attack = function(unit)
  return UnitCanAttack("player", unit)
end

filter.noattack = function(unit)
  return not UnitCanAttack("player", unit)
end

filter.pet = function(unit)
  local isPlayer = UnitIsPlayer(unit)
  local isControlled = UnitPlayerControlled(unit)
  return not isPlayer and isControlled
end

filter.nopet = function(unit)
  local isPlayer = UnitIsPlayer(unit)
  local isControlled = UnitPlayerControlled(unit)
  return isPlayer or not isControlled
end

filter.human = function(unit)
  local _, race = UnitRace(unit)
  return race == "Human"
end

filter.orc = function(unit)
  local _, race = UnitRace(unit)
  return race == "Orc"
end

filter.dwarf = function(unit)
  local _, race = UnitRace(unit)
  return race == "Dwarf"
end

filter.nightelf = function(unit)
  local _, race = UnitRace(unit)
  return race == "NightElf"
end

filter.undead = function(unit)
  local _, race = UnitRace(unit)
  return race == "Scourge"
end

filter.tauren = function(unit)
  local _, race = UnitRace(unit)
  return race == "Tauren"
end

filter.gnome = function(unit)
  local _, race = UnitRace(unit)
  return race == "Gnome"
end

filter.troll = function(unit)
  local _, race = UnitRace(unit)
  return race == "Troll"
end

filter.goblin = function(unit)
  local _, race = UnitRace(unit)
  return race == "Goblin"
end

filter.highelf = function(unit)
  local _, race = UnitRace(unit)
  return race == "BloodElf"
end

filter.warlock = function(unit)
  if not UnitIsPlayer(unit) then return false end
  local _, class = UnitClass(unit)
  return class == "WARLOCK"
end

filter.warrior = function(unit)
  if not UnitIsPlayer(unit) then return false end
  local _, class = UnitClass(unit)
  return class == "WARRIOR"
end

filter.hunter = function(unit)
  if not UnitIsPlayer(unit) then return false end
  local _, class = UnitClass(unit)
  return class == "HUNTER"
end

filter.mage = function(unit)
  if not UnitIsPlayer(unit) then return false end
  local _, class = UnitClass(unit)
  return class == "MAGE"
end

filter.priest = function(unit)
  if not UnitIsPlayer(unit) then return false end
  local _, class = UnitClass(unit)
  return class == "PRIEST"
end

filter.druid = function(unit)
  if not UnitIsPlayer(unit) then return false end
  local _, class = UnitClass(unit)
  return class == "DRUID"
end

filter.paladin = function(unit)
  if not UnitIsPlayer(unit) then return false end
  local _, class = UnitClass(unit)
  return class == "PALADIN"
end

filter.shaman = function(unit)
  if not UnitIsPlayer(unit) then return false end
  local _, class = UnitClass(unit)
  return class == "SHAMAN"
end

filter.rogue = function(unit)
  if not UnitIsPlayer(unit) then return false end
  local _, class = UnitClass(unit)
  return class == "ROGUE"
end

filter.aggro = function(unit)
  local target = unit .. "target"
  return UnitExists(target) and UnitIsUnit(target, "player")
end

filter.noaggro = function(unit)
  local target = unit .. "target"
  return not UnitExists(target) or not UnitIsUnit(target, "player")
end

filter.pfquest = function(unit)
  if not (pfQuest and pfMap) then return false end
  local name = UnitName(unit)
  return name and pfMap.tooltips[name]
end

filter.range = function(unit)
  return CheckInteractDistance(unit, 4)
end

filter.level = function(unit, args)
  local level = tonumber(args)
  return level and UnitLevel(unit) == level
end

filter.minlevel = function(unit, args)
  local level = tonumber(args)
  return level and UnitLevel(unit) >= level
end

filter.maxlevel = function(unit, args)
  local level = tonumber(args)
  return level and UnitLevel(unit) <= level
end

filter.name = function(unit, name)
  name = strlower(name or "")
  unit = strlower(UnitName(unit) or "")
  return string.find(unit, name) ~= nil
end

ShaguScan.filter = filter
