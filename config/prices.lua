-- What every change costs in the customs menu. The server prices each order itself from this file.
Config.Prices = {
    -- Performance prices are per level, starting at stock (always free to go back to).
    performance = {
        modEngine = { 0, 10000, 20000, 35000, 50000 },
        modBrakes = { 0, 6000, 12000, 20000 },
        modTransmission = { 0, 8000, 16000, 25000, 35000 },
        modSuspension = { 0, 4000, 8000, 12000, 16000, 20000 },
        modArmor = { 0, 100000, 250000, 450000, 700000, 1000000 }, -- 20%, 40%, 60%, 80%, 100%
    },
    turbo = 30000,

    part = 2500, -- any body, interior or plate part
    horn = 1000,
    primary = 3000,
    secondary = 3000,
    pearlescent = 2000,
    wheelColor = 1500,
    interiorColor = 1500,
    dashboardColor = 1500,
    wheels = 4000,
    tyreSmoke = 2500,
    xenon = 2500,
    neon = 5000,
    windowTint = 1500,
    plateIndex = 1000,
    livery = 3000,
    roofLivery = 2000,
    extra = 500, -- per extra toggled
}
