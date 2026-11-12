local hooks = require 'config.banking'
local Logs = require 'server.logs'

local core = exports.qbx_core

local billing = {}
local listeners = {}
local answering = {}
local sent = 0

function billing.onStatus(listener)
    listeners[#listeners + 1] = listener
end

function billing.resolve(id, status)
    if id == nil or type(status) ~= 'string' then return end

    id = tostring(id)

    for _, listener in ipairs(listeners) do
        listener(id, status)
    end
end

local function collect(target, account, total, reason)
    if not GetPlayerName(target) then return false end

    if not core:RemoveMoney(target, 'bank', total, 'mechanic-bill') then
        TriggerClientEvent('ox_lib:notify', target, {
            title = locale('notify_title'),
            description = locale('bill_cannot_afford'),
            type = 'error',
        })

        return false
    end

    if account then
        hooks.addAccountMoney(account, total, reason)
    end

    return true
end

local function ask(id, src, target, account, lines, reason, total)
    local ok, accepted = pcall(lib.callback.await, 'whey_mechanic:client:bill', target, {
        from = Logs.person(src).name,
        reason = reason,
        lines = lines,
        total = total,
    })

    if answering[target] == id then
        answering[target] = nil
    end

    local paid = ok and accepted == true and collect(target, account, total, reason)

    billing.resolve(id, paid and 'paid' or 'declined')
end

function billing.create(src, target, account, lines, reason)
    local total = 0

    for _, line in ipairs(lines) do
        total += line.price * line.qty
    end

    if hooks.sendBill then
        local id, problem = hooks.sendBill(src, target, account, lines, reason, total)

        if not id then return false, problem end

        return true, nil, tostring(id)
    end

    if answering[target] then return false, locale('bill_target_busy') end

    sent += 1

    local id = ('%d-%d'):format(os.time(), sent)

    answering[target] = id

    CreateThread(function()
        ask(id, src, target, account, lines, reason, total)
    end)

    return true, nil, id
end

exports('resolveBill', billing.resolve)

return billing
