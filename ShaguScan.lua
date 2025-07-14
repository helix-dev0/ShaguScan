-- ShaguScan Bootstrap
-- Initializes the addon namespace and core systems

ShaguScan = CreateFrame("Frame", nil, UIParent)
ShaguScan:RegisterEvent("ADDON_LOADED")

-- Initialize core namespaces
ShaguScan.core = {}
ShaguScan.ui = {}
ShaguScan.filter = {}
ShaguScan.config = {}
ShaguScan.api = {}
ShaguScan.modules = {}

-- Version information
ShaguScan.version = "1.0"

-- Initialize saved variables
ShaguScan_db = {}

-- Global compatibility functions
ShaguScan.GetEnvironment = function(self)
  return getfenv(1)
end

-- Module registration system
ShaguScan.RegisterModule = function(name, module)
  if ShaguScan.modules[name] then
    error("Module " .. name .. " already exists")
  end
  ShaguScan.modules[name] = module
end

-- Initialize bootup flag
ShaguScan.bootup = true