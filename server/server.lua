local playerZones = {}
local inv = exports.ox_inventory

local function validateSource(source)
    return source and source > 0 and GetPlayerPed(source) ~= 0
end

local function ensurePlayerData(playerId)
    if not validateSource(playerId) then return false end
    
    if not playerZones[playerId] then
        playerZones[playerId] = {}
    end
    
    return true
end

AddEventHandler('playerDropped', function()
    playerZones[source] = nil
end)

RegisterNetEvent('s-zoneitem:requestConfig', function()
    local playerId = source
    if not validateSource(playerId) then return end
    
    TriggerClientEvent('s-zoneitem:syncConfig', playerId, Config)
end)

RegisterNetEvent('s-zoneitem:enterZone', function(item, zoneId)
    local playerId = source
    if not ensurePlayerData(playerId) or not Config.RestrictedItems[item] then return end
    
    if not playerZones[playerId][item] then
        playerZones[playerId][item] = {}
    end
    
    playerZones[playerId][item][zoneId] = true
end)

RegisterNetEvent('s-zoneitem:exitZone', function(item, zoneId)
    local playerId = source
    if not validateSource(playerId) or not playerZones[playerId] or not playerZones[playerId][item] then return end
    
    playerZones[playerId][item][zoneId] = nil
    
    if next(playerZones[playerId][item]) == nil then
        playerZones[playerId][item] = nil
        
        if next(playerZones[playerId]) == nil then
            playerZones[playerId] = nil
        end
    end
end)

local function verifyPlayerInZone(coords, zone)
    return #(coords - zone.coords) <= zone.radius
end

local function isPlayerInValidZone(playerId, item)
    if not validateSource(playerId) or not playerZones[playerId] or not playerZones[playerId][item] then return false end
    
    local itemConfig = Config.RestrictedItems[item]
    if not itemConfig or not itemConfig.zones then return false end
    
    local playerCoords = GetEntityCoords(GetPlayerPed(playerId))
    if not playerCoords then return false end
    
    local validZoneFound = false
    local toRemove = {}
    
    for zoneId in pairs(playerZones[playerId][item]) do
        local index = tonumber(zoneId:match("_(%d+)$"))
        
        if index and itemConfig.zones[index] then
            if verifyPlayerInZone(playerCoords, itemConfig.zones[index]) then
                validZoneFound = true
            else
                toRemove[zoneId] = true
            end
        else
            toRemove[zoneId] = true
        end
    end
    
    for zoneId in pairs(toRemove) do
        playerZones[playerId][item][zoneId] = nil
    end
    
    if next(playerZones[playerId][item]) == nil then
        playerZones[playerId][item] = nil
        if next(playerZones[playerId]) == nil then
            playerZones[playerId] = nil
        end
    end
    
    return validZoneFound
end

RegisterNetEvent('s-zoneitem:verifyUsage', function(item)
    local playerId = source
    if not validateSource(playerId) then return end
    
    local restricted = Config.RestrictedItems[item]
    if not restricted then return end
    
    local isInZone = isPlayerInValidZone(playerId, item)
    
    if not isInZone then
        TriggerClientEvent('ox_lib:notify', playerId, {
            title = 'Item Restricted',
            description = restricted.message or "This item is restricted in this area",
            type = 'error'
        })
        return false
    end
    
    return true
end)

exports('checkItemZone', function(playerId, item)
    if not validateSource(playerId) then return false end
    if not Config.RestrictedItems[item] then return true end
    return isPlayerInValidZone(playerId, item)
end)

AddEventHandler('onServerResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    if Config == nil then
        Config = {
            RestrictedItems = {},
            Debug = false,
            ValidationInterval = 5000,
            PositionUpdateInterval = 1000,
            CooldownTimes = {
                short = 500,
                long = 1000
            }
        }
    end
    
    for item in pairs(Config.RestrictedItems) do
        inv.registerUsage(item, function(playerId)
            return isPlayerInValidZone(playerId, item)
        end)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    playerZones = {}
end)