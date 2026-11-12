local Mods = {}

local function levels(key, count)
    local out = {}

    for i = 1, count do
        out[i] = locale(('level_%s_%d'):format(key, i - 1))
    end

    return out
end

local function performance(key, slot, count)
    return { key = key, slot = slot, label = locale('part_' .. key), levels = levels(key, count) }
end

local function part(key, slot)
    return { key = key, slot = slot, label = locale('part_' .. key) }
end

local function named(prefix, id, hex)
    return { id = id, label = locale(('%s_%s'):format(prefix, id == -1 and 'stock' or id)), hex = hex }
end

Mods.performance = {
    performance('modEngine', 11, 5),
    performance('modBrakes', 12, 4),
    performance('modTransmission', 13, 5),
    performance('modSuspension', 15, 6),
    performance('modArmor', 16, 6),
}

Mods.parts = {
    body = {
        part('modSpoilers', 0),
        part('modFrontBumper', 1),
        part('modRearBumper', 2),
        part('modSideSkirt', 3),
        part('modExhaust', 4),
        part('modFrame', 5),
        part('modGrille', 6),
        part('modHood', 7),
        part('modFender', 8),
        part('modRightFender', 9),
        part('modRoof', 10),
        part('modTrunk', 37),
        part('modHydrolic', 38),
        part('modEngineBlock', 39),
        part('modAirFilter', 40),
        part('modStruts', 41),
        part('modArchCover', 42),
        part('modAerials', 43),
        part('modTrimB', 44),
        part('modTank', 45),
        part('modWindows', 46),
        part('modDoorR', 47),
        part('modLightbar', 49),
    },
    interior = {
        part('modTrimA', 27),
        part('modOrnaments', 28),
        part('modDashboard', 29),
        part('modDial', 30),
        part('modDoorSpeaker', 31),
        part('modSeats', 32),
        part('modSteeringWheel', 33),
        part('modShifterLeavers', 34),
        part('modAPlate', 35),
        part('modSpeakers', 36),
    },
    plates = {
        part('modPlateHolder', 25),
        part('modVanityPlate', 26),
    },
}

Mods.horn = part('modHorns', 14)
Mods.livery = part('modLivery', 48)

Mods.aircraftLocked = { modRoof = true, modFrontBumper = true }

Mods.weaponWords = {
    'gun',
    'cannon',
    'missile',
    'rocket',
    'flare',
    'chaff',
    'countermeasure',
    'bomb',
    'turret',
    'weapon',
    'barrage',
    'explosive',
}

Mods.finishes = {
    named('finish', 0),
    named('finish', 1),
    named('finish', 2),
    named('finish', 3),
    named('finish', 4),
    named('finish', 5),
}

Mods.colours = {
    named('colour', 0, '#0d1116'),
    named('colour', 1, '#1c1d21'),
    named('colour', 3, '#464c56'),
    named('colour', 4, '#999da0'),
    named('colour', 6, '#585a60'),
    named('colour', 10, '#3a3f45'),
    named('colour', 111, '#f0f0f0'),
    named('colour', 112, '#e3e3e3'),
    named('colour', 107, '#cfc0a5'),
    named('colour', 27, '#c00e1a'),
    named('colour', 28, '#da1918'),
    named('colour', 29, '#b6111b'),
    named('colour', 34, '#690e1a'),
    named('colour', 35, '#8f0a1b'),
    named('colour', 150, '#bc1917'),
    named('colour', 36, '#f78616'),
    named('colour', 38, '#f2611c'),
    named('colour', 138, '#ff5f00'),
    named('colour', 37, '#c2944f'),
    named('colour', 158, '#7a6440'),
    named('colour', 88, '#fbe212'),
    named('colour', 89, '#fdbb16'),
    named('colour', 91, '#d5ce5c'),
    named('colour', 92, '#98d223'),
    named('colour', 53, '#155c2d'),
    named('colour', 50, '#0b4224'),
    named('colour', 51, '#1d6e4f'),
    named('colour', 52, '#4d5d35'),
    named('colour', 55, '#66b81f'),
    named('colour', 61, '#222e46'),
    named('colour', 62, '#233155'),
    named('colour', 64, '#2354a1'),
    named('colour', 68, '#4a93c9'),
    named('colour', 70, '#0b9cf1'),
    named('colour', 73, '#2446a8'),
    named('colour', 74, '#6ea3c6'),
    named('colour', 71, '#2f2d52'),
    named('colour', 142, '#280f2a'),
    named('colour', 145, '#621276'),
    named('colour', 148, '#6b1f7b'),
    named('colour', 135, '#f21f99'),
    named('colour', 137, '#df5891'),
    named('colour', 136, '#fdd6cd'),
    named('colour', 96, '#221b19'),
    named('colour', 94, '#4e3423'),
    named('colour', 98, '#6f4b2e'),
    named('colour', 104, '#895737'),
    named('colour', 105, '#c5ae7c'),
    named('colour', 117, '#6a747c'),
    named('colour', 119, '#a7abaf'),
    named('colour', 120, '#d8dcdf'),
    named('colour', 147, '#060606'),
    named('colour', 12, '#13181f'),
    named('colour', 13, '#262627'),
    named('colour', 39, '#cf1f21'),
    named('colour', 151, '#2d362a'),
    named('colour', 153, '#5b4a35'),
}

Mods.xenon = {
    named('xenon', -1),
    named('xenon', 0, '#f4f6ff'),
    named('xenon', 1, '#2a6dff'),
    named('xenon', 2, '#38b6ff'),
    named('xenon', 3, '#5dffb0'),
    named('xenon', 4, '#9cff2e'),
    named('xenon', 5, '#ffe834'),
    named('xenon', 6, '#ffc23a'),
    named('xenon', 7, '#ff8b2c'),
    named('xenon', 8, '#ff2f2f'),
    named('xenon', 9, '#ff7fc8'),
    named('xenon', 10, '#ff2fa4'),
    named('xenon', 11, '#a447ff'),
    named('xenon', 12, '#5c2bff'),
}

Mods.tints = {
    named('tint', 0),
    named('tint', 4),
    named('tint', 3),
    named('tint', 2),
    named('tint', 5),
    named('tint', 1),
    named('tint', 6),
}

Mods.plateStyles = {
    named('plate', 0),
    named('plate', 3),
    named('plate', 4),
    named('plate', 1),
    named('plate', 2),
    named('plate', 5),
}

Mods.wheelTypes = {
    named('wheel', 0),
    named('wheel', 1),
    named('wheel', 2),
    named('wheel', 3),
    named('wheel', 4),
    named('wheel', 5),
    named('wheel', 7),
    named('wheel', 8),
    named('wheel', 9),
    named('wheel', 10),
    named('wheel', 11),
    named('wheel', 12),
    named('wheel', 6),
}

Mods.keys = {
    modTurbo = { kind = 'bool', group = 'turbo' },
    modHorns = { kind = 'int', min = -1, max = 100, group = 'horn' },
    modLivery = { kind = 'int', min = -1, max = 100, group = 'livery' },
    livery = { kind = 'int', min = -1, max = 100, group = 'livery' },
    modRoofLivery = { kind = 'int', min = -1, max = 100, group = 'roofLivery' },

    color1 = { kind = 'rgb', group = 'primary' },
    paintType1 = { kind = 'int', min = 0, max = 5, group = 'primary' },
    color2 = { kind = 'rgb', group = 'secondary' },
    paintType2 = { kind = 'int', min = 0, max = 5, group = 'secondary' },
    pearlescentColor = { kind = 'int', min = 0, max = 255, group = 'pearlescent' },
    wheelColor = { kind = 'int', min = 0, max = 255, group = 'wheelColor' },
    interiorColor = { kind = 'int', min = 0, max = 255, group = 'interiorColor' },
    dashboardColor = { kind = 'int', min = 0, max = 255, group = 'dashboardColor' },

    wheels = { kind = 'int', min = 0, max = 12, group = 'wheels' },
    modFrontWheels = { kind = 'int', min = -1, max = 300, group = 'wheels' },
    modBackWheels = { kind = 'int', min = -1, max = 300, group = 'wheels' },
    modCustomTiresF = { kind = 'bool', group = 'wheels' },
    modCustomTiresR = { kind = 'bool', group = 'wheels' },

    modSmokeEnabled = { kind = 'bool', group = 'tyreSmoke' },
    tyreSmokeColor = { kind = 'rgb', group = 'tyreSmoke' },
    modXenon = { kind = 'bool', group = 'xenon' },
    xenonColor = { kind = 'int', min = -1, max = 255, group = 'xenon' },
    neonEnabled = { kind = 'neon', group = 'neon' },
    neonColor = { kind = 'rgb', group = 'neon' },

    windowTint = { kind = 'int', min = -1, max = 6, group = 'windowTint' },
    plateIndex = { kind = 'int', min = 0, max = 12, group = 'plateIndex' },
    extras = { kind = 'extras', group = 'extra' },
}

Mods.groupLabels = {}

for _, spec in pairs(Mods.keys) do
    Mods.groupLabels[spec.group] = locale('group_' .. spec.group)
end

for _, perf in ipairs(Mods.performance) do
    Mods.keys[perf.key] = { kind = 'int', min = -1, max = #perf.levels - 2, group = perf.key }
    Mods.groupLabels[perf.key] = perf.label
end

for _, list in pairs(Mods.parts) do
    for _, item in ipairs(list) do
        Mods.keys[item.key] = { kind = 'int', min = -1, max = 100, group = item.key }
        Mods.groupLabels[item.key] = item.label
    end
end

return Mods
