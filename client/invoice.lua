local MENU = 'whey_mechanic:invoice'

local function money(n)
    local s = tostring(n):reverse():gsub('(%d%d%d)', '%1,'):reverse():gsub('^,', '')

    return '$' .. s
end

local function send(target, index)
    local ok, msg = lib.callback.await('whey_mechanic:server:invoice', false, target, index)

    Mechanic.notify(msg or locale('invoice_failed'), ok and 'success' or 'error')
end

local function choose(target)
    local options = {}

    for i, item in ipairs(Config.Invoices.items) do
        options[i] = {
            title = item.label,
            description = money(item.price),
            icon = 'file-invoice-dollar',
            onSelect = function()
                send(target, i)
            end,
        }
    end

    lib.registerContext({ id = MENU, title = locale('target_invoice'), options = options })
    lib.showContext(MENU)
end

exports.ox_target:addGlobalPlayer({
    {
        name = 'whey_mechanic:invoice',
        icon = 'fa-solid fa-file-invoice-dollar',
        label = locale('target_invoice'),
        distance = Config.Invoices.distance,
        canInteract = function()
            return not cache.vehicle and Mechanic.isOnDuty()
        end,
        onSelect = function(data)
            choose(GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity)))
        end,
    },
})
