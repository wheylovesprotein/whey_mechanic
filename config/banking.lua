-- Server side. How the resource moves money in and out of a business account (Config.Account and each
-- shop's `account`). The default uses Renewed-Banking, where a job's account has the same name as the job.
-- Change the three functions below to use another banking resource.
--
-- Player money is always handled by qbx_core. Only business accounts go through this file.

return {
    -- Puts money into a business account. `reason` is a short text for a statement, if your banking shows one.
    addAccountMoney = function(account, amount, reason)
        return exports['Renewed-Banking']:addAccountMoney(account, amount)
    end,

    -- Takes money out of a business account. Must return false when the account cannot pay.
    removeAccountMoney = function(account, amount, reason)
        return exports['Renewed-Banking']:removeAccountMoney(account, amount)
    end,

    -- Bills. With `false` the resource uses its own bill: the customer gets a prompt listing every line,
    -- and accepting pays the total from their bank into the account.
    --
    -- To send bills through your own billing resource instead, set this to a function that creates the bill
    -- and returns its id (or nil and a message for the mechanic when it could not be sent):
    --
    --   sendBill = function(source, target, account, lines, reason, total)
    --       return exports.my_billing:create(source, target, account, total, reason)
    --   end,
    --
    -- `lines` is a list of { label, qty, price }. When that bill is settled, tell the mechanic resource with
    --   exports.whey_mechanic:resolveBill(id, 'paid')      the money is already in the account
    --   exports.whey_mechanic:resolveBill(id, 'declined')  the customer did not pay
    sendBill = false,
}
