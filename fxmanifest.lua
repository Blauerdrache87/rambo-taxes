shared_script '@AC/waveshield.lua' --this line was automatically written by WaveShield

fx_version 'cerulean'
games { 'gta5' }

author 'rambo'
description 'srp-taxes'

server_scripts {
    'server/*.lua',
    'config.lua',
    '@oxmysql/lib/MySQL.lua',
}

shared_scripts {
    'shared/*.lua',
}

server_only 'yes'

lua54 'yes'