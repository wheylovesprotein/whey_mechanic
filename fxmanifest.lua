fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

name 'whey_mechanic'
author 'wheylovesprotein'
version '1.0.0'
description 'Mechanic job for Qbox: customs shop, part requests with an install tablet, repairs, cleaning and inspections'
repository 'https://github.com/wheylovesprotein/whey_mechanic'

shared_scripts {
    '@ox_lib/init.lua',
    'config/general.lua',
    'config/shops.lua',
    'config/prices.lua',
}

client_scripts {
    '@qbx_core/modules/playerdata.lua',
    'client/main.lua',
    'client/inspect.lua',
    'client/kits.lua',
    'client/repair.lua',
    'client/clean.lua',
    'client/invoice.lua',
    'client/billing.lua',
    'client/customs.lua',
    'client/installs.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

ui_page 'web/dist/index.html'

files {
    'shared/mods.lua',
    'locales/*.json',
    'web/dist/index.html',
    'web/dist/**/*',
}

dependencies {
    '/onesync',
    'qbx_core',
    'ox_lib',
    'oxmysql',
    'ox_inventory',
    'ox_target',
}
