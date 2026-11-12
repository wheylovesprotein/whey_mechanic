lib.locale()

Mechanic = {}

local function hasJob(job)
    local current = QBX.PlayerData and QBX.PlayerData.job

    if not current or current.name ~= job then return false end

    return not Config.RequireDuty or current.onduty == true
end

function Mechanic.isOnDuty()
    return hasJob(Config.Job)
end

function Mechanic.send(action, data)
    SendNUIMessage({ action = action, data = data })
end

function Mechanic.notify(description, kind)
    lib.notify({ title = locale('notify_title'), description = description, type = kind or 'inform' })
end

function Mechanic.money(n)
    local s = tostring(n):reverse():gsub('(%d%d%d)', '%1,'):reverse():gsub('^,', '')

    return '$' .. s
end

function Mechanic.vehicleName(vehicle)
    local model = GetEntityModel(vehicle)
    local make = GetLabelText(GetMakeNameFromVehicleModel(model))
    local name = GetLabelText(GetDisplayNameFromVehicleModel(model))

    if name == 'NULL' then
        name = GetDisplayNameFromVehicleModel(model)
    end

    if make == 'NULL' or make == '' then return name end

    return ('%s %s'):format(make, name)
end

function Mechanic.isAircraft(vehicle)
    local model = GetEntityModel(vehicle)

    return IsThisModelAHeli(model) or IsThisModelAPlane(model)
end

function Mechanic.canUse(shop, vehicle)
    if shop.job and not hasJob(shop.job) then return false end

    return Mechanic.isAircraft(vehicle) == (shop.aircraft == true)
end

function Mechanic.inShop(shop, vehicle)
    local coords = GetEntityCoords(vehicle)

    for _, spot in ipairs(shop.spots or { shop.coords }) do
        if #(coords - spot) <= shop.radius then return true end
    end

    return false
end

function Mechanic.control(vehicle)
    if NetworkHasControlOfEntity(vehicle) then return true end

    NetworkRequestControlOfEntity(vehicle)

    local ok = pcall(lib.waitFor, function()
        if NetworkHasControlOfEntity(vehicle) then return true end

        NetworkRequestControlOfEntity(vehicle)
    end, nil, 2000)

    return ok
end

RegisterNUICallback('ready', function(_, cb)
    cb({ locale = lib.getLocales() })
end)

local function isShopBoss()
    local job = QBX.PlayerData and QBX.PlayerData.job

    return job and job.name == Config.Job and job.isboss == true
end

if Config.BossMenu then
    local marker = Config.BossMenu.marker
    local ground = Config.BossMenu.coords - vec3(0.0, 0.0, 0.98)

    lib.points.new({
        coords = Config.BossMenu.coords,
        distance = marker.drawDistance,
        nearby = function()
            if not isShopBoss() then return end

            local scale, color = marker.scale, marker.color

            DrawMarker(
                marker.type,
                ground.x, ground.y, ground.z,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                scale.x, scale.y, scale.z,
                color.r, color.g, color.b, color.a,
                false, false, 2, false, nil, nil, false
            )
        end,
    })
end

for _, shop in pairs(Config.Shops) do
    local b, c = shop.blip, shop.coords

    if b then
        local blip = AddBlipForCoord(c.x, c.y, c.z)

        SetBlipSprite(blip, b.sprite)
        SetBlipColour(blip, b.color)
        SetBlipScale(blip, b.scale)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(shop.label)
        EndTextCommandSetBlipName(blip)
    end
end
