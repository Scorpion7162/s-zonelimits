local playerZones = {}
local inv = exports.ox_inventory
local Config = require 'config'

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

local function isPlayerInValidZone(playerId, item)
    return playerZones[playerId] and playerZones[playerId][item] and next(playerZones[playerId][item]) ~= nil
end

RegisterNetEvent('s-zoneitem:verifyUsage', function(item)
    local playerId = source
    if not validateSource(playerId) then return end
    
    local restricted = Config.RestrictedItems[item]
    if not restricted then return end
    
    local isInZone = isPlayerInValidZone(playerId, item)
    
    if not isInZone then
        lib.notify(playerId,{
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

AddEventHandler('ox_inventory:usedItem', function(playerId, name, slotId, metadata)
    if Config.RestrictedItems[name] then
        if not isPlayerInValidZone(playerId, name) then
            local restricted = Config.RestrictedItems[name]
            inv:AddItem(playerId, name, 1, metadata)
            TriggerClientEvent('ox_lib:notify', playerId, {
                title = 'Item Restricted',
                description = restricted.message or "This item is restricted in this area",
                type = 'error'
            })
        end
    end
end)


AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    playerZones = {}
end)