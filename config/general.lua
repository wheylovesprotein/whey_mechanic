Config = {}

-- Prints every log line to the server console, on top of sending it to config/logs.lua.
Config.Debug = false

-- Checks GitHub for a newer release when the resource starts.
Config.VersionCheck = true
Config.Repository = 'wheylovesprotein/whey_mechanic'

-- The Qbox job that counts as a mechanic. Mechanics repair for free, send invoices, use the parts counter,
-- bill part requests from the tablet and fit the parts.
Config.Job = 'mechanic'
Config.RequireDuty = true -- false lets off-duty mechanics work too

-- The business account that pays for stock at the parts counter and receives invoices and repair kit sales.
-- How money goes in and out of an account is set in config/banking.lua.
Config.Account = 'mechanic'

-- A ground ring only bosses of Config.Job can see, to mark where your boss menu is (for example qbx_management's).
-- It only draws the ring, it does not open anything. Set to false for no ring.
Config.BossMenu = {
    coords = vec3(-339.41, -157.41, 44.59), -- taken standing on the spot
    marker = {
        type = 25, -- a flat circle
        scale = vec3(0.8, 0.8, 0.8),
        color = { r = 0, g = 120, b = 255, a = 150 },
        drawDistance = 3.0,
    },
}

-- Anyone can inspect a vehicle from the vehicle target or with the command. It shows a card with the
-- vehicle's condition and performance upgrades.
Config.Inspect = {
    command = 'inspect', -- false for no command
    distance = 4.0,      -- how close you have to be to the vehicle
    duration = 5000,     -- how long the card stays up (ms)
    keepWithin = 10.0,   -- the card closes early once you walk further than this from the vehicle
}

-- On-duty mechanics repair from the vehicle target for free. Anyone else needs a repair kit, which is used up.
Config.Repair = {
    duration = 12000,   -- ms
    distance = 3.0,
    kit = 'repair_kit', -- the ox_inventory item
}

-- Anyone carrying a cloth can clean a vehicle from the vehicle target, or by using the cloth next to one.
Config.Clean = {
    item = 'cloth',
    duration = 8000, -- ms
    distance = 3.0,
    consume = false, -- true uses a cloth up each clean
}

-- Fitting requested parts. On-duty mechanics see requests on the install tablet and bill the customer from it.
-- Once the bill is sent they target the car to fit the parts: three small jobs against the clock.
Config.Install = {
    item = 'mechanic_tablet', -- using it opens the install tablet; the command only works while carrying one
    command = 'mods',         -- false for no command
    seconds = 30,             -- time to finish all three jobs
    minSeconds = 8,           -- the server refuses an install finished faster than this
    distance = 3.0,           -- how close the mechanic has to stand to the car
    penalty = 1.5,            -- seconds lost for a wrong nut, wire or overfill
}

-- Engine and body health (out of 1000) a vehicle needs before it can be customized. A repair sets both to 1000.
Config.RepairedHealth = 990

Config.Billing = {
    payerDistance = 5.0, -- who can be picked to pay or to buy a repair kit: anyone standing this close to the vehicle
    answerTime = 30000,  -- ms a customer has to accept a bill before it counts as declined (built-in bills only)
}
