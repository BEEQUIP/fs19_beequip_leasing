BeequipLeasing = Mod:init()

-- BeequipLeasing.debugMode = true

BeequipLeasing:trySource("debugMode.lua", true);

local DEBUG_MODE = true
local MAIN_SETTING_NAME = 'beequipLease'
local DOWNPAYMENT_SETTING_NAME = 'leaseDownpayment'
local TENOR_SETTING_NAME = 'leaseTenor'

-- ESSENTIAL DOCS https://gdn.giants-software.com/documentation_print.php

function BeequipLeasing:loadMap(savegame)
    -- Init the mod
    self:init()

    -- If GlobalCompany is present, delay execution of load event (otherwise execute immediately)
    if g_company ~= nil and type(g_company.addLoadable) == "function" then
        g_company.addLoadable(self, self.load)
    else
        self:load()
    end
end

-- addConfigurationType(string name, string title, function preLoadFunc, function singleItemLoadFunc, function postLoadFunc, integer selectorType)
function BeequipLeasing:init()
    g_configurationManager:addConfigurationType(MAIN_SETTING_NAME, g_i18n:getText("main_setting_title"), nil, nil, nil, nil, ConfigurationUtil.SELECTOR_MULTIOPTION)    
    g_configurationManager:addConfigurationType(DOWNPAYMENT_SETTING_NAME, g_i18n:getText("downpayment_setting_title"), nil, nil, nil, nil, ConfigurationUtil.SELECTOR_MULTIOPTION)
    g_configurationManager:addConfigurationType(TENOR_SETTING_NAME, g_i18n:getText("tenor_setting_title"), nil, nil, nil, nil, ConfigurationUtil.SELECTOR_MULTIOPTION)
end

function BeequipLeasing:load() 

end

function BeequipLeasing:canBeBeequipLeased(storeItem)
    if storeItem == nil then return false end

    return true
end

ShopConfigScreen.setStoreItem = Utils.overwrittenFunction(ShopConfigScreen.setStoreItem, function(self, superFunc, storeItem, vehicle, ...)
    BeequipLeasing:printDebug("SetStoreItem")
    -- if storeItem ~= nil and storeItem.configurations ~= nil and BeequipLeasing:canBeBeequipLeased(storeItem) then
    --     if vehicle == nil then -- I.e. buying (not using workshop)
    --         storeItem.configurations["vehicleBuyCondition"][1].name = BeequipLeasing.l10n.texts.NEW
    --     else
    --         -- vehicle.configurations[CONFIGTYPE_NAME] = 1
    --         -- storeItem.configurations["vehicleBuyCondition"] = nil
    --         -- storeItem.configurations["vehicleBuyCondition"] = storeItem.configurations["vehicleBuyCondition"] or {}
    --         storeItem.configurations["vehicleBuyCondition"][1].name = BeequipLeasing.l10n.texts.USED
    --     end
    -- end

    return superFunc(self, storeItem, vehicle, ...)
end)


-- Function called when bought from store and then added to your vehicle collection
-- set runningLeasingFactor to calculated annuity
-- set 
FSBaseMission.addVehicle = Utils.overwrittenFunction(FSBaseMission.addVehicle, function(currentMission, superFunc, newVehicle)
    if newVehicle ~= nil and newVehicle.configurations ~= nil then

    end 
    return superFunc(currentMission, newVehicle)
end)

local function addConfigOption(name, price, index, isDefault)
    return {
        -- name = g_i18n:getText("configuration_" .. name),
        name = name,
        index = index or 1,
        isDefault = isDefault or false,
        price = price or 0,
        dailyUpkeep = 0,
        desc = ""
    }
end

-- Injecty new config type to all machines via getConfigurationsFromXML event
StoreItemUtil.getConfigurationsFromXML = Utils.overwrittenFunction(StoreItemUtil.getConfigurationsFromXML, function(xmlFile, superFunc, baseXMLName, baseDir, customEnvironment, isMod, storeItem)
	local configurations = superFunc(xmlFile, baseXMLName, baseDir, customEnvironment, isMod, storeItem)

    if BeequipLeasing:canBeBeequipLeased(storeItem) then
        configurations = configurations or {}

        configurations[MAIN_SETTING_NAME] = {
            addConfigOption('Ja', 0, 1, false),
            addConfigOption('Nee', 0, 2, true),
        }

        configurations[DOWNPAYMENT_SETTING_NAME] = {
            addConfigOption('5%', 0, 1, false),
            addConfigOption('10%', 0, 2, false),
            addConfigOption('15%', 0, 3, false),
        }

        configurations[TENOR_SETTING_NAME] = {
            addConfigOption('12', 0, 1, false),
            addConfigOption('24', 0, 2, false),
            addConfigOption('36', 0, 3, false),
            addConfigOption('48', 0, 4, false),
            addConfigOption('60', 0, 5, false),
        }
    end

    return configurations
end)