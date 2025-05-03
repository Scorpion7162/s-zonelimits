local activeZones, currentZones, cooldowns = {}, {}, {}
local playerPed = PlayerPedId()
local cachedCoords = GetEntityCoords(playerPed)
local DEFAULT_COOLDOWN_SHORT = 500
local DEFAULT_COOLDOWN_LONG = 1000

local function isInRestrictedZone(item)
    return currentZones[item] and next(currentZones[item]) ~= nil
end

local function isItemOnCooldown(item)
    return cooldowns[item] and GetGameTimer() < cooldowns[item]
end

local function setItemCooldown(item, ms)
    cooldowns[item] = GetGameTimer() + ms
end

local function handleZoneEntry(item, zoneId)
    currentZones[item] = currentZones[item] or {}
    currentZones[item][zoneId] = true
    TriggerServerEvent('s-zoneitem:enterZone', item, zoneId)
end

local function handleZoneExit(item, zoneId)
    if not currentZones[item] then return end
    currentZones[item][zoneId] = nil
    TriggerServerEvent('s-zoneitem:exitZone', item, zoneId)
    if next(currentZones[item]) == nil then
        currentZones[item] = nil
    end
end

local function cleanupZones()
    for item, zones in pairs(activeZones) do
        for _, zone in pairs(zones) do
            if zone and zone.remove then 
                zone:remove() 
            end
        end
    end
    activeZones, currentZones, cooldowns = {}, {}, {}
end

local function createZone(item, i, zone)
    local zoneId = item .. '_' .. i
    
    return lib.zones.sphere({
        coords = zone.coords,
        radius = zone.radius,
        debug = Config.Debug,
        onEnter = function()
            handleZoneEntry(item, zoneId)
        end,
        onExit = function()
            handleZoneExit(item, zoneId)
        end
    })
end

local function setupZones()
    if not Config or not Config.RestrictedItems then return false end
    
    cleanupZones()
    
    for item, data in pairs(Config.RestrictedItems) do
        if type(data) ~= 'table' or type(data.zones) ~= 'table' then
            goto continue
        end
        
        activeZones[item] = {}
        cooldowns[item] = 0
        
        for i, zone in ipairs(data.zones) do
            if type(zone) ~= 'table' or type(zone.coords) ~= 'vector3' or type(zone.radius) ~= 'number' then
                goto continue
            end
            
            local success, zoneObj = pcall(createZone, item, i, zone)
            
            if success and zoneObj then
                activeZones[item][i] = zoneObj
            end
        end
        
        ::continue::
    end
    
    return true
end

local function verifyItemUsage(item)
    if isItemOnCooldown(item) then return false end
    
    local cooldownShort = Config.CooldownTimes and Config.CooldownTimes.short or DEFAULT_COOLDOWN_SHORT
    setItemCooldown(item, cooldownShort)
    
    if not Config.RestrictedItems[item] then return true end
    
    if not isInRestrictedZone(item) then
        TriggerEvent('ox_inventory:disarm')
        lib.notify({
            title = 'Item Restricted',
            description = Config.RestrictedItems[item].message or "This item is restricted in this area",
            type = 'error'
        })
        return false
    end
    
    TriggerServerEvent('s-zoneitem:verifyUsage', item)
    local cooldownLong = Config.CooldownTimes and Config.CooldownTimes.long or DEFAULT_COOLDOWN_LONG
    setItemCooldown(item, cooldownLong)
    return true
end

RegisterNetEvent('s-zoneitem:syncConfig', function(newConfig)
    if not newConfig then return end
    Config = newConfig
    setupZones()
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    Wait(500)
    setupZones()
    TriggerServerEvent('s-zoneitem:requestConfig')
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    cleanupZones()
end)

AddEventHandler('ox_inventory:usedItem', function(data)
    if type(data) ~= 'table' or not data.name then return end
    
    local item = data.name
    
    if Config.RestrictedItems[item] and not verifyItemUsage(item) then
        TriggerEvent('ox_inventory:disarm')
        return false
    end
end)

CreateThread(function()
    local validationInterval = Config and Config.ValidationInterval or 5000
    local positionUpdateInterval = Config and Config.PositionUpdateInterval or 1000
    local nextValidation, nextPositionUpdate = 0, 0
    
    while true do
        local hasActiveZones = next(currentZones) ~= nil
        local waitTime = hasActiveZones and 250 or 500
        
        Wait(waitTime)
        
        local gameTime = GetGameTimer()
        
        if gameTime > nextPositionUpdate then
            nextPositionUpdate = gameTime + positionUpdateInterval
            playerPed = PlayerPedId()
            cachedCoords = GetEntityCoords(playerPed)
        end
        
        if hasActiveZones and gameTime > nextValidation then
            nextValidation = gameTime + validationInterval
            
            for item in pairs(currentZones) do
                if not Config.RestrictedItems[item] then
                    currentZones[item] = nil
                end
            end
        end
    end
end)

exports('isInItemZone', isInRestrictedZone)
exports('getPlayerZones', function() return currentZones end)