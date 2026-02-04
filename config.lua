return {
    Debug = false,

    ValidationInterval = 5000,  -- How often to validate zone integrity (ms)

    CooldownTimes = {
        short = 500,  -- Quick check cooldown (ms)
        long = 1000   -- Full verification cooldown (ms)
    },

    RestrictedItems = {
        ['bandage'] = {
            zones = {
                {
                    coords = vec3(311.14, -594.33, 43.28),
                    radius = 50.0,
                    name = 'Hospital'
                },
                {
                    coords = vec3(441.81, -982.05, 30.69),
                    radius = 30.0,
                    name = 'Police Station'
                }
            },
            message = "You can only use this item in a medical or police facility."
        },
            
        ['armor'] = {
            zones = {
                {
                    coords = vec3(452.31, -980.03, 30.69),
                    radius = 25.0,
                    name = 'Armory'
                }
            },
            message = "You can only use armor in designated armories."
        }
    }
}