lib.callback.register('whey_mechanic:client:bill', function(bill)
    local open = true
    local rows = {}

    for i, line in ipairs(bill.lines) do
        rows[i] = ('- %s: %s'):format(line.label, Mechanic.money(line.price * line.qty))
    end

    SetTimeout(Config.Billing.answerTime, function()
        if open then lib.closeAlertDialog() end
    end)

    local answer = lib.alertDialog({
        header = bill.reason,
        content = ('%s\n\n%s'):format(locale('bill_text', bill.from, Mechanic.money(bill.total)), table.concat(rows, '\n')),
        centered = true,
        cancel = true,
        labels = { confirm = locale('bill_pay'), cancel = locale('bill_decline') },
    })

    open = false

    return answer == 'confirm'
end)
