local function money(n)
    local s = tostring(n):reverse():gsub('(%d%d%d)', '%1,'):reverse():gsub('^,', '')

    return '$' .. s
end

local counter = Config.Kits.counter

local function labelOf(name)
    local item = exports.ox_inventory:Items(name)

    return item and item.label or name
end

local function buy(index)
    local stock = counter.items[index]
    local count = 1

    if stock.max > 1 then
        local input = lib.inputDialog(labelOf(stock.name), {
            {
                type = 'number',
                label = locale('how_many'),
                description = locale('each_business', money(stock.price)),
                default = 1,
                min = 1,
                max = stock.max,
                required = true,
            },
        })

        if not input then return end

        count = input[1]
    end

    local ok, msg = lib.callback.await('whey_mechanic:server:buyStock', false, index, count)

    Mechanic.notify(msg or locale('buy_failed'), ok and 'success' or 'error')
end

local function openCounter()
    local options = {}

    for i, stock in ipairs(counter.items) do
        options[i] = {
            title = labelOf(stock.name),
            description = locale('each_business', money(stock.price)),
            image = ('nui://ox_inventory/web/images/%s.png'):format(stock.name),
            onSelect = function() buy(i) end,
        }
    end

    lib.registerContext({ id = 'whey_mechanic:counter', title = locale('parts_counter'), options = options })
    lib.showContext('whey_mechanic:counter')
end

exports.ox_target:addSphereZone({
    coords = counter.coords,
    radius = counter.radius,
    options = {
        {
            name = 'whey_mechanic:counter',
            icon = 'fa-solid fa-toolbox',
            label = locale('parts_counter'),
            canInteract = function()
                return Mechanic.isOnDuty()
            end,
            onSelect = openCounter,
        },
    },
})

lib.callback.register('whey_mechanic:client:offerKit', function(seller, price, count)
    local open = true

    count = tonumber(count) or 1

    SetTimeout(Config.Kits.sell.answerTime, function()
        if open then lib.closeAlertDialog() end
    end)

    local answer = lib.alertDialog({
        header = locale('kit_offer_title'),
        content = locale('kit_offer_text', seller, count, money(price)),
        centered = true,
        cancel = true,
        labels = { confirm = locale('buy'), cancel = locale('no_thanks') },
    })

    open = false

    return answer == 'confirm'
end)

local function offer(netId, buyer)
    local held = exports.ox_inventory:Search('count', Config.Repair.kit) or 0
    local max = math.min(Config.Kits.sell.max, held)
    local count = 1

    if max > 1 then
        local input = lib.inputDialog(locale('sell_kits_to', buyer.name), {
            {
                type = 'number',
                label = locale('how_many'),
                description = locale('each_you_have', money(Config.Kits.sell.price), held),
                default = 1,
                min = 1,
                max = max,
                required = true,
            },
        })

        if not input then return end

        count = input[1]
    end

    Mechanic.notify(locale('kit_offered', buyer.name, count))

    local ok, msg = lib.callback.await('whey_mechanic:server:sellKit', false, netId, buyer.id, count)

    Mechanic.notify(msg or locale('sell_failed'), ok and 'success' or 'error')
end

function Mechanic.sellKit(vehicle)
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    local buyers = lib.callback.await('whey_mechanic:server:kitBuyers', false, netId)

    if not buyers or #buyers == 0 then
        return Mechanic.notify(locale('nobody_nearby'), 'error')
    end

    local options = {}

    for i, buyer in ipairs(buyers) do
        options[i] = {
            title = buyer.name,
            description = locale('per_kit', money(Config.Kits.sell.price)),
            icon = 'user',
            onSelect = function() offer(netId, buyer) end,
        }
    end

    lib.registerContext({ id = 'whey_mechanic:sellKit', title = locale('target_sell_kit'), options = options })
    lib.showContext('whey_mechanic:sellKit')
end
