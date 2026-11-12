local HOOD = 4

local repairing = false

local function repair(vehicle, useKit)
    if repairing then return end

    local netId = NetworkGetNetworkIdFromEntity(vehicle)

    if not lib.callback.await('whey_mechanic:server:repairStart', false, netId, useKit) then
        return Mechanic.notify(useKit and locale('need_kit') or locale('cannot_repair'), 'error')
    end

    repairing = true

    TaskTurnPedToFaceEntity(cache.ped, vehicle, 800)
    SetVehicleDoorOpen(vehicle, HOOD, false, false)

    local done = lib.progressBar({
        label = locale('repairing'),
        duration = Config.Repair.duration,
        canCancel = true,
        useWhileDead = false,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'mini@repair', clip = 'fixing_a_player' },
    })

    SetVehicleDoorShut(vehicle, HOOD, false)
    repairing = false

    if not done then
        TriggerServerEvent('whey_mechanic:server:repairCancel')
        return Mechanic.notify(locale('repair_cancelled'), 'error')
    end

    if lib.callback.await('whey_mechanic:server:repairFinish', false, netId) then
        Mechanic.notify(locale('repaired'), 'success')
    else
        Mechanic.notify(locale('repair_failed'), 'error')
    end
end

RegisterNetEvent('whey_mechanic:client:fix', function(netId)
    if not NetworkDoesEntityExistWithNetworkId(netId) then return end

    local vehicle = NetToVeh(netId)

    if not Mechanic.control(vehicle) then return end

    SetVehicleFixed(vehicle)
    SetVehicleDeformationFixed(vehicle)
    SetVehicleEngineHealth(vehicle, 1000.0)
    SetVehicleBodyHealth(vehicle, 1000.0)
    SetVehiclePetrolTankHealth(vehicle, 1000.0)
    SetVehicleUndriveable(vehicle, false)
end)

exports.ox_target:addGlobalVehicle({
    {
        name = 'whey_mechanic:repair',
        icon = 'fa-solid fa-wrench',
        label = locale('target_repair'),
        distance = Config.Repair.distance,
        canInteract = function()
            return not cache.vehicle and Mechanic.isOnDuty()
        end,
        onSelect = function(data)
            repair(data.entity)
        end,
    },
    {
        name = 'whey_mechanic:sellKit',
        icon = 'fa-solid fa-toolbox',
        label = locale('target_sell_kit'),
        distance = Config.Repair.distance,
        canInteract = function()
            if cache.vehicle or repairing or not Mechanic.isOnDuty() then return false end

            return (exports.ox_inventory:Search('count', Config.Repair.kit) or 0) > 0
        end,
        onSelect = function(data)
            Mechanic.sellKit(data.entity)
        end,
    },
    {
        name = 'whey_mechanic:repairKit',
        icon = 'fa-solid fa-toolbox',
        label = locale('target_use_kit'),
        distance = Config.Repair.distance,
        canInteract = function()
            if cache.vehicle or repairing or Mechanic.isOnDuty() then return false end

            return (exports.ox_inventory:Search('count', Config.Repair.kit) or 0) > 0
        end,
        onSelect = function(data)
            repair(data.entity, true)
        end,
    },
})

exports('useRepairKit', function()
    CreateThread(function()
        if cache.vehicle then
            return Mechanic.notify(locale('exit_vehicle_first'), 'error')
        end

        local vehicle = lib.getClosestVehicle(GetEntityCoords(cache.ped), Config.Repair.distance, false)

        if not vehicle then
            return Mechanic.notify(locale('repair_stand_next'), 'error')
        end

        repair(vehicle, true)
    end)
end)
