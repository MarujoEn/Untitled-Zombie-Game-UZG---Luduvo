-- UZG - Weapon Service
-- Server authoritative weapon system

-- Network events
local WeaponShot = game.EventTable(
    "UZG_WeaponShot",
    game.EventTable.ToServer,
    {
        {"origin", game.EventTable.Vec3},
        {"direction", game.EventTable.Vec3}
    },
    {
        Coalesce = "First"
    }
)

local WeaponReload = game.EventTable(
    "UZG_WeaponReload",
    game.EventTable.ToServer,
    {}
)

local ZombieHit = game.EventTable(
    "UZG_ZombieHit",
    game.EventTable.ToClients,
    {
        {"zombie", game.EventTable.Instance}
    }
)

-- Weapon configuration
local OlympiaConfig =
    require("../weapons/olympia")

local DAMAGE = OlympiaConfig.Damage
local RANGE = OlympiaConfig.Range

local MAX_AMMO = OlympiaConfig.MaxAmmo
local FIRE_INTERVAL = OlympiaConfig.FireInterval
local RELOAD_DURATION = OlympiaConfig.ReloadDuration

-- Shot validation
local MAX_ORIGIN_OFFSET = 8

-- Per-player weapon states
local WeaponStates = {}

local function GetWeaponState(player)

    local state = WeaponStates[player]

    if not state then

        state = {
            Ammo = MAX_AMMO,
            IsReloading = false,
            LastShotTime = -math.huge
        }

        WeaponStates[player] = state
    end

    return state
end

-- Handle reload requests
WeaponReload.OnServerEvent:Connect(function(player)

    local state = GetWeaponState(player)

    if state.IsReloading then
        return
    end

    if state.Ammo >= MAX_AMMO then
        return
    end

    state.IsReloading = true

    print("[UZG] Server reload started:", player.Name)

    task.delay(RELOAD_DURATION, function()

        -- Ignore callbacks for a player state that no longer exists
        if WeaponStates[player] ~= state then
            return
        end

        state.Ammo = MAX_AMMO
        state.IsReloading = false

        print("[UZG] Server reload complete:", player.Name)
    end)
end)

-- Handle weapon shots
WeaponShot.OnServerEvent:Connect(function(
    player,
    origin,
    direction
)

    local character = player.Character

    -- Validate player character
    if not character or not character:IsAlive() then
        return
    end

    if not character:HasComponent("Health") then
        return
    end

    if character.Health <= 0 then
        return
    end

    local state = GetWeaponState(player)

    -- Validate ammunition and reload state
    if state.IsReloading or state.Ammo <= 0 then
        return
    end

    -- Validate aim direction
    local directionMagnitude = direction.Magnitude

    if directionMagnitude < 0.95 or directionMagnitude > 1.05 then
        return
    end

    direction = direction / directionMagnitude

    -- Validate camera origin
    local originDistance =
        (origin - character.Position).Magnitude

    if originDistance > MAX_ORIGIN_OFFSET then
        return
    end

    -- Server-side fire rate validation
    local currentTime = tick()

    if currentTime - state.LastShotTime < FIRE_INTERVAL then
        return
    end

    state.LastShotTime = currentTime
    state.Ammo -= 1

    print(
        "[UZG] Server shot:",
        player.Name,
        "Ammo:",
        state.Ammo,
        "/",
        MAX_AMMO
    )

    -- Perform authoritative raycast
    local result = game.Physics.Raycast(
        origin,
        direction,
        RANGE,
        {
            ExcludeInstances = {character}
        }
    )

    -- Nothing was hit
    if not result or not result.Instance then
        return
    end

    local hitInstance = result.Instance

    if not hitInstance:IsAlive() then
        return
    end

    -- Find the character that owns the hit part
    local zombie =
        hitInstance:FindAncestorWithComponent("Health")

    if not zombie then
        return
    end

    -- Only damage instances marked as UZG zombies
    if zombie.attr.UZG_Zombie ~= true then
        return
    end

    if zombie.Health <= 0 then
        return
    end

    -- Apply damage on the server
    zombie:TakeDamage(DAMAGE, character)

    print(
        "[UZG] Olympia hit:",
        zombie.Name,
        "Damage:",
        DAMAGE,
        "HP:",
        zombie.Health,
        "/",
        zombie.MaxHealth
    )

    -- Notify all clients about the confirmed hit
    ZombieHit:FireAllClients(zombie)

    if zombie.Health <= 0 then

        print(
            "[UZG] Zombie killed:",
            zombie.Name
        )
    end
end)

print("[UZG] Weapon Service initialized!")