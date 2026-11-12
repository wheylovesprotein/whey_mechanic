local Mods = require 'shared.mods'

local WHEELS = 23
local BACK_WHEELS = 24
local WATCH = 500
local MAX_REACH = 12.0

local HOOD = 4
local TRUNK = 5
local CAMERA_SPEED = 6.0
local MIN_DIST = 0.4
local HORN_PREVIEW = 1500

local CUSTOMIZE = 38
local PROMPT = locale('prompt_customize')

local GROUND_ONLY = { wheels = true, lights = true, windows = true, plates = true, horn = true }

local session

local VIEWS = {
    overview = { heading = 40, pitch = 12, zoom = 1.0, at = vec3(0, 0, 0) },
    engine = { heading = 0, pitch = 38, zoom = 0.65, at = vec3(0, 0.6, 0.2), doors = { HOOD } },
    hood = { heading = 15, pitch = 30, zoom = 0.7, at = vec3(0, 0.55, 0.35) },
    front = { heading = 10, pitch = 8, zoom = 0.65, at = vec3(0, 0.85, -0.25) },
    headlights = { heading = 25, pitch = 6, zoom = 0.6, at = vec3(0, 0.9, -0.05) },
    rear = { heading = 170, pitch = 8, zoom = 0.65, at = vec3(0, -0.85, -0.25) },
    spoiler = { heading = 160, pitch = 22, zoom = 0.7, at = vec3(0, -0.8, 0.5) },
    exhaust = { heading = 150, pitch = 4, zoom = 0.5, at = vec3(0.3, -0.95, -0.55) },
    trunk = { heading = 175, pitch = 28, zoom = 0.7, at = vec3(0, -0.7, 0.25), doors = { TRUNK } },
    side = { heading = 90, pitch = 8, zoom = 0.95, at = vec3(0, 0, -0.1) },
    skirt = { heading = 95, pitch = 2, zoom = 0.75, at = vec3(1, 0, -0.6) },
    fenderLeft = { heading = -60, pitch = 10, zoom = 0.55, at = vec3(-1, 0.55, -0.1) },
    fenderRight = { heading = 60, pitch = 10, zoom = 0.55, at = vec3(1, 0.55, -0.1) },
    wheel = { heading = 70, pitch = 4, zoom = 0.45, at = vec3(1, 0.6, -0.55) },
    smoke = { heading = 125, pitch = 6, zoom = 0.6, at = vec3(0.9, -0.6, -0.6) },
    roof = { heading = 50, pitch = 50, zoom = 0.85, at = vec3(0, 0, 0.7) },
    underside = { heading = 90, pitch = 2, zoom = 1.0, at = vec3(0, 0, -0.85) },
    plateRear = { heading = 180, pitch = 6, zoom = 0.4, at = vec3(0, -1, -0.35) },
    plateFront = { heading = 0, pitch = 6, zoom = 0.4, at = vec3(0, 1, -0.35) },
    interior = { heading = 150, pitch = 12, dist = 0.9, at = vec3(0, 0.25, 0.3) },
}

local SECTION_VIEWS = {
    modEngine = 'engine',
    modTransmission = 'engine',
    modTurbo = 'engine',
    modBrakes = 'wheel',
    modSuspension = 'wheel',
    modArmor = 'side',
    modSpoilers = 'spoiler',
    modFrontBumper = 'front',
    modRearBumper = 'rear',
    modSideSkirt = 'skirt',
    modExhaust = 'exhaust',
    modFrame = 'interior',
    modGrille = 'front',
    modHood = 'hood',
    modFender = 'fenderLeft',
    modRightFender = 'fenderRight',
    modRoof = 'roof',
    modTrunk = 'trunk',
    modHydrolic = 'engine',
    modEngineBlock = 'engine',
    modAirFilter = 'engine',
    modStruts = 'engine',
    modArchCover = 'wheel',
    modAerials = 'roof',
    modTrimB = 'spoiler',
    modTank = 'rear',
    modWindows = 'side',
    modDoorR = 'side',
    modLightbar = 'roof',
    modTrimA = 'interior',
    modOrnaments = 'interior',
    modDashboard = 'interior',
    modDial = 'interior',
    modDoorSpeaker = 'interior',
    modSeats = 'interior',
    modSteeringWheel = 'interior',
    modShifterLeavers = 'interior',
    modAPlate = 'interior',
    modSpeakers = 'trunk',
    interiorColor = 'interior',
    dashboardColor = 'interior',
    wheels = 'wheel',
    modCustomTiresF = 'wheel',
    wheelColor = 'wheel',
    smoke = 'smoke',
    xenon = 'headlights',
    neon = 'underside',
    windowTint = 'side',
    plateIndex = 'plateRear',
    modPlateHolder = 'plateRear',
    modVanityPlate = 'plateFront',
    modLivery = 'side',
    livery = 'side',
    modRoofLivery = 'roof',
    modHorns = 'front',
}

local NO_REPLY = { ok = false, msg = locale('no_reply') }
local CLOSED = { ok = false, msg = locale('menu_closed') }

local function normalize(value)
    if type(value) == 'number' then return math.tointeger(value) or value end
    if type(value) ~= 'table' then return value end

    local out = {}

    for k, v in pairs(value) do
        out[k] = normalize(v)
    end

    return out
end

local function modLabel(vehicle, slot, index, fallback)
    local text = GetModTextLabel(vehicle, slot, index)
    local label = text and GetLabelText(text)

    if not label or label == 'NULL' or label == '' then
        return ('%s %d'):format(fallback, index + 1)
    end

    return label
end

local function slotOptions(vehicle, slot, name, stock)
    local count = GetNumVehicleMods(vehicle, slot)

    if count == 0 then return end

    local options = { { value = -1, label = stock or locale('option_stock') } }

    for i = 0, count - 1 do
        options[#options + 1] = { value = i, label = modLabel(vehicle, slot, i, name) }
    end

    return options
end

local function partSections(vehicle, parts)
    local sections = {}

    for _, part in ipairs(parts) do
        local options = slotOptions(vehicle, part.slot, part.label)

        if options then
            sections[#sections + 1] = { type = 'list', title = part.label, key = part.key, options = options }
        end
    end

    return sections
end

local function performanceSections(vehicle)
    local sections = {}

    for _, perf in ipairs(Mods.performance) do
        local count = math.min(GetNumVehicleMods(vehicle, perf.slot), #perf.levels - 1)

        if count > 0 then
            local options = {}

            for level = 0, count do
                options[level + 1] = { value = level - 1, label = perf.levels[level + 1] }
            end

            sections[#sections + 1] = { type = 'list', title = perf.label, key = perf.key, options = options }
        end
    end

    sections[#sections + 1] = {
        type = 'list',
        title = locale('group_turbo'),
        key = 'modTurbo',
        options = { { value = false, label = locale('option_none') }, { value = true, label = locale('group_turbo') } },
    }

    return sections
end

local function liverySections(vehicle)
    local sections = {}
    local livery = Mods.livery
    local options = slotOptions(vehicle, livery.slot, livery.label, locale('option_none'))

    if options then
        sections[1] = { type = 'list', title = livery.label, key = livery.key, options = options }
    else
        local count = GetVehicleLiveryCount(vehicle)

        if count > 0 then
            options = {}

            for i = 0, count - 1 do
                local name = GetLabelText(GetLiveryName(vehicle, i))
                options[i + 1] = { value = i, label = name ~= 'NULL' and name or locale('livery_n', i + 1) }
            end

            sections[1] = { type = 'list', title = livery.label, key = 'livery', options = options }
        end
    end

    local roofs = GetVehicleRoofLiveryCount(vehicle)

    if roofs > 0 then
        options = { { value = -1, label = locale('option_none') } }

        for i = 0, roofs - 1 do
            options[#options + 1] = { value = i, label = locale('roof_livery_n', i + 1) }
        end

        sections[#sections + 1] = { type = 'list', title = locale('group_roofLivery'), key = 'modRoofLivery', options = options }
    end

    return sections
end

local function extraSections(vehicle)
    local ids = {}

    for i = 1, 14 do
        if DoesExtraExist(vehicle, i) then
            ids[#ids + 1] = i
        end
    end

    if #ids == 0 then return {} end

    return { { type = 'extras', title = locale('group_extra'), ids = ids } }
end

local function hornSections(vehicle)
    local horn = Mods.horn
    local options = slotOptions(vehicle, horn.slot, horn.label)

    if not options then return {} end

    return { { type = 'list', title = horn.label, key = horn.key, options = options } }
end

local function pairsToOptions(list)
    local options = {}

    for i, item in ipairs(list) do
        options[i] = { value = item.id, label = item.label }
    end

    return options
end

local function isWeapon(label)
    label = label:lower()

    for _, word in ipairs(Mods.weaponWords) do
        if label:find(word, 1, true) then return true end
    end

    return false
end

local function disarm(sections, values)
    local kept = {}

    for _, section in ipairs(sections) do
        local first = section.type == 'list' and section.options[1]

        if not first or first.value ~= -1 then
            kept[#kept + 1] = section
        else
            local options = { first }

            if not Mods.aircraftLocked[section.key] then
                for i = 2, #section.options do
                    local option = section.options[i]

                    if not isWeapon(option.label) then
                        options[#options + 1] = option
                    end
                end
            end

            if #options > 1 or (values[section.key] or -1) ~= -1 then
                section.options = options
                kept[#kept + 1] = section
            end
        end
    end

    return kept
end

local function catalog(vehicle, values)
    local bike = IsThisModelABike(GetEntityModel(vehicle))
    local wheelTypes = {}

    for _, wheelType in ipairs(Mods.wheelTypes) do
        if (wheelType.id == 6) == bike then
            wheelTypes[#wheelTypes + 1] = wheelType
        end
    end

    local plates = partSections(vehicle, Mods.parts.plates)

    table.insert(plates, 1, {
        type = 'list',
        title = locale('group_plateIndex'),
        key = 'plateIndex',
        options = pairsToOptions(Mods.plateStyles),
    })

    local categories = {
        { id = 'performance', label = locale('cat_performance'), icon = 'gauge', sections = performanceSections(vehicle) },
        {
            id = 'paint',
            label = locale('cat_paint'),
            icon = 'palette',
            sections = {
                { type = 'paint', title = locale('sec_primary'), key = 'color1', finishKey = 'paintType1' },
                { type = 'paint', title = locale('sec_secondary'), key = 'color2', finishKey = 'paintType2' },
                { type = 'swatch', title = locale('group_pearlescent'), key = 'pearlescentColor' },
                { type = 'swatch', title = locale('group_wheelColor'), key = 'wheelColor' },
                { type = 'swatch', title = locale('cat_interior'), key = 'interiorColor' },
                { type = 'swatch', title = locale('sec_dashboard'), key = 'dashboardColor' },
            },
        },
        {
            id = 'wheels',
            label = locale('cat_wheels'),
            icon = 'disc',
            sections = {
                { type = 'wheels', title = locale('group_wheels'), types = wheelTypes, bike = bike },
                {
                    type = 'list',
                    title = locale('sec_tyres'),
                    key = 'modCustomTiresF',
                    options = { { value = false, label = locale('option_stock_tyres') }, { value = true, label = locale('option_custom_tyres') } },
                },
                { type = 'smoke', title = locale('group_tyreSmoke') },
            },
        },
        { id = 'body', label = locale('cat_body'), icon = 'car', sections = partSections(vehicle, Mods.parts.body) },
        {
            id = 'interior',
            label = locale('cat_interior'),
            icon = 'armchair',
            sections = partSections(vehicle, Mods.parts.interior),
        },
        {
            id = 'lights',
            label = locale('cat_lights'),
            icon = 'lightbulb',
            sections = {
                { type = 'xenon', title = locale('group_xenon'), options = Mods.xenon },
                { type = 'neon', title = locale('group_neon') },
            },
        },
        {
            id = 'windows',
            label = locale('cat_windows'),
            icon = 'window',
            sections = {
                { type = 'list', title = locale('group_windowTint'), key = 'windowTint', options = pairsToOptions(Mods.tints) },
            },
        },
        { id = 'plates', label = locale('cat_plates'), icon = 'plate', sections = plates },
        { id = 'livery', label = locale('group_livery'), icon = 'layers', sections = liverySections(vehicle) },
        { id = 'extras', label = locale('group_extra'), icon = 'plus', sections = extraSections(vehicle) },
        { id = 'horn', label = locale('group_horn'), icon = 'horn', sections = hornSections(vehicle) },
    }

    local aircraft = Mechanic.isAircraft(vehicle)
    local shown = {}

    for _, category in ipairs(categories) do
        if aircraft then
            category.sections = disarm(category.sections, values)
        end

        if #category.sections > 0 and not (aircraft and GROUND_ONLY[category.id]) then
            shown[#shown + 1] = category
        end
    end

    return shown
end

local function customsValues(props)
    local values = {}

    for key in pairs(Mods.keys) do
        if key == 'extras' then
            local extras = {}

            for id, off in pairs(props.extras or {}) do
                extras[tostring(id)] = off
            end

            values.extras = extras
        elseif props[key] ~= nil then
            values[key] = props[key]
        end
    end

    return values
end

local function restore(vehicle, values)
    lib.setVehicleProperties(vehicle, values)

    if type(values.color1) == 'number' then
        SetVehicleModColor_1(vehicle, values.paintType1 or 0, values.color1, values.pearlescentColor or 0)
    end

    if type(values.color2) == 'number' then
        SetVehicleModColor_2(vehicle, values.paintType2 or 0, values.color2)
    end
end

local function merge(base, changes)
    for key, value in pairs(changes) do
        if key == 'extras' then
            for id, off in pairs(value) do
                base.extras[id] = off
            end
        else
            base[key] = value
        end
    end
end

local function aim(s)
    local h, p, d, at = math.rad(s.heading), math.rad(s.pitch), s.dist, s.at
    local x = at.x + d * math.cos(p) * math.sin(h)
    local y = at.y + d * math.cos(p) * math.cos(h)
    local z = at.z + d * math.sin(p)

    local target = GetOffsetFromEntityInWorldCoords(s.vehicle, at.x, at.y, at.z)
    local eye = GetOffsetFromEntityInWorldCoords(s.vehicle, x, y, z)

    SetCamCoord(s.cam, eye.x, eye.y, eye.z)
    PointCamAtCoord(s.cam, target.x, target.y, target.z)
end

local function viewGoal(s, name)
    local view = VIEWS[name] or VIEWS.overview
    local at = view.at

    return {
        heading = view.heading,
        pitch = view.pitch,
        dist = view.dist or s.baseDist * view.zoom,
        at = s.centre + vec3(at.x * s.half.x, at.y * s.half.y, at.z * s.half.z),
        doors = view.doors,
    }
end

local function setDoors(s, doors)
    local want = {}

    for _, door in ipairs(doors or {}) do
        want[door] = true
    end

    for _, door in ipairs({ HOOD, TRUNK }) do
        if want[door] and not s.doors[door] then
            SetVehicleDoorOpen(s.vehicle, door, false, false)
        elseif s.doors[door] and not want[door] then
            SetVehicleDoorShut(s.vehicle, door, false)
        end
    end

    s.doors = want
end

local function focus(s, section)
    s.goal = viewGoal(s, SECTION_VIEWS[section] or 'overview')
    setDoors(s, s.goal.doors)
end

local function angleTo(from, to)
    return (to - from + 540) % 360 - 180
end

local function runCamera(s)
    CreateThread(function()
        while session == s do
            local goal = s.goal
            local k = 1 - math.exp(-GetFrameTime() * CAMERA_SPEED)

            s.heading += angleTo(s.heading, goal.heading) * k
            s.pitch += (goal.pitch - s.pitch) * k
            s.dist += (goal.dist - s.dist) * k
            s.at += (goal.at - s.at) * k

            aim(s)
            SetEntityLocallyInvisible(cache.ped)
            Wait(0)
        end
    end)
end

local function startCamera(s)
    local min, max = GetModelDimensions(GetEntityModel(s.vehicle))
    local size = math.max(max.y - min.y, max.x - min.x)

    s.centre = (min + max) / 2
    s.half = (max - min) / 2
    s.baseDist = size * 0.9 + 2.0
    s.maxDist = size * 1.4 + 3.0
    s.doors = {}
    s.goal = viewGoal(s, 'overview')
    s.heading, s.pitch, s.dist, s.at = s.goal.heading, s.goal.pitch, s.goal.dist, s.goal.at
    s.cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 50.0, false, 0)

    aim(s)
    SetCamActive(s.cam, true)
    RenderScriptCams(true, true, 500, true, false)
    runCamera(s)
end

local function stopCamera(cam, ease)
    RenderScriptCams(false, ease, ease and 500 or 0, true, false)
    DestroyCam(cam, false)
end

local function close()
    if not session then return end

    local s = session
    session = nil

    SetNuiFocus(false, false)
    Mechanic.send('customs:close')
    stopCamera(s.cam, true)

    if DoesEntityExist(s.vehicle) then
        setDoors(s, nil)
        restore(s.vehicle, s.base)
        FreezeEntityPosition(s.vehicle, false)
    end

    TriggerServerEvent('whey_mechanic:server:close')
end

local function stillWorkable(s)
    local vehicle = s.vehicle

    if not DoesEntityExist(vehicle) or IsEntityDead(cache.ped) then return false end
    if not Mechanic.inShop(s.shop, vehicle) or not Mechanic.canUse(s.shop, vehicle) then return false end

    return #(GetEntityCoords(cache.ped) - GetEntityCoords(vehicle)) <= MAX_REACH
end

local function watch()
    local mine = session

    CreateThread(function()
        while session == mine do
            if not stillWorkable(mine) then
                close()
                break
            end

            Wait(WATCH)
        end
    end)
end

local function open(shopId, vehicle)
    if session then return end

    local shop = Config.Shops[shopId]
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    local ok, info = lib.callback.await('whey_mechanic:server:open', false, shopId, netId)

    if not ok then
        return Mechanic.notify(info or locale('cannot_work'), 'error')
    end

    if not Mechanic.control(vehicle) then
        TriggerServerEvent('whey_mechanic:server:close')
        return Mechanic.notify(locale('control_failed'), 'error')
    end

    SetVehicleModKit(vehicle, 0)
    FreezeEntityPosition(vehicle, true)

    local base = customsValues(lib.getVehicleProperties(vehicle) or {})
    session = { shop = shop, vehicle = vehicle, netId = netId, base = base }

    local groups = {}

    for key, spec in pairs(Mods.keys) do
        groups[key] = spec.group
    end

    startCamera(session)
    SetNuiFocus(true, true)

    Mechanic.send('customs:open', {
        shop = shop.label,
        vehicle = { name = Mechanic.vehicleName(vehicle), plate = GetVehicleNumberPlateText(vehicle) },
        billsOwner = info.billing ~= 'driver',
        requests = info.requests == true,
        payerDistance = Config.Billing.payerDistance,
        damaged = info.damaged == true,
        repairPrice = info.repair,
        prices = Config.Prices,
        groups = groups,
        values = base,
        categories = catalog(vehicle, base),
        colours = Mods.colours,
        finishes = Mods.finishes,
    })

    watch()
end

RegisterNUICallback('customs:close', function(_, cb)
    cb(1)
    close()
end)

RegisterNUICallback('customs:preview', function(patch, cb)
    cb(1)

    if not session or type(patch) ~= 'table' then return end

    local vehicle = session.vehicle
    patch = normalize(patch)

    if patch.modFrontWheels and IsThisModelABike(GetEntityModel(vehicle)) then
        patch.modBackWheels = patch.modFrontWheels
        patch.modCustomTiresR = patch.modCustomTiresF
    end

    lib.setVehicleProperties(vehicle, patch)

    if patch.modHorns then
        StartVehicleHorn(vehicle, HORN_PREVIEW, joaat('HELDDOWN'), false)
    end
end)

RegisterNUICallback('customs:reset', function(_, cb)
    cb(1)

    if session then
        restore(session.vehicle, session.base)
    end
end)

RegisterNUICallback('customs:rims', function(data, cb)
    if not session then return cb({}) end

    local vehicle = session.vehicle
    local wheelType = math.tointeger(data.type) or 0
    local current = GetVehicleWheelType(vehicle)
    local mod = GetVehicleMod(vehicle, WHEELS)
    local variation = GetVehicleModVariation(vehicle, WHEELS)

    SetVehicleWheelType(vehicle, wheelType)

    local options = slotOptions(vehicle, WHEELS, locale('rim')) or { { value = -1, label = locale('option_stock') } }

    SetVehicleWheelType(vehicle, current)
    SetVehicleMod(vehicle, WHEELS, mod, variation)

    if IsThisModelABike(GetEntityModel(vehicle)) then
        SetVehicleMod(vehicle, BACK_WHEELS, mod, variation)
    end

    cb(options)
end)

RegisterNUICallback('customs:camera', function(data, cb)
    cb(1)

    if not session then return end

    local goal = session.goal

    goal.heading = (goal.heading - (tonumber(data.dx) or 0) * 0.35) % 360
    goal.pitch = math.min(70.0, math.max(-5.0, goal.pitch + (tonumber(data.dy) or 0) * 0.25))
    goal.dist = math.min(session.maxDist, math.max(MIN_DIST, goal.dist + (tonumber(data.zoom) or 0) * 0.4))
end)

RegisterNUICallback('customs:focus', function(data, cb)
    cb(1)

    if session and type(data.section) == 'string' then
        focus(session, data.section)
    end
end)

RegisterNUICallback('customs:repair', function(_, cb)
    if not session then return cb(CLOSED) end

    cb(lib.callback.await('whey_mechanic:server:shopRepair', false, session.netId) or NO_REPLY)
end)

RegisterNUICallback('customs:payers', function(_, cb)
    if not session then return cb({}) end

    cb(lib.callback.await('whey_mechanic:server:payers', false, session.netId) or {})
end)

RegisterNUICallback('customs:apply', function(data, cb)
    if not session then return cb(CLOSED) end

    local s = session
    local changes = normalize(data.changes or {})
    local result = lib.callback.await('whey_mechanic:server:apply', false, s.netId, changes, data.payer) or NO_REPLY

    if result.ok and session == s then
        if result.waiting then
            s.waiting = changes
        else
            merge(s.base, changes)
        end
    end

    cb(result)
end)

RegisterNetEvent('whey_mechanic:client:billed', function(result)
    local s = session

    if not s or s.netId ~= result.netId or not s.waiting then return end

    if result.ok then
        merge(s.base, s.waiting)
    end

    s.waiting = nil
    Mechanic.send('customs:billed', result)
end)

local prompting = false

local function prompt(show)
    if show == prompting then return end

    prompting = show

    if show then
        lib.showTextUI(PROMPT, { icon = 'paint-roller' })
    else
        lib.hideTextUI()
    end
end

local function canCustomize(shop)
    local vehicle = cache.vehicle

    if not vehicle or session or cache.seat ~= -1 then return false end
    if not Mechanic.canUse(shop, vehicle) or not Mechanic.inShop(shop, vehicle) then return false end

    return not IsEntityInAir(vehicle)
end

for id, shop in pairs(Config.Shops) do
    for _, spot in ipairs(shop.spots or { shop.coords }) do
        lib.points.new({
            coords = spot,
            distance = shop.radius,
            nearby = function()
                local ready = canCustomize(shop)

                prompt(ready)

                if ready and IsControlJustReleased(0, CUSTOMIZE) then
                    prompt(false)
                    open(id, cache.vehicle)
                end
            end,
            onExit = function()
                prompt(false)
            end,
        })
    end
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    if prompting then
        lib.hideTextUI()
    end

    if not session then return end

    SetNuiFocus(false, false)
    stopCamera(session.cam, false)
    FreezeEntityPosition(session.vehicle, false)
end)
