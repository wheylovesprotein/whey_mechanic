local cleaning = false

local function hasCloth()
    return (exports.ox_inventory:Search('count', Config.Clean.item) or 0) > 0
end

local function clean(vehicle)
    if cleaning then return end

    local netId = NetworkGetNetworkIdFromEntity(vehicle)

    if not lib.callback.await('whey_mechanic:server:cleanStart', false, netId) then
        return Mechanic.notify(locale('need_cloth'), 'error')
    end

    cleaning = true

    TaskTurnPedToFaceEntity(cache.ped, vehicle, 800)

    local done = lib.progressBar({
        label = locale('cleaning'),
        duration = Config.Clean.duration,
        canCancel = true,
        useWhileDead = false,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'timetable@floyd@clean_kitchen@base', clip = 'base', flag = 1 },
        prop = { model = `prop_sponge_01`, pos = vec3(0.0, 0.0, -0.01), rot = vec3(90.0, 0.0, 0.0) },
    })

    cleaning = false

    if not done then
        TriggerServerEvent('whey_mechanic:server:cleanCancel')
        return Mechanic.notify(locale('clean_stopped'), 'error')
    end

    if lib.callback.await('whey_mechanic:server:cleanFinish', false, netId) then
        Mechanic.notify(locale('cleaned'), 'success')
    else
        Mechanic.notify(locale('clean_failed'), 'error')
    end
end

RegisterNetEvent('whey_mechanic:client:clean', function(netId)
    if not NetworkDoesEntityExistWithNetworkId(netId) then return end

    local vehicle = NetToVeh(netId)

    if not Mechanic.control(vehicle) then return end

    SetVehicleDirtLevel(vehicle, 0.0)
    WashDecalsFromVehicle(vehicle, 1.0)
end)

exports.ox_target:addGlobalVehicle({
    {
        name = 'whey_mechanic:clean',
        icon = 'fa-solid fa-soap',
        label = locale('target_clean'),
        distance = Config.Clean.distance,
        canInteract = function()
            return not cache.vehicle and not cleaning and hasCloth()
        end,
        onSelect = function(data)
            clean(data.entity)
        end,
    },
})

exports('useCloth', function()
    CreateThread(function()
        if cache.vehicle then
            return Mechanic.notify(locale('exit_vehicle_first'), 'error')
        end

        local vehicle = lib.getClosestVehicle(GetEntityCoords(cache.ped), Config.Clean.distance, false)

        if not vehicle then
            return Mechanic.notify(locale('clean_stand_next'), 'error')
        end

        clean(vehicle)
    end)
end)
