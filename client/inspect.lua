local Mods = require 'shared.mods'

local REFRESH = 1000

local shown = { 'modArmor', 'modEngine', 'modBrakes', 'modTransmission', 'modSuspension' }

local performance = {}

for _, perf in ipairs(Mods.performance) do
    performance[perf.key] = perf
end

local run = 0

local function upgrade(vehicle, perf)
    local max = GetNumVehicleMods(vehicle, perf.slot)
    local level = GetVehicleMod(vehicle, perf.slot) + 1

    return {
        label = perf.label,
        level = level,
        max = max,
        name = perf.levels[level + 1] or locale('level_n', level),
    }
end

local function report(vehicle)
    SetVehicleModKit(vehicle, 0)

    local upgrades = {}

    for i, key in ipairs(shown) do
        upgrades[i] = upgrade(vehicle, performance[key])
    end

    return {
        name = Mechanic.vehicleName(vehicle),
        plate = GetVehicleNumberPlateText(vehicle):gsub('^%s+', ''):gsub('%s+$', ''),
        engine = math.max(0, math.floor(GetVehicleEngineHealth(vehicle) / 10 + 0.5)),
        body = math.max(0, math.floor(GetVehicleBodyHealth(vehicle) / 10 + 0.5)),
        turbo = IsToggleModOn(vehicle, 18),
        upgrades = upgrades,
    }
end

local function stillShowing(vehicle, hideAt)
    if GetGameTimer() >= hideAt or not DoesEntityExist(vehicle) then return false end

    return #(GetEntityCoords(cache.ped) - GetEntityCoords(vehicle)) <= Config.Inspect.keepWithin
end

local function inspect(vehicle)
    run += 1

    local mine = run
    local hideAt = GetGameTimer() + Config.Inspect.duration

    CreateThread(function()
        while run == mine and stillShowing(vehicle, hideAt) do
            Mechanic.send('inspect', report(vehicle))
            Wait(math.max(0, math.min(REFRESH, hideAt - GetGameTimer())))
        end

        if run == mine then
            Mechanic.send('inspect', false)
        end
    end)
end

exports.ox_target:addGlobalVehicle({
    {
        name = 'whey_mechanic:inspect',
        icon = 'fa-solid fa-magnifying-glass',
        label = locale('target_inspect'),
        distance = Config.Inspect.distance,
        canInteract = function()
            return not cache.vehicle
        end,
        onSelect = function(data)
            inspect(data.entity)
        end,
    },
})

local function inspectNearest()
    local vehicle = cache.vehicle or lib.getClosestVehicle(GetEntityCoords(cache.ped), Config.Inspect.distance, false)

    if not vehicle then
        return Mechanic.notify(locale('no_vehicle_nearby'), 'error')
    end

    inspect(vehicle)
end

if Config.Inspect.command then
    RegisterCommand(Config.Inspect.command, inspectNearest, false)
end
