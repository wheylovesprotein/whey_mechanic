lib.locale()

local Mods = require 'shared.mods'
local Logs = require 'server.logs'
local banking = require 'config.banking'
local billing = require 'server.billing'

local core = exports.qbx_core
local vehicles = exports.qbx_vehicles

local SHOP_SLACK = 5.0
local CUSTOMS_REACH = 10.0
local REPAIR_REACH = Config.Repair.distance + 2.0
local REPAIR_EARLY = 1000

local AIRCRAFT = { heli = true, plane = true }

local sessions = {}
local holders = {}
local repairs = {}
local orders = {}
local invoices = {}

local LINE_LABELS = Mods.groupLabels

local performance = {}

for _, perf in ipairs(Mods.performance) do
    performance[perf.key] = perf
end

for id, shop in pairs(Config.Shops) do
    shop.id = id
end

local function hasJob(src, name)
    local player = core:GetPlayer(src)
    local job = player and player.PlayerData.job

    if not job or job.name ~= name then return false end

    return not Config.RequireDuty or job.onduty == true
end

local function isMechanic(src)
    return hasJob(src, Config.Job)
end

local function vehicleFrom(netId)
    if type(netId) ~= 'number' then return end

    local vehicle = NetworkGetEntityFromNetworkId(netId)

    if vehicle == 0 or not DoesEntityExist(vehicle) or GetEntityType(vehicle) ~= 2 then return end

    return vehicle
end

local function within(src, entity, reach)
    return #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(entity)) <= reach
end

local function inShop(shop, entity)
    local coords = GetEntityCoords(entity)

    for _, spot in ipairs(shop.spots or { shop.coords }) do
        if #(coords - spot) <= shop.radius + SHOP_SLACK then return true end
    end

    return false
end

local function refusal(src, shop, vehicle)
    if shop.job and not hasJob(src, shop.job) then
        return locale('not_employed', shop.label)
    end

    local aircraft = AIRCRAFT[GetVehicleType(vehicle)] == true

    if shop.aircraft and not aircraft then
        return locale('aircraft_only')
    end

    if aircraft and not shop.aircraft then
        return locale('no_aircraft')
    end

    if not inShop(shop, vehicle) or not within(src, vehicle, CUSTOMS_REACH) then
        return locale('bring_inside', shop.label)
    end

    if GetPedInVehicleSeat(vehicle, -1) ~= GetPlayerPed(src) then
        return locale('driver_seat')
    end
end

local function rowOf(vehicle)
    local id = Entity(vehicle).state.vehicleid or vehicles:GetVehicleIdByPlate(GetVehicleNumberPlateText(vehicle))

    return id and vehicles:GetPlayerVehicle(id)
end

local function mayModify(src, shop, vehicle, row)
    if not shop.ownerOrKeys then return true end

    local player = core:GetPlayer(src)

    if player and player.PlayerData.citizenid == row.citizenid then return true end
    if GetResourceState('qbx_vehiclekeys') ~= 'started' then return false end

    return exports.qbx_vehiclekeys:HasKeys(src, vehicle) == true
end

local function applyOrder(props, clean)
    for key, value in pairs(clean) do
        if key == 'extras' then
            props.extras = props.extras or {}

            for id, off in pairs(value) do
                props.extras[id] = off
            end
        else
            props[key] = value
        end
    end
end

local function logVehicle(src, vehicle, row, action, extra, severity)
    local by = Logs.person(src)
    local plate = Logs.plate(GetVehicleNumberPlateText(vehicle))

    local fields = {
        playerSource = src,
        player = by.name,
        playerCitizenId = by.citizenid,
        playerJob = by.job,
        plate = plate,
        vehicleId = row and row.id,
        model = row and row.modelName,
        owner = row and Logs.nameOf(row.citizenid),
        ownerCitizenId = row and row.citizenid,
    }

    for key, value in pairs(extra or {}) do
        fields[key] = value
    end

    Logs.send(('%s %s %s'):format(by.name, action, plate or 'a vehicle'), fields, severity)
end

local function restore(netId)
    local vehicle = vehicleFrom(netId)
    local row = vehicle and rowOf(vehicle)

    if not row then return end

    local saved = {}

    for key in pairs(Mods.keys) do
        if row.props[key] ~= nil then
            saved[key] = row.props[key]
        end
    end

    Entity(vehicle).state:set('ox_lib:setVehicleProperties', saved, true)
end

local function endSession(src)
    local netId = sessions[src] and sessions[src].netId

    if not netId then return end

    sessions[src] = nil

    if holders[netId] == src then
        holders[netId] = nil
    end

    restore(netId)
end

local function int(value, min, max)
    if type(value) ~= 'number' or value ~= math.floor(value) then return end
    if value < min or value > max then return end

    return math.tointeger(value)
end

local function rgb(value)
    if type(value) ~= 'table' then return end

    local r, g, b = int(value[1], 0, 255), int(value[2], 0, 255), int(value[3], 0, 255)

    if r and g and b then
        return { r, g, b }
    end
end

local cleaners = {
    int = function(value, spec)
        return int(value, spec.min, spec.max)
    end,
    bool = function(value)
        if type(value) == 'boolean' then
            return value
        end
    end,
    rgb = rgb,
    neon = function(value)
        if type(value) ~= 'table' then return end

        local out = {}

        for i = 1, 4 do
            if type(value[i]) ~= 'boolean' then return end

            out[i] = value[i]
        end

        return out
    end,
    extras = function(value)
        if type(value) ~= 'table' then return end

        local out, count = {}, 0

        for id, off in pairs(value) do
            local extra = int(tonumber(id), 1, 14)
            off = int(off, 0, 1)

            if not extra or not off then return end

            out[tostring(extra)] = off
            count += 1
        end

        if count > 0 then
            return out
        end
    end,
}

local function check(changes)
    if type(changes) ~= 'table' then return end

    local clean, lines, total, billed = {}, {}, 0, {}
    local prices = Config.Prices

    local function line(label, price)
        if price <= 0 then return end

        lines[#lines + 1] = { label = label, qty = 1, price = price }
        total += price
    end

    for key, value in pairs(changes) do
        local spec = Mods.keys[key]
        local cleaned = spec and cleaners[spec.kind](value, spec)

        if cleaned == nil then return end

        clean[key] = cleaned

        local levels = prices.performance[key]

        if levels then
            line(('%s: %s'):format(LINE_LABELS[key], performance[key].levels[cleaned + 2]), levels[cleaned + 2] or 0)
        elseif spec.group == 'turbo' then
            if cleaned then
                line(LINE_LABELS.turbo, prices.turbo)
            end
        elseif spec.group == 'extra' then
            local count = 0

            for _ in pairs(cleaned) do
                count += 1
            end

            line(('%s (%d)'):format(LINE_LABELS.extra, count), prices.extra * count)
        elseif not billed[spec.group] then
            billed[spec.group] = true
            line(LINE_LABELS[spec.group] or spec.group, prices[spec.group] or prices.part)
        end
    end

    if next(clean) then
        return clean, lines, total
    end
end

local function money(n)
    local s = tostring(n):reverse():gsub('(%d%d%d)', '%1,'):reverse():gsub('^,', '')

    return '$' .. s
end

local function payCommission(record)
    local shop, by, payer = record.shop, record.by, record.payer
    local amount = math.floor(record.total * (shop.commission or 0))

    if amount <= 0 then return 0 end
    if not payer or payer.citizenid == by.citizenid then return 0 end

    local reason = locale('account_commission', by.name)

    if not banking.removeAccountMoney(shop.account, amount, reason) then return 0 end

    if not core:AddMoney(by.citizenid, 'bank', amount, 'mechanic-commission') then
        banking.addAccountMoney(shop.account, amount, locale('account_commission_returned'))
        return 0
    end

    return amount
end

local function takeTax(shop, total)
    if not shop.account then return total end

    local tax = math.floor(total * (shop.tax or 0))
    local reason = locale('account_tax', math.floor((shop.tax or 0) * 100 + 0.5))

    if tax > 0 and not banking.removeAccountMoney(shop.account, tax, reason) then
        return 0
    end

    return tax
end

local function settle(record)
    record.tax = takeTax(record.shop, record.total)
    record.commission = record.shop.account and payCommission(record) or 0
end

local function onlineSource(person)
    local player = person and person.source and core:GetPlayer(person.source)

    if player and player.PlayerData.citizenid == person.citizenid then
        return person.source
    end
end

local function logInstall(row, before, after, clean, record)
    local changes = Logs.describe(clean, before, after)
    local by, payer, shop = record.by, record.payer, record.shop
    local plate = Logs.plate(after.plate) or '?'
    local tax, commission = record.tax or 0, record.commission or 0
    local count = #changes == 1 and '1 change' or ('%d changes'):format(#changes)
    local payerSource = onlineSource(payer)

    Logs.send(('%s installed %s on %s (%s) at %s'):format(by.name, count, plate, row.modelName, shop.label), {
        playerSource = onlineSource(by),
        targetSource = payerSource ~= by.source and payerSource or nil,
        plate = plate,
        vehicleId = row.id,
        model = row.modelName,
        owner = Logs.nameOf(row.citizenid),
        ownerCitizenId = row.citizenid,
        shop = shop.label,
        shopId = shop.id,
        aircraftShop = shop.aircraft == true,
        installedBy = by.name,
        installedByCitizenId = by.citizenid,
        installedByJob = by.job,
        payment = record.payment,
        paidBy = payer and payer.name,
        paidByCitizenId = payer and payer.citizenid,
        billId = record.billId,
        total = record.total,
        shopKept = record.total - tax - commission,
        commission = commission,
        tax = tax,
        changes = table.concat(changes, '; '),
        changeCount = #changes,
        upgrades = Logs.upgrades(after),
    })
end

local function install(vehicleId, netId, clean, record)
    local row = vehicles:GetPlayerVehicle(vehicleId)

    if not row then return false end

    local props = row.props or {}
    local before = lib.table.deepclone(props)

    applyOrder(props, clean)

    local vehicle = vehicleFrom(netId)
    local current = vehicle and rowOf(vehicle)

    if current and current.id == vehicleId then
        vehicles:SaveVehicle(vehicle, { props = props })
        Entity(vehicle).state:set('ox_lib:setVehicleProperties', clean, true)
    else
        MySQL.update.await('UPDATE player_vehicles SET mods = ? WHERE id = ?', { json.encode(props), vehicleId })
    end

    logInstall(row, before, props, clean, record)

    return true
end

local function tellMechanic(src, result)
    if GetPlayerName(src) then
        TriggerClientEvent('whey_mechanic:client:billed', src, result)
    end
end

billing.onStatus(function(id, status)
    local order = orders[id]

    if not order then return end

    orders[id] = nil

    if status ~= 'paid' and status ~= 'collected' then
        local total = money(order.total)
        local message = ('%s %s a %s customs bill for %s'):format(order.ownerName, status, total, order.plate)

        Logs.send(message, {
            plate = order.plate,
            vehicleId = order.vehicleId,
            shop = order.shop.label,
            billId = id,
            status = status,
            total = order.total,
            billedBy = order.record.by.name,
            billedByCitizenId = order.record.by.citizenid,
            paidBy = order.record.payer.name,
            paidByCitizenId = order.record.payer.citizenid,
        })

        return tellMechanic(order.src, {
            ok = false,
            netId = order.netId,
            msg = locale('bill_not_paid', order.ownerName),
        })
    end

    settle(order.record)

    local ok = install(order.vehicleId, order.netId, order.clean, order.record)
    local paid = money(order.total)

    tellMechanic(order.src, {
        ok = ok,
        netId = order.netId,
        msg = ok and locale('bill_paid_installed', order.ownerName, paid) or locale('paid_vehicle_gone'),
    })
end)

local READY_STATE = 'whey_mechanic:ready'
local FITTABLE = { billed = true, paid = true }

local requests = {}
local requestByBill = {}

local function requestForVehicle(vehicleId)
    for _, request in pairs(requests) do
        if request.vehicleId == vehicleId then return request end
    end
end

local function publishReady()
    local ready = {}

    for _, request in pairs(requests) do
        if FITTABLE[request.status] then
            ready[request.plate] = true
        end
    end

    GlobalState[READY_STATE] = ready
end

local function requestsChanged(notice)
    for _, id in ipairs(GetPlayers()) do
        local src = tonumber(id)

        if src and isMechanic(src) then
            TriggerClientEvent('whey_mechanic:client:requestsChanged', src, notice)
        end
    end
end

local function sourceOf(citizenid)
    local player = core:GetPlayerByCitizenId(citizenid)

    return player and player.PlayerData.source
end

local function tellCustomer(citizenid, text, kind)
    local src = sourceOf(citizenid)

    if src then
        TriggerClientEvent('ox_lib:notify', src, { title = locale('notify_title'), description = text, type = kind or 'inform' })
    end
end

local function saveRequest(request)
    MySQL.update.await([[UPDATE `whey_mechanic_requests` SET `changes` = ?, `parts` = ?, `total` = ?, `status` = ?,
        `bill_id` = ?, `paid_by` = ?, `paid_by_name` = ?, `tax` = ?, `installer` = ?, `installer_name` = ?,
        `previous` = ?, `net_id` = ? WHERE `id` = ?]], {
        json.encode(request.changes),
        json.encode(request.parts),
        request.total,
        request.status,
        request.billId,
        request.paidBy,
        request.paidByName,
        request.tax,
        request.installer,
        request.installerName,
        request.previous and json.encode(request.previous),
        request.netId,
        request.id,
    })
end

local function dropRequest(request)
    requests[request.id] = nil

    if request.billId then
        requestByBill[request.billId] = nil
    end

    MySQL.update.await('DELETE FROM `whey_mechanic_requests` WHERE `id` = ?', { request.id })
    publishReady()
end

local function logRequest(request, action, extra, severity)
    local fields = {
        requestId = request.id,
        plate = request.plate,
        vehicleId = request.vehicleId,
        model = request.model,
        customer = request.customer,
        customerCitizenId = request.citizenid,
        total = request.total,
        changes = table.concat(request.parts, '; '),
    }

    for key, value in pairs(extra or {}) do
        fields[key] = value
    end

    Logs.send(('%s %s (%s)'):format(request.customer, action, request.plate), fields, severity)
end

MySQL.ready(function()
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS `whey_mechanic_requests` (
        `id` INT NOT NULL AUTO_INCREMENT,
        `shop` VARCHAR(32) NOT NULL,
        `vehicle_id` INT NOT NULL,
        `plate` VARCHAR(16) NOT NULL,
        `model` VARCHAR(64) NULL,
        `citizenid` VARCHAR(50) NOT NULL,
        `customer` VARCHAR(100) NOT NULL,
        `changes` LONGTEXT NOT NULL,
        `parts` LONGTEXT NOT NULL,
        `total` INT NOT NULL DEFAULT 0,
        `status` VARCHAR(12) NOT NULL,
        `bill_id` VARCHAR(64) NULL,
        `paid_by` VARCHAR(50) NULL,
        `paid_by_name` VARCHAR(100) NULL,
        `tax` INT NULL,
        `installer` VARCHAR(50) NULL,
        `installer_name` VARCHAR(100) NULL,
        `previous` LONGTEXT NULL,
        `net_id` INT NULL,
        `created_at` BIGINT NOT NULL,
        PRIMARY KEY (`id`),
        KEY `vehicle_id` (`vehicle_id`)
    ) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]])

    for _, row in ipairs(MySQL.query.await('SELECT * FROM `whey_mechanic_requests`') or {}) do
        local request = {
            id = row.id,
            shop = row.shop,
            vehicleId = row.vehicle_id,
            plate = row.plate,
            model = row.model,
            citizenid = row.citizenid,
            customer = row.customer,
            changes = json.decode(row.changes) or {},
            parts = json.decode(row.parts) or {},
            total = row.total,
            status = row.status,
            billId = row.bill_id,
            paidBy = row.paid_by,
            paidByName = row.paid_by_name,
            tax = row.tax,
            installer = row.installer,
            installerName = row.installer_name,
            previous = row.previous and json.decode(row.previous),
            netId = row.net_id,
            createdAt = row.created_at,
        }

        if Config.Shops[request.shop] then
            requests[request.id] = request

            if request.billId then
                requestByBill[request.billId] = request.id
            end
        end
    end

    publishReady()
end)

local function requestInstall(src, shop, vehicle, row, clean, total)
    local existing = requestForVehicle(row.id)

    if existing and existing.status == 'paid' then
        return { ok = false, msg = locale('request_already_paid') }
    end

    if existing and existing.status == 'billed' then
        return { ok = false, msg = locale('request_already_billed') }
    end

    if existing and existing.status == 'fitted' then
        return { ok = false, msg = locale('request_already_fitted') }
    end

    local customer = Logs.person(src)
    local after = lib.table.deepclone(row.props)

    applyOrder(after, clean)

    local request = existing or {
        shop = shop.id,
        vehicleId = row.id,
        plate = Logs.plate(row.props.plate or GetVehicleNumberPlateText(vehicle)) or '?',
        model = row.modelName,
        createdAt = os.time() * 1000,
    }

    request.citizenid = customer.citizenid
    request.customer = customer.name
    request.changes = clean
    request.parts = Logs.describe(clean, row.props, after)
    request.total = total
    request.status = total == 0 and 'paid' or 'requested'

    if existing then
        saveRequest(request)
    else
        request.id = MySQL.insert.await([[INSERT INTO `whey_mechanic_requests`
            (`shop`, `vehicle_id`, `plate`, `model`, `citizenid`, `customer`, `changes`, `parts`, `total`, `status`, `created_at`)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)]], {
            request.shop,
            request.vehicleId,
            request.plate,
            request.model,
            request.citizenid,
            request.customer,
            json.encode(request.changes),
            json.encode(request.parts),
            request.total,
            request.status,
            request.createdAt,
        })

        if not request.id then
            return { ok = false, msg = locale('request_save_failed') }
        end

        requests[request.id] = request
    end

    publishReady()
    requestsChanged(locale('notice_requested', request.customer, request.plate, money(total)))
    logRequest(request, existing and 'changed an install request' or 'requested an install', {
        playerSource = src,
        shop = shop.label,
    })

    local msg = total == 0 and locale('request_sent_free')
        or locale('request_sent', money(total))

    return { ok = true, requested = true, msg = msg }
end

local function hasTablet(src)
    return isMechanic(src) and (exports.ox_inventory:Search(src, 'count', Config.Install.item) or 0) > 0
end

local function requestForMechanic(src, id)
    if not hasTablet(src) then return nil, locale('need_tablet_duty') end

    local request = requests[tonumber(id)]

    if not request then return nil, locale('request_gone') end

    return request
end

lib.callback.register('whey_mechanic:server:requests', function(src)
    if not hasTablet(src) then return false end

    local list = {}

    for _, request in pairs(requests) do
        local installing = request.installing

        list[#list + 1] = {
            id = request.id,
            customer = request.customer,
            online = sourceOf(request.citizenid) ~= nil,
            plate = request.plate,
            model = request.model,
            parts = request.parts,
            total = request.total,
            status = installing and 'installing' or request.status,
            installer = installing and installing.name or request.installerName,
            paidBy = request.paidByName,
            createdAt = request.createdAt,
        }
    end

    table.sort(list, function(a, b) return a.createdAt < b.createdAt end)

    return list
end)

lib.callback.register('whey_mechanic:server:billRequest', function(src, id)
    local request, problem = requestForMechanic(src, id)

    if not request then return { ok = false, msg = problem } end
    if request.status ~= 'requested' then return { ok = false, msg = locale('already_billed') } end

    local target = sourceOf(request.citizenid)

    if not target then return { ok = false, msg = locale('customer_offline', request.customer) } end

    local shop = Config.Shops[request.shop]
    local clean, lines, total = check(request.changes)

    if not clean or not total or total <= 0 then return { ok = false, msg = locale('cannot_bill') } end

    local reason = locale('bill_reason', request.plate)
    local sent, msg, billId = billing.create(src, target, shop.account, lines, reason)

    if not sent or not billId then return { ok = false, msg = msg or locale('bill_failed') } end

    local by = Logs.person(src)

    request.status = 'billed'
    request.total = total
    request.billId = tostring(billId)
    request.billedBy = src
    requestByBill[request.billId] = request.id
    saveRequest(request)
    requestsChanged()

    logRequest(request, ('was billed %s by %s'):format(money(total), by.name), {
        playerSource = src,
        targetSource = target,
        billId = request.billId,
        billedBy = by.name,
        billedByCitizenId = by.citizenid,
    })

    return { ok = true, msg = locale('bill_sent', request.customer, money(total)) }
end)

lib.callback.register('whey_mechanic:server:declineRequest', function(src, id)
    local request, problem = requestForMechanic(src, id)

    if not request then return { ok = false, msg = problem } end
    if request.status ~= 'requested' then return { ok = false, msg = locale('decline_billed') } end

    local by = Logs.person(src)

    dropRequest(request)
    requestsChanged()
    tellCustomer(request.citizenid, locale('customer_declined', request.plate), 'error')
    logRequest(request, ('had an install request declined by %s'):format(by.name), {
        playerSource = src,
        declinedBy = by.name,
        declinedByCitizenId = by.citizenid,
    })

    return { ok = true, msg = locale('request_declined') }
end)

local function removeParts(request)
    local row = vehicles:GetPlayerVehicle(request.vehicleId)
    local previous = request.previous

    if not row or type(previous) ~= 'table' or not next(previous) then return false end

    local props = row.props or {}

    applyOrder(props, previous)

    local vehicle = request.netId and vehicleFrom(request.netId)
    local current = vehicle and rowOf(vehicle)

    if current and current.id == request.vehicleId then
        vehicles:SaveVehicle(vehicle, { props = props })
        Entity(vehicle).state:set('ox_lib:setVehicleProperties', previous, true)
    else
        MySQL.update.await('UPDATE player_vehicles SET mods = ? WHERE id = ?', { json.encode(props), request.vehicleId })
    end

    return true
end

local function tellBiller(src, text)
    if src and GetPlayerName(src) then
        TriggerClientEvent('ox_lib:notify', src, { title = locale('notify_title'), description = text, type = 'error' })
    end
end

billing.onStatus(function(id, status)
    local requestId = requestByBill[tostring(id)]
    local request = requestId and requests[requestId]

    if not request then return end

    requestByBill[request.billId] = nil

    local shop = Config.Shops[request.shop]
    local paid = status == 'paid' or status == 'collected'
    local fields = { billId = tostring(id), status = status }

    if not paid and request.status == 'fitted' then
        local removed = removeParts(request)

        dropRequest(request)
        requestsChanged(locale('notice_parts_removed', request.customer, request.plate))
        tellCustomer(request.citizenid, locale('customer_parts_removed', request.plate), 'error')
        fields.removed = removed
        logRequest(request, ('%s the bill after the parts were fitted, so they were taken off'):format(status), fields, 'warn')

        return
    end

    if not paid then
        request.status = 'requested'
        request.billId = nil
        saveRequest(request)
        publishReady()
        requestsChanged()
        tellBiller(request.billedBy, locale('bill_not_paid', request.customer))
        logRequest(request, ('%s the bill for an install'):format(status), fields)

        return
    end

    local payer = sourceOf(request.citizenid)
    local person = payer and Logs.person(payer)

    request.tax = takeTax(shop, request.total)
    request.paidBy = person and person.citizenid or request.citizenid
    request.paidByName = person and person.name or request.customer
    fields.tax = request.tax

    if request.status == 'fitted' then
        local record = {
            shop = shop,
            by = { citizenid = request.installer, name = request.installerName },
            payer = { citizenid = request.paidBy, name = request.paidByName },
            total = request.total,
        }

        fields.commission = shop.account and payCommission(record) or 0
        fields.installedBy = request.installerName

        dropRequest(request)
        requestsChanged(locale('notice_paid_fitted', request.customer, request.plate))
        logRequest(request, 'paid for parts already fitted', fields)

        return
    end

    request.status = 'paid'
    request.billId = nil
    saveRequest(request)
    publishReady()
    requestsChanged(locale('notice_paid', request.customer, request.plate))
    tellCustomer(request.citizenid, locale('customer_paid', request.plate), 'success')
    logRequest(request, 'paid for an install', fields)
end)

local INSTALL_REACH = Config.Install.distance + 2.0

local function isEmpty(vehicle)
    for seat = -1, 14 do
        if GetPedInVehicleSeat(vehicle, seat) ~= 0 then return false end
    end

    return true
end

local function fittable(src, netId)
    if not isMechanic(src) then return nil, nil, nil, locale('not_on_duty') end

    local vehicle = vehicleFrom(netId)

    if not vehicle or not within(src, vehicle, INSTALL_REACH) then
        return nil, nil, nil, locale('stand_next')
    end

    local row = rowOf(vehicle)
    local request = row and requestForVehicle(row.id)

    if not request or not FITTABLE[request.status] then
        return nil, nil, nil, locale('nothing_to_fit')
    end

    local shop = Config.Shops[request.shop]

    if not inShop(shop, vehicle) then return nil, nil, nil, locale('park_in_bay', shop.label) end
    if not isEmpty(vehicle) then return nil, nil, nil, locale('vehicle_occupied') end

    return request, vehicle, row
end

lib.callback.register('whey_mechanic:server:installStart', function(src, netId)
    local request, _, _, problem = fittable(src, netId)

    if not request then return false, problem end

    local installing = request.installing
    local window = (Config.Install.seconds + 10) * 1000

    if installing and installing.src ~= src and GetGameTimer() - installing.at < window then
        return false, locale('already_fitting', installing.name)
    end

    request.installing = { src = src, name = Logs.person(src).name, at = GetGameTimer(), netId = netId }
    requestsChanged()

    return true, { seconds = Config.Install.seconds, penalty = Config.Install.penalty, parts = request.parts }
end)

local function installingBy(src)
    for _, request in pairs(requests) do
        if request.installing and request.installing.src == src then return request end
    end
end

RegisterNetEvent('whey_mechanic:server:installCancel', function()
    local request = installingBy(source)

    if request then
        request.installing = nil
        requestsChanged()
    end
end)

local AGAIN = { ok = false, msg = locale('install_again') }

lib.callback.register('whey_mechanic:server:installFinish', function(src, netId)
    local job = installingBy(src)

    if not job then return AGAIN end

    local installing = job.installing

    job.installing = nil
    requestsChanged()

    if installing.netId ~= netId then return AGAIN end

    if GetGameTimer() - installing.at < Config.Install.minSeconds * 1000 then
        return { ok = false, msg = locale('install_too_quick') }
    end

    local request, _, row, problem = fittable(src, netId)

    if request ~= job then return { ok = false, msg = problem or AGAIN.msg } end

    local clean = check(request.changes)

    if not clean then return { ok = false, msg = locale('cannot_fit') } end

    local shop = Config.Shops[request.shop]
    local by = Logs.person(src)
    local count = #request.parts

    if request.status == 'billed' then
        local previous = {}
        local props = row.props or {}

        for key, value in pairs(clean) do
            if key == 'extras' then
                previous.extras = {}

                for extra, off in pairs(value) do
                    previous.extras[extra] = (props.extras or {})[extra] or (off == 0 and 1 or 0)
                end
            elseif props[key] ~= nil then
                previous[key] = props[key]
            end
        end

        local record = { shop = shop, by = by, payment = 'bill, not paid yet', total = request.total, billId = request.billId }

        if not install(row.id, netId, clean, record) then
            return { ok = false, msg = locale('vehicle_gone') }
        end

        request.status = 'fitted'
        request.installer = by.citizenid
        request.installerName = by.name
        request.previous = previous
        request.netId = netId
        saveRequest(request)
        publishReady()
        requestsChanged()
        tellCustomer(request.citizenid, locale('customer_fitted_unpaid', request.plate))

        return { ok = true, msg = locale('fitted_unpaid', request.plate, count) }
    end

    local payer = request.paidBy and { citizenid = request.paidBy, name = request.paidByName } or nil

    local record = {
        shop = shop,
        by = by,
        payer = payer,
        payment = request.total == 0 and 'free' or 'requested bill',
        total = request.total,
        tax = request.tax or 0,
    }

    record.commission = payer and shop.account and payCommission(record) or 0

    dropRequest(request)
    requestsChanged()

    if not install(row.id, netId, clean, record) then
        return { ok = false, msg = locale('vehicle_gone') }
    end

    tellCustomer(request.citizenid, locale('customer_fitted', request.plate), 'success')

    return { ok = true, msg = locale('fitted', request.plate, count) }
end)

AddEventHandler('playerDropped', function()
    local request = installingBy(source)

    if request then
        request.installing = nil
        requestsChanged()
    end
end)

local function isDamaged(vehicle)
    local health = Config.RepairedHealth

    return GetVehicleEngineHealth(vehicle) < health or GetVehicleBodyHealth(vehicle) < health
end

local function payersFor(src, vehicle, row)
    local list = {}

    for _, nearby in ipairs(lib.getNearbyPlayers(GetEntityCoords(vehicle), Config.Billing.payerDistance)) do
        local id = tonumber(nearby.id)
        local person = id and Logs.person(id)

        if person and person.citizenid then
            list[#list + 1] = {
                id = id,
                name = person.name,
                owner = person.citizenid == row.citizenid,
                you = id == src,
            }
        end
    end

    table.sort(list, function(a, b)
        if a.you ~= b.you then return a.you end
        if a.owner ~= b.owner then return a.owner end

        return a.name < b.name
    end)

    return list
end

local function findPayer(list, id)
    for _, payer in ipairs(list) do
        if payer.id == id then
            return payer
        end
    end
end

local function sessionFor(src, netId)
    local session = sessions[src]

    if session and session.netId == netId then
        return session
    end
end

local REOPEN = { ok = false, msg = locale('reopen') }

lib.callback.register('whey_mechanic:server:open', function(src, shopId, netId)
    local shop = type(shopId) == 'string' and Config.Shops[shopId]
    local vehicle = vehicleFrom(netId)

    if not shop or not vehicle then return false, locale('cannot_work') end

    local row = rowOf(vehicle)

    local function refuse(reason)
        logVehicle(src, vehicle, row, 'was turned away from customs on', { shop = shop.label, reason = reason }, 'warn')

        return false, reason
    end

    local problem = refusal(src, shop, vehicle)

    if problem then return refuse(problem) end

    local holder = holders[netId]

    if holder and holder ~= src and sessionFor(holder, netId) then
        return refuse(locale('vehicle_busy'))
    end

    if not row then return refuse(locale('not_registered')) end
    if not mayModify(src, shop, vehicle, row) then return refuse(locale('need_owner_or_keys')) end

    local damaged = isDamaged(vehicle)

    if damaged and not shop.repair then return refuse(locale('damaged_first')) end

    endSession(src)
    sessions[src] = { netId = netId, shop = shop, damaged = damaged }
    holders[netId] = src

    logVehicle(src, vehicle, row, 'opened customs on', { shop = shop.label, damaged = damaged })

    return true, { billing = shop.billing, damaged = damaged, repair = shop.repair, requests = shop.requests == true }
end)

lib.callback.register('whey_mechanic:server:payers', function(src, netId)
    local vehicle = sessionFor(src, netId) and vehicleFrom(netId)
    local row = vehicle and rowOf(vehicle)

    if not row then return {} end

    return payersFor(src, vehicle, row)
end)

lib.callback.register('whey_mechanic:server:shopRepair', function(src, netId)
    local session = sessionFor(src, netId)

    if not session then return REOPEN end

    local shop = session.shop
    local vehicle = vehicleFrom(netId)

    if not shop.repair or not vehicle then
        return { ok = false, msg = locale('shop_no_repair') }
    end

    if not session.damaged then
        return { ok = true, msg = locale('already_repaired') }
    end

    local problem = refusal(src, shop, vehicle)

    if problem then
        return { ok = false, msg = problem }
    end

    if not core:RemoveMoney(src, 'bank', shop.repair, 'mechanic-repair') then
        return { ok = false, msg = locale('not_enough_bank', money(shop.repair)) }
    end

    if shop.account then
        banking.addAccountMoney(shop.account, shop.repair, locale('account_repair', shop.label))
    end

    local owner = NetworkGetEntityOwner(vehicle)

    TriggerClientEvent('whey_mechanic:client:fix', owner > 0 and owner or src, netId)
    session.damaged = false

    logVehicle(src, vehicle, rowOf(vehicle), 'paid for a repair on', { shop = shop.label, total = shop.repair })

    return { ok = true, msg = locale('repaired_for', money(shop.repair)) }
end)

lib.callback.register('whey_mechanic:server:apply', function(src, netId, changes, payerId)
    local session = sessionFor(src, netId)

    if not session then return REOPEN end

    local shop = session.shop
    local vehicle = vehicleFrom(netId)

    if not vehicle then
        return { ok = false, msg = locale('vehicle_gone') }
    end

    local problem = refusal(src, shop, vehicle)

    if problem then
        return { ok = false, msg = problem }
    end

    if session.damaged then
        return { ok = false, msg = locale('repair_first') }
    end

    local clean, lines, total = check(changes)

    if not clean then
        return { ok = false, msg = locale('install_failed') }
    end

    local row = rowOf(vehicle)

    if not row then
        return { ok = false, msg = locale('not_registered') }
    end

    local function refuse(reason)
        logVehicle(src, vehicle, row, 'was refused an install on', { shop = shop.label, reason = reason }, 'warn')

        return { ok = false, msg = reason }
    end

    if AIRCRAFT[GetVehicleType(vehicle)] then
        for key in pairs(Mods.aircraftLocked) do
            if clean[key] ~= nil and clean[key] ~= -1 then
                return refuse(locale('no_weapons'))
            end
        end
    end

    if not mayModify(src, shop, vehicle, row) then
        return refuse(locale('need_owner_or_keys'))
    end

    if shop.requests then
        return requestInstall(src, shop, vehicle, row, clean, total)
    end

    local by = Logs.person(src)

    if total == 0 then
        install(row.id, netId, clean, { shop = shop, by = by, payment = 'free', total = 0 })

        return { ok = true, msg = locale('installed') }
    end

    local payer

    if shop.billing ~= 'driver' then
        payer = findPayer(payersFor(src, vehicle, row), tonumber(payerId))

        if not payer then
            return { ok = false, msg = locale('payer_too_far') }
        end
    end

    if not payer or payer.you then
        if not core:RemoveMoney(src, 'bank', total, 'mechanic-customs') then
            return { ok = false, msg = locale('not_enough_bank', money(total)) }
        end

        local record = { shop = shop, by = by, payer = by, payment = 'own bank', total = total }

        if shop.account then
            banking.addAccountMoney(shop.account, total, locale('account_upgrade', shop.label, by.name))
        end

        settle(record)
        install(row.id, netId, clean, record)

        return { ok = true, msg = locale('installed_from_bank', money(total)) }
    end

    local reason = locale('bill_reason', row.props.plate or '?')
    local sent, msg, billId = billing.create(src, payer.id, shop.account, lines, reason)

    if not sent or not billId then
        return { ok = false, msg = msg or locale('bill_failed') }
    end

    local record = {
        shop = shop,
        by = by,
        payer = Logs.person(payer.id),
        payment = 'bill',
        total = total,
        billId = billId,
    }
    local plate = Logs.plate(row.props.plate) or '?'

    orders[billId] = {
        src = src,
        shop = shop,
        netId = netId,
        vehicleId = row.id,
        plate = plate,
        clean = clean,
        total = total,
        ownerName = payer.name,
        record = record,
    }

    local after = lib.table.deepclone(row.props)

    applyOrder(after, clean)

    logVehicle(src, vehicle, row, ('billed %s %s for customs on'):format(payer.name, money(total)), {
        targetSource = payer.id,
        shop = shop.label,
        billId = billId,
        total = total,
        paidBy = record.payer.name,
        paidByCitizenId = record.payer.citizenid,
        changes = table.concat(Logs.describe(clean, row.props, after), '; '),
    })

    return { ok = true, waiting = true, msg = locale('bill_waiting', money(total)) }
end)

RegisterNetEvent('whey_mechanic:server:close', function()
    endSession(source)
end)

local INVOICE_ACCOUNT = Config.Account

lib.callback.register('whey_mechanic:server:invoice', function(src, target, index)
    if not isMechanic(src) then return false, locale('not_on_duty') end

    local item = type(index) == 'number' and Config.Invoices.items[index]
    target = tonumber(target)

    if not item or not target or target == src or not GetPlayerName(target) then
        return false, locale('invoice_failed')
    end

    local ped = GetPlayerPed(target)

    if ped == 0 or not within(src, ped, Config.Invoices.distance + 2.0) then return false, locale('too_far') end

    local lines = { { label = item.label, qty = 1, price = item.price } }
    local sent, msg, billId = billing.create(src, target, INVOICE_ACCOUNT, lines, item.label)

    if not sent then return false, msg or locale('invoice_failed') end

    local mechanic, customer = Logs.person(src), Logs.person(target)

    if billId then
        invoices[billId] = {
            citizenid = mechanic.citizenid,
            mechanic = mechanic.name,
            customer = customer.name,
            customerCitizenId = customer.citizenid,
            price = item.price,
            cut = item.cut or 0,
            label = item.label,
        }
    end

    local price = money(item.price)
    local message = ('%s invoiced %s %s for %s'):format(mechanic.name, customer.name, price, item.label:lower())

    Logs.send(message, {
        playerSource = src,
        targetSource = target,
        mechanic = mechanic.name,
        mechanicCitizenId = mechanic.citizenid,
        customer = customer.name,
        customerCitizenId = customer.citizenid,
        invoice = item.label,
        billId = billId,
        total = item.price,
        cut = item.cut or 0,
    })

    return true, locale('invoice_sent', money(item.price), item.label:lower())
end)

local function payCut(invoice)
    if invoice.cut <= 0 then return false end

    local reason = locale('account_cut', invoice.label)

    if not banking.removeAccountMoney(INVOICE_ACCOUNT, invoice.cut, reason) then return false end

    if not core:AddMoney(invoice.citizenid, 'bank', invoice.cut, 'mechanic-invoice-cut') then
        banking.addAccountMoney(INVOICE_ACCOUNT, invoice.cut, locale('account_cut_returned'))
        return false
    end

    return true
end

billing.onStatus(function(id, status)
    local invoice = invoices[id]

    if not invoice then return end

    invoices[id] = nil

    local paid = status == 'paid' or status == 'collected'
    local cutPaid = paid and payCut(invoice)
    local price = money(invoice.price)
    local message = ('%s %s a %s invoice for %s'):format(invoice.customer, status, price, invoice.label:lower())

    Logs.send(message, {
        mechanic = invoice.mechanic,
        mechanicCitizenId = invoice.citizenid,
        customer = invoice.customer,
        customerCitizenId = invoice.customerCitizenId,
        invoice = invoice.label,
        billId = id,
        status = status,
        total = invoice.price,
        cut = cutPaid and invoice.cut or 0,
    })
end)

local function hasKit(src)
    return (exports.ox_inventory:Search(src, 'count', Config.Repair.kit) or 0) > 0
end

lib.callback.register('whey_mechanic:server:repairStart', function(src, netId, useKit)
    local kit = useKit == true or not isMechanic(src)

    if kit and not hasKit(src) then return false end

    local vehicle = vehicleFrom(netId)

    if not vehicle or not within(src, vehicle, REPAIR_REACH) then return false end

    repairs[src] = { netId = netId, at = GetGameTimer(), kit = kit }

    return true
end)

lib.callback.register('whey_mechanic:server:repairFinish', function(src, netId)
    local job = repairs[src]
    repairs[src] = nil

    if not job or job.netId ~= netId then return false end
    if GetGameTimer() - job.at < Config.Repair.duration - REPAIR_EARLY then return false end
    if not job.kit and not isMechanic(src) then return false end

    local vehicle = vehicleFrom(netId)

    if not vehicle or not within(src, vehicle, REPAIR_REACH) then return false end

    if job.kit and not exports.ox_inventory:RemoveItem(src, Config.Repair.kit, 1) then return false end

    local owner = NetworkGetEntityOwner(vehicle)

    TriggerClientEvent('whey_mechanic:client:fix', owner > 0 and owner or src, netId)

    local coords = GetEntityCoords(vehicle)

    logVehicle(src, vehicle, rowOf(vehicle), job.kit and 'used a repair kit on' or 'repaired', {
        repairKit = job.kit,
        engineBefore = math.floor(GetVehicleEngineHealth(vehicle)),
        bodyBefore = math.floor(GetVehicleBodyHealth(vehicle)),
        coords = ('%.1f, %.1f, %.1f'):format(coords.x, coords.y, coords.z),
    })

    return true
end)

RegisterNetEvent('whey_mechanic:server:repairCancel', function()
    repairs[source] = nil
end)

local KIT_ACCOUNT = Config.Account
local COUNTER_REACH = Config.Kits.counter.radius + 2.0
local BUYER_REACH = Config.Billing.payerDistance + 2.0
local OFFER_WINDOW = Config.Kits.sell.answerTime + 5000

local offers = {}

lib.callback.register('whey_mechanic:server:buyStock', function(src, index, count)
    if not isMechanic(src) then return false, locale('not_on_duty') end

    local counter = Config.Kits.counter
    local stock = type(index) == 'number' and counter.items[index]
    local item = stock and exports.ox_inventory:Items(stock.name)

    if not item then return false, locale('buy_failed') end

    count = int(count, 1, stock.max)

    if not count then return false, locale('pick_between', stock.max) end

    if #(GetEntityCoords(GetPlayerPed(src)) - counter.coords) > COUNTER_REACH then
        return false, locale('go_counter')
    end

    if not exports.ox_inventory:CanCarryItem(src, stock.name, count) then
        return false, locale('cannot_carry')
    end

    local total = stock.price * count
    local by = Logs.person(src)
    local bought = ('%dx %s'):format(count, item.label)

    if not banking.removeAccountMoney(KIT_ACCOUNT, total, ('%s: %s'):format(bought, by.name)) then
        return false, locale('business_broke', money(total))
    end

    if not exports.ox_inventory:AddItem(src, stock.name, count) then
        banking.addAccountMoney(KIT_ACCOUNT, total, locale('account_stock_returned', bought))
        return false, locale('cannot_carry')
    end

    Logs.send(('%s bought %s for %s from the business'):format(by.name, bought, money(total)), {
        playerSource = src,
        player = by.name,
        playerCitizenId = by.citizenid,
        item = stock.name,
        count = count,
        total = total,
    })

    return true, locale('stock_bought', bought, money(total))
end)

lib.callback.register('whey_mechanic:server:kitBuyers', function(src, netId)
    if not isMechanic(src) then return {} end

    local vehicle = vehicleFrom(netId)

    if not vehicle or not within(src, vehicle, REPAIR_REACH) then return {} end

    local list = {}

    for _, nearby in ipairs(lib.getNearbyPlayers(GetEntityCoords(vehicle), Config.Billing.payerDistance)) do
        local id = tonumber(nearby.id)
        local person = id and id ~= src and Logs.person(id)

        if person and person.citizenid then
            list[#list + 1] = { id = id, name = person.name }
        end
    end

    table.sort(list, function(a, b) return a.name < b.name end)

    return list
end)

local function saleProblem(src, vehicle, target, count)
    if not isMechanic(src) then return locale('not_on_duty') end
    if not GetPlayerName(target) then return locale('buyer_left') end
    if not vehicle or not within(src, vehicle, REPAIR_REACH) then return locale('stay_next') end

    local ped = GetPlayerPed(target)

    if ped == 0 or #(GetEntityCoords(ped) - GetEntityCoords(vehicle)) > BUYER_REACH then return locale('too_far') end

    if (exports.ox_inventory:Search(src, 'count', Config.Repair.kit) or 0) < count then
        return locale('no_kits', count)
    end
end

lib.callback.register('whey_mechanic:server:sellKit', function(src, netId, target, count)
    target = tonumber(target)
    count = int(count, 1, Config.Kits.sell.max)

    if not target or target == src or not count then return false, locale('sell_failed') end

    local vehicle = vehicleFrom(netId)
    local problem = saleProblem(src, vehicle, target, count)

    if problem then return false, problem end

    if offers[src] and GetGameTimer() - offers[src] < OFFER_WINDOW then
        return false, locale('offer_pending')
    end

    local price = Config.Kits.sell.price * count
    local what = locale('kits_count', count)
    local seller, buyer = Logs.person(src), Logs.person(target)

    offers[src] = GetGameTimer()
    local accepted = lib.callback.await('whey_mechanic:client:offerKit', target, seller.name, price, count)
    offers[src] = nil

    if not accepted then return false, locale('offer_declined', buyer.name) end

    vehicle = vehicleFrom(netId)
    problem = saleProblem(src, vehicle, target, count)

    if problem then return false, problem end

    local kit = Config.Repair.kit

    if not exports.ox_inventory:CanCarryItem(target, kit, count) then return false, locale('buyer_cannot_carry', buyer.name, what) end
    if not exports.ox_inventory:RemoveItem(src, kit, count) then return false, locale('seller_missing', what) end

    if not core:RemoveMoney(target, 'bank', price, 'mechanic-kit') then
        exports.ox_inventory:AddItem(src, kit, count)
        return false, locale('buyer_broke', buyer.name, money(price))
    end

    banking.addAccountMoney(KIT_ACCOUNT, price, locale('account_kit_sold', what, buyer.name, seller.name))

    if not exports.ox_inventory:AddItem(target, kit, count) then
        banking.removeAccountMoney(KIT_ACCOUNT, price, locale('account_kit_refund', what, buyer.name))
        core:AddMoney(target, 'bank', price, 'mechanic-kit-refund')
        exports.ox_inventory:AddItem(src, kit, count)
        return false, locale('buyer_cannot_carry', buyer.name, what)
    end

    TriggerClientEvent('ox_lib:notify', target, {
        title = locale('notify_title'),
        description = locale('kit_bought', what, money(price)),
        type = 'success',
    })

    Logs.send(('%s sold %s %s for %s'):format(seller.name, buyer.name, what, money(price)), {
        playerSource = src,
        targetSource = target,
        mechanic = seller.name,
        mechanicCitizenId = seller.citizenid,
        customer = buyer.name,
        customerCitizenId = buyer.citizenid,
        count = count,
        total = price,
    })

    return true, locale('kit_sold', buyer.name, what, money(price))
end)

local CLEAN_REACH = Config.Clean.distance + 2.0

local cleans = {}

local function hasCloth(src)
    return (exports.ox_inventory:Search(src, 'count', Config.Clean.item) or 0) > 0
end

lib.callback.register('whey_mechanic:server:cleanStart', function(src, netId)
    local vehicle = vehicleFrom(netId)

    if not hasCloth(src) or not vehicle or not within(src, vehicle, CLEAN_REACH) then return false end

    cleans[src] = { netId = netId, at = GetGameTimer() }

    return true
end)

lib.callback.register('whey_mechanic:server:cleanFinish', function(src, netId)
    local job = cleans[src]
    cleans[src] = nil

    if not job or job.netId ~= netId then return false end
    if GetGameTimer() - job.at < Config.Clean.duration - REPAIR_EARLY then return false end

    local vehicle = vehicleFrom(netId)

    if not vehicle or not within(src, vehicle, CLEAN_REACH) or not hasCloth(src) then return false end
    if Config.Clean.consume and not exports.ox_inventory:RemoveItem(src, Config.Clean.item, 1) then return false end

    local owner = NetworkGetEntityOwner(vehicle)

    TriggerClientEvent('whey_mechanic:client:clean', owner > 0 and owner or src, netId)

    return true
end)

RegisterNetEvent('whey_mechanic:server:cleanCancel', function()
    cleans[source] = nil
end)

AddEventHandler('playerDropped', function()
    endSession(source)
    repairs[source] = nil
    offers[source] = nil
    cleans[source] = nil
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    for src in pairs(sessions) do
        endSession(src)
    end
end)

if Config.VersionCheck then
    lib.versionCheck(Config.Repository)
end
