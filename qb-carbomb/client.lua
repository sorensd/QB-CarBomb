local QBCore = exports['qb-core']:GetCoreObject()
local bombModel = "prop_bomb_01" -- Example bomb model
local beepSound = "Beep_Red" -- Example sound

RegisterKeyMapping("placeCarBomb", "Place Car Bomb on Player", "keyboard", "H")
RegisterCommand("placeCarBomb", function()
    local ped = PlayerPedId()
    local weaponHash = GetSelectedPedWeapon(ped)
    local targetPed = GetClosestPlayer() -- Find the closest player
    
    if weaponHash ~= GetHashKey("weapon_stickybomb") then
        QBCore.Functions.Notify("You must be holding a sticky bomb!", "error")
        return
    end
    
    if targetPed and targetPed ~= -1 then
        TriggerEvent('qb-car-bomb:placeBombOnPlayer', targetPed)
    else
        QBCore.Functions.Notify("No player nearby to place the bomb on!", "error")
    end
end, false)

RegisterNetEvent('qb-car-bomb:placeBombOnPlayer', function(targetPed)
    local ped = PlayerPedId()
    
    if targetPed and DoesEntityExist(targetPed) then
        TaskStartScenarioInPlace(ped, "WORLD_HUMAN_VEHICLE_MECHANIC", 0, true)
        QBCore.Functions.Progressbar("placing_bomb", "Placing Bomb on Player...", 5000, false, true, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }, {}, {}, {}, function() -- On Success
            ClearPedTasksImmediately(ped)
            
            -- Remove sticky bomb from inventory
            TriggerServerEvent('qb-car-bomb:removeBombItem')
            
            -- Attach bomb prop to the player
            RequestModel(GetHashKey(bombModel))
            while not HasModelLoaded(GetHashKey(bombModel)) do
                Wait(10)
            end
            local bomb = CreateObject(GetHashKey(bombModel), 0, 0, 0, true, true, true)
            
            -- Attach the bomb to the player's body (for example, attaching it to the player's back or chest)
            AttachEntityToEntity(bomb, targetPed, 0, 0.0, 0.3, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
            SetEntityAsMissionEntity(bomb, true, true)
            
            local netId = PedToNet(targetPed)
            
            -- Sync the bomb with other players
            TriggerServerEvent('qb-car-bomb:syncBomb', netId, ObjToNet(bomb))
            QBCore.Functions.Notify("Bomb placed on player! Use your keybind to detonate.", "success")
            
            -- Play quiet beeping sound
            CreateThread(function()
                while DoesEntityExist(bomb) do
                    PlaySoundFromEntity(-1, beepSound, bomb, "DLC_HEIST_HACKING_SOUNDS", 0, 0)
                    Wait(3000) -- Beep every 3 seconds
                end
            end)
        end, function() -- On Cancel
            ClearPedTasksImmediately(ped)
            QBCore.Functions.Notify("Bomb placement cancelled.", "error")
        end)
    else
        QBCore.Functions.Notify("Player not found!", "error")
    end
end)

RegisterNetEvent('qb-car-bomb:detonate', function()
    for netId, data in pairs(carBombs) do
        local targetPed = NetToPed(data.netId)
        local bomb = NetToObj(data.bombId)
        if DoesEntityExist(targetPed) then
            local pedCoords = GetEntityCoords(targetPed)
            AddExplosion(pedCoords.x, pedCoords.y, pedCoords.z, 2, 10.0, true, false, 1.0)
            carBombs[netId] = nil
            if DoesEntityExist(bomb) then
                DeleteEntity(bomb)
            end
            QBCore.Functions.Notify("Boom! Bomb detonated on the player.", "success")
        end
    end
end)

RegisterKeyMapping("detonateCarBomb", "Detonate Car Bomb", "keyboard", "G")
RegisterCommand("detonateCarBomb", function()
    TriggerServerEvent('qb-car-bomb:detonateAll')
end, false)

RegisterNetEvent('qb-car-bomb:syncBomb', function(netId, bombId)
    carBombs[netId] = {netId = netId, bombId = bombId}
end)

