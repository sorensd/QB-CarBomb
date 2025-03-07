local QBCore = exports['qb-core']:GetCoreObject()
local carBombs = {}

RegisterNetEvent('qb-car-bomb:syncBomb', function(plate, netId, bombId)
    carBombs[plate] = {netId = netId, bombId = bombId}
    TriggerClientEvent('qb-car-bomb:syncBomb', -1, plate, netId, bombId)
end)

RegisterNetEvent('qb-car-bomb:detonateAll', function()
    TriggerClientEvent('qb-car-bomb:detonate', -1)
    carBombs = {}
end)

RegisterNetEvent('qb-car-bomb:removeBombItem', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        if Player.Functions.RemoveItem("weapon_stickybomb", 1) then
            TriggerClientEvent('inventory:client:ItemBox', src, exports['qb-core']:GetSharedObject().Items["weapon_stickybomb"], "remove")
            print("Removed weapon_stickybomb from player: " .. src)
        else
            print("Failed to remove weapon_stickybomb from player: " .. src)
        end
    end
end)