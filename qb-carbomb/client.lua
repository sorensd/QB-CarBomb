local QBCore = exports['qb-core']:GetCoreObject()
local carBombs = {}
local bombModel = "prop_bomb_01" -- Example bomb model
local beepSound = "Beep_Red" -- Example sound

RegisterKeyMapping("placeCarBomb", "Place Car Bomb", "keyboard", "H")
RegisterCommand("placeCarBomb", function()
    local ped = PlayerPedId()
    local weaponHash = GetSelectedPedWeapon(ped)
    local vehicle = QBCore.Functions.GetClosestVehicle()
    
    if weaponHash ~= GetHashKey("weapon_stickybomb") then
        QBCore.Functions.Notify("You must be holding a sticky bomb!", "error")
        return
    end
    
    if vehicle and DoesEntityExist(vehicle) then
        TriggerEvent('qb-car-bomb:placeBomb', vehicle)
    else
        QBCore.Functions.Notify("You must be near a vehicle to place a bomb!", "error")
    end
end, false)

RegisterNetEvent('qb-car-bomb:placeBomb', function(vehicle)
    local ped = PlayerPedId()
    
    if vehicle and DoesEntityExist(vehicle) then
        TaskStartScenarioInPlace(ped, "WORLD_HUMAN_VEHICLE_MECHANIC", 0, true)
        QBCore.Functions.Progressbar("placing_bomb", "Placing Car Bomb...", 5000, false, true, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }, {}, {}, {}, function() -- On Success
            ClearPedTasksImmediately(ped)
            local plate = GetVehicleNumberPlateText(vehicle)
            local netId = VehToNet(vehicle)
            
            -- Remove sticky bomb from inventory
            TriggerServerEvent('qb-car-bomb:removeBombItem')
            
            -- Attach bomb prop
            RequestModel(GetHashKey(bombModel))
            while not HasModelLoaded(GetHashKey(bombModel)) do
                Wait(10)
            end
            local bomb = CreateObject(GetHashKey(bombModel), 0, 0, 0, true, true, true)
            AttachEntityToEntity(bomb, vehicle, 0, 0.0, -1.5, 0.3, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
            SetEntityAsMissionEntity(bomb, true, true)
            
            TriggerServerEvent('qb-car-bomb:syncBomb', plate, netId, ObjToNet(bomb))
            QBCore.Functions.Notify("Car bomb placed! Use your keybind to detonate.", "success")
            
            -- Play quiet beeping sound
            CreateThread(function()
                while DoesEntityExist(bomb) do
                    PlaySoundFromEntity(-1, beepSound, bomb, "DLC_HEIST_HACKING_SOUNDS", 0, 0)
                    Wait(3000) -- Beep every 3 seconds
                end
            end)
        end, function() -- On Cancel
            ClearPedTasksImmediately(ped)
            QBCore.Functions.Notify("Car bomb placement cancelled.", "error")
        end)
    else
        QBCore.Functions.Notify("No vehicle nearby!", "error")
    end
end)

RegisterNetEvent('qb-car-bomb:detonate', function()
    for plate, data in pairs(carBombs) do
        local vehicle = NetToVeh(data.netId)
        local bomb = NetToObj(data.bombId)
        if DoesEntityExist(vehicle) then
            local vehCoords = GetEntityCoords(vehicle)
            AddExplosion(vehCoords.x, vehCoords.y, vehCoords.z, 2, 10.0, true, false, 1.0)
            carBombs[plate] = nil
            if DoesEntityExist(bomb) then
                DeleteEntity(bomb)
            end
            QBCore.Functions.Notify("Boom! Car bomb detonated.", "success")
        end
    end
end)

RegisterKeyMapping("detonateCarBomb", "Detonate Car Bomb", "keyboard", "G")
RegisterCommand("detonateCarBomb", function()
    TriggerServerEvent('qb-car-bomb:detonateAll')
end, false)

RegisterNetEvent('qb-car-bomb:syncBomb', function(plate, netId, bombId)
    carBombs[plate] = {netId = netId, bombId = bombId}
end)