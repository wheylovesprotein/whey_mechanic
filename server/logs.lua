local Mods = require 'shared.mods'
local hook = require 'config.logs'

local core = exports.qbx_core

local Logs = {}

local performance = {}
local colours, xenon, tints, plateStyles, wheelTypes, finishes = {}, {}, {}, {}, {}, {}

for _, perf in ipairs(Mods.performance) do
    performance[perf.key] = perf
end

for _, c in ipairs(Mods.colours) do
    colours[c.id] = c.label
end

for _, x in ipairs(Mods.xenon) do
    xenon[x.id] = x.label
end

for _, t in ipairs(Mods.tints) do
    tints[t.id] = t.label
end

for _, p in ipairs(Mods.plateStyles) do
    plateStyles[p.id] = p.label
end

for _, w in ipairs(Mods.wheelTypes) do
    wheelTypes[w.id] = w.label
end

for _, f in ipairs(Mods.finishes) do
    finishes[f.id] = f.label
end

local NEON_SIDES = { locale('side_left'), locale('side_right'), locale('side_front'), locale('side_back') }

function Logs.send(message, metadata, severity)
    severity = severity or 'info'

    if Config.Debug then
        lib.print.info(message, json.encode(metadata))
    end

    local ok, problem = pcall(hook, message, metadata, severity)

    if not ok then
        lib.print.error(('config/logs.lua failed: %s'):format(problem))
    end
end

function Logs.plate(plate)
    if type(plate) ~= 'string' then return end

    return (plate:gsub('^%s+', ''):gsub('%s+$', ''))
end

local function charName(player)
    local info = player and player.PlayerData.charinfo

    if info then
        return ('%s %s'):format(info.firstname, info.lastname)
    end
end

function Logs.person(src)
    local player = core:GetPlayer(src)

    return {
        source = src,
        name = charName(player) or GetPlayerName(src) or ('#%d'):format(src),
        citizenid = player and player.PlayerData.citizenid,
        job = player and player.PlayerData.job and player.PlayerData.job.name,
    }
end

function Logs.nameOf(citizenid)
    if not citizenid then return end

    return charName(core:GetPlayerByCitizenId(citizenid)) or charName(core:GetOfflinePlayer(citizenid))
end

local function index(value, none)
    if value == nil then return '?' end
    if value == -1 or value == false then return none or locale('option_stock') end

    return ('#%d'):format(value + 1)
end

local function hex(rgb)
    if type(rgb) ~= 'table' or not rgb[3] then return end

    return ('#%02x%02x%02x'):format(rgb[1], rgb[2], rgb[3])
end

local function colourName(id)
    if id == nil then return '?' end

    return colours[id] or ('#%s'):format(tostring(id))
end

local function paint(colour, finish)
    local finishName = finishes[finish] or finishes[0]

    if type(colour) == 'table' then
        return ('%s %s'):format(finishName, hex(colour) or '?')
    end

    return ('%s %s'):format(finishName, colourName(colour))
end

local renderers = {
    turbo = function(p)
        return p.modTurbo and locale('desc_installed') or locale('option_none')
    end,
    horn = function(p)
        return index(p.modHorns)
    end,
    livery = function(p)
        if p.modLivery and p.modLivery >= 0 then return index(p.modLivery) end

        return index(p.livery, locale('option_none'))
    end,
    roofLivery = function(p)
        return index(p.modRoofLivery, locale('option_none'))
    end,
    primary = function(p)
        return paint(p.color1, p.paintType1)
    end,
    secondary = function(p)
        return paint(p.color2, p.paintType2)
    end,
    pearlescent = function(p)
        return colourName(p.pearlescentColor)
    end,
    wheelColor = function(p)
        return colourName(p.wheelColor)
    end,
    interiorColor = function(p)
        return colourName(p.interiorColor)
    end,
    dashboardColor = function(p)
        return colourName(p.dashboardColor)
    end,
    wheels = function(p)
        local rim = ('%s %s'):format(wheelTypes[p.wheels] or '?', index(p.modFrontWheels))

        return p.modCustomTiresF and locale('desc_custom_tyres', rim) or rim
    end,
    tyreSmoke = function(p)
        return p.modSmokeEnabled and (hex(p.tyreSmokeColor) or locale('desc_on')) or locale('option_stock')
    end,
    xenon = function(p)
        return p.modXenon and (xenon[p.xenonColor] or locale('desc_on')) or locale('option_stock')
    end,
    neon = function(p)
        local sides = {}

        for i, side in ipairs(NEON_SIDES) do
            if p.neonEnabled and p.neonEnabled[i] then
                sides[#sides + 1] = side
            end
        end

        if #sides == 0 then return locale('desc_off') end

        return ('%s %s'):format(table.concat(sides, ', '), hex(p.neonColor) or '')
    end,
    windowTint = function(p)
        return tints[p.windowTint] or tostring(p.windowTint)
    end,
    plateIndex = function(p)
        return plateStyles[p.plateIndex] or tostring(p.plateIndex)
    end,
}

local function render(group, props)
    local renderer = renderers[group]

    if renderer then return renderer(props) end

    local perf = performance[group]
    local value = props[group]

    if perf then
        return value and perf.levels[value + 2] or '?'
    end

    return index(value)
end

function Logs.describe(clean, before, after)
    local lines, seen = {}, {}

    for key, value in pairs(clean) do
        local group = Mods.keys[key].group
        local label = Mods.groupLabels[group] or group

        if group == 'extra' then
            for id, off in pairs(value) do
                lines[#lines + 1] = locale(off == 0 and 'desc_extra_fitted' or 'desc_extra_removed', id)
            end
        elseif not seen[group] then
            seen[group] = true
            lines[#lines + 1] = ('%s: %s → %s'):format(label, render(group, before), render(group, after))
        end
    end

    table.sort(lines)

    return lines
end

function Logs.upgrades(props)
    local out = { [Mods.groupLabels.turbo] = props.modTurbo and locale('desc_installed') or locale('option_none') }

    for _, perf in ipairs(Mods.performance) do
        out[perf.label] = render(perf.key, props)
    end

    return out
end

return Logs
