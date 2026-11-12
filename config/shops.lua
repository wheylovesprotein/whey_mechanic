-- Customs shops. Sit in the driver seat of a vehicle inside one and press E.
--   label        the name on the map, in the menu and on bills
--   coords       where the blip goes, and the middle of the shop when there are no spots
--   radius       how close to coords, or to a spot, the vehicle has to be parked
--   spots        bays a vehicle has to be parked in; leave out to use one area of `radius` around coords
--   job          only on-duty players with this job can use the menu; leave out for anyone
--   aircraft     true takes only helicopters and planes, otherwise the shop takes everything but them
--   requests     true makes the menu a request: the customer picks parts, a mechanic bills them from the
--                install tablet and then fits the parts at the car (Config.Install). billing is ignored.
--   billing      for shops without requests. 'driver' takes the money from the driver's bank straight away.
--                'owner' asks who pays out of the people standing by the vehicle (the owner is marked) and
--                installs once they pay; picking yourself pays from your own bank.
--   account      the business account the money goes into (config/banking.lua); leave out to just take it
--   tax          share of a customs payment that is removed from the account as tax (0.15 = 15%)
--   commission   share paid to the mechanic who fitted the parts (0.10 = 10%), unless they paid themselves
--   repair       price of a repair in the menu, paid by the driver; leave out to turn damaged vehicles away
--   ownerOrKeys  true lets only the vehicle's owner, or someone holding its keys (qbx_vehiclekeys), customize it
--   blip         the map blip, or leave out for none
Config.Shops = {
    lscustoms = {
        label = 'Los Santos Customs',
        coords = vec3(-371.82, -118.06, 38.70),
        radius = 5.0,
        spots = {
            vec3(-347.26, -124.50, 39.02),
            vec3(-349.12, -130.96, 39.02),
            vec3(-342.57, -113.52, 39.02),
            vec3(-339.31, -95.04, 39.02),
            vec3(-352.48, -90.08, 39.02),
            vec3(-365.92, -85.25, 39.02),
            vec3(-321.84, -128.63, 39.02),
            vec3(-323.20, -133.80, 39.02),
            vec3(-325.18, -138.78, 39.02),
            vec3(-326.99, -144.17, 39.02),
            vec3(-319.76, -123.91, 39.02),
            vec3(-317.71, -118.50, 39.02),
            vec3(-315.64, -113.49, 39.02),
            vec3(-313.85, -108.16, 39.02),
            vec3(-312.06, -102.95, 39.02),
        },
        requests = true,
        ownerOrKeys = true,
        account = 'mechanic',
        tax = 0.15,
        commission = 0.10, -- the account keeps the other 75%
        blip = { sprite = 72, color = 47, scale = 0.8 },
    },
    aircraft = {
        label = 'Aircraft Customs',
        coords = vec3(-968.50, -3005.62, 13.95),
        radius = 25.0,
        aircraft = true,
        billing = 'driver',
        repair = 5000,
        ownerOrKeys = true,
        blip = { sprite = 43, color = 3, scale = 0.8 },
    },
}

-- The parts counter, where on-duty mechanics buy stock paid out of Config.Account.
-- Mechanics can also sell their repair kits to a customer from the vehicle target: the customer confirms,
-- pays from their bank into Config.Account, and gets the kits.
Config.Kits = {
    counter = {
        coords = vec3(-345.88, -170.84, 39.26),
        radius = 1.5,
        items = {
            -- price is per item, max is the most in one purchase (what they can carry limits it first)
            { name = 'repair_kit', price = 1000, max = 1000 },
            { name = 'mechanic_tablet', price = 500, max = 1 },
            { name = 'cloth', price = 100, max = 1000 },
        },
    },
    sell = {
        price = 2500,       -- what the customer pays, per kit
        max = 50,           -- most kits in one sale
        answerTime = 15000, -- ms the customer has to accept before the offer lapses
    },
}

-- What an on-duty mechanic can invoice a player for by targeting them. Only these, at these prices.
-- The money goes into Config.Account, apart from `cut`, which goes to the mechanic's bank once it is paid.
Config.Invoices = {
    distance = 3.0,
    items = {
        { label = 'Vehicle repair', price = 5000, cut = 2500 },
    },
}
