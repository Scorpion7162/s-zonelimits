fx_version 'cerulean'
game 'gta5'
lua54 'yes'
name 's-zonelimits'
author 'Scorpion'
version '1.0.0'
description 'Zone-based item usage restriction'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/client.lua'
}

server_scripts {
    'server/server.lua'
}

server_export 'checkItemZone'

exports {
    'isInItemZone',
    'getPlayerZones'
}