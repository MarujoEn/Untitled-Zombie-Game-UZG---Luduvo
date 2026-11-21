
-- UZG - Olympia Configuration

return {
    Id = "Olympia",
    DisplayName = "Olympia",

    -- Ammunition
    MaxAmmo = 2,

    -- Timing (seconds)
    FireInterval = 0.65,
    ShootAnimationDuration = 0.22,
    ReloadDuration = 1.8,

    -- Screen placement
    Screen = {
        Size = UDim2.new(0.46, 0, 0.58, 0),
        Position = UDim2.new(0.54, 0, 0.42, 0)
    },

    -- Weapon animations
    Sprites = {
        Idle = "sprites/Olympia/Olympia_Idle.png",
        Shoot = "sprites/Olympia/Olympia_Shoot.png",
        Reload = "sprites/Olympia/Olympia_Reload.png"
    }
}
