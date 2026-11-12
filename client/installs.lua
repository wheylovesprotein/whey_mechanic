local HOOD = 4
local READY_STATE = 'whey_mechanic:ready'
local ANIM_DICT = 'mini@repair'
local ANIM_CLIP = 'fixing_a_player'
local WATCH = 500
local NO_REPLY = { ok = false, msg = locale('no_reply') }
local OFF_DUTY = locale('not_on_duty')

local tabletOpen = false
local fitting

local function closeTablet()
    if not tabletOpen then return end

    tabletOpen = false
    SetNuiFocus(false, false)
    Mechanic.send('tablet:close')
end

local function refreshTablet()
    local list = lib.callback.await('whey_mechanic:server:requests', false)

    if not tabletOpen then return end

    if list == false then
        closeTablet()
        return Mechanic.notify(locale('need_tablet_duty'), 'error')
    end

    Mechanic.send('tablet:list', list or {})
end

local function openTablet()
    if tabletOpen or fitting then return end

    if not Mechanic.isOnDuty() then
        return Mechanic.notify(OFF_DUTY, 'error')
    end

    if (exports.ox_inventory:Search('count', Config.Install.item) or 0) < 1 then
        return Mechanic.notify(locale('need_tablet'), 'error')
    end

    tabletOpen = true
    SetNuiFocus(true, true)
    Mechanic.send('tablet:open')
    refreshTablet()
end

if Config.Install.command then
    RegisterCommand(Config.Install.command, openTablet, false)
end

exports('useTablet', function()
    CreateThread(openTablet)
end)

RegisterNUICallback('tablet:close', function(_, cb)
    cb(1)
    closeTablet()
end)

RegisterNUICallback('tablet:refresh', function(_, cb)
    cb(1)
    refreshTablet()
end)

RegisterNUICallback('tablet:bill', function(data, cb)
    cb(lib.callback.await('whey_mechanic:server:billRequest', false, data.id) or NO_REPLY)
end)

RegisterNUICallback('tablet:decline', function(data, cb)
    cb(lib.callback.await('whey_mechanic:server:declineRequest', false, data.id) or NO_REPLY)
end)

RegisterNetEvent('whey_mechanic:client:requestsChanged', function(notice)
    if notice then
        Mechanic.notify(notice)
    end

    if tabletOpen then
        refreshTablet()
    end
end)

local function hasPaidParts(vehicle)
    local ready = GlobalState[READY_STATE]

    if not ready then return false end

    local plate = (GetVehicleNumberPlateText(vehicle):gsub('^%s+', ''):gsub('%s+$', ''))

    return ready[plate] == true
end

local function stopFitting()
    local current = fitting

    if not current then return end

    fitting = nil
    SetNuiFocus(false, false)
    Mechanic.send('install:close')
    StopAnimTask(cache.ped, ANIM_DICT, ANIM_CLIP, 1.0)
    RemoveAnimDict(ANIM_DICT)

    if DoesEntityExist(current.vehicle) then
        SetVehicleDoorShut(current.vehicle, HOOD, false)
    end

    return current
end

local function watchFitting()
    local mine = fitting
    local reach = Config.Install.distance + 3.0

    CreateThread(function()
        while fitting == mine do
            local vehicle = mine.vehicle
            local gone = not DoesEntityExist(vehicle) or IsEntityDead(cache.ped)

            if gone or #(GetEntityCoords(cache.ped) - GetEntityCoords(vehicle)) > reach then
                stopFitting()
                TriggerServerEvent('whey_mechanic:server:installCancel')
                Mechanic.notify(locale('install_left'), 'error')
                break
            end

            Wait(WATCH)
        end
    end)
end

local function startFitting(vehicle)
    if fitting or tabletOpen then return end

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    local ok, info = lib.callback.await('whey_mechanic:server:installStart', false, netId)

    if not ok then
        return Mechanic.notify(info or locale('cannot_fit_vehicle'), 'error')
    end

    fitting = { vehicle = vehicle, netId = netId }

    TaskTurnPedToFaceEntity(cache.ped, vehicle, 800)
    Wait(800)

    SetVehicleDoorOpen(vehicle, HOOD, false, false)
    lib.requestAnimDict(ANIM_DICT)
    TaskPlayAnim(cache.ped, ANIM_DICT, ANIM_CLIP, 8.0, -8.0, -1, 1, 0, false, false, false)

    SetNuiFocus(true, true)
    Mechanic.send('install:start', {
        seconds = info.seconds,
        penalty = info.penalty,
        parts = info.parts,
        vehicle = Mechanic.vehicleName(vehicle),
        plate = GetVehicleNumberPlateText(vehicle),
    })

    watchFitting()
end

RegisterNUICallback('install:done', function(data, cb)
    cb(1)

    local current = stopFitting()

    if not current then return end

    if data.ok ~= true then
        TriggerServerEvent('whey_mechanic:server:installCancel')

        local reason = data.reason == 'time' and locale('install_timeout') or locale('install_cancelled')

        return Mechanic.notify(reason, 'error')
    end

    local result = lib.callback.await('whey_mechanic:server:installFinish', false, current.netId) or NO_REPLY

    Mechanic.notify(result.msg, result.ok and 'success' or 'error')
end)

exports.ox_target:addGlobalVehicle({
    {
        name = 'whey_mechanic:install',
        icon = 'fa-solid fa-screwdriver-wrench',
        label = locale('target_install'),
        distance = Config.Install.distance,
        canInteract = function(entity)
            return not cache.vehicle and not fitting and Mechanic.isOnDuty() and hasPaidParts(entity)
        end,
        onSelect = function(data)
            startFitting(data.entity)
        end,
    },
})

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    if tabletOpen or fitting then
        SetNuiFocus(false, false)
    end

    if fitting then
        StopAnimTask(cache.ped, ANIM_DICT, ANIM_CLIP, 1.0)
    end
end)
