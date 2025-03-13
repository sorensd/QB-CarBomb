fx_version 'cerulean'
game 'gta5'

author 'VisionDEV1'
description 'QBCore Car Bomb Script'
version '1.0.0'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'shared/*.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

dependencies {
    'qb-core',
    'qb-inventory'
}
