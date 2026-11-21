-- UZG - Weapon Client

-- Load modules
local WeaponController =
    require("./systems/WeaponController")

local OlympiaConfig =
    require("../weapons/olympia")

-- Network events declared by the server
local WeaponShot = game.EventTable("UZG_WeaponShot")
local WeaponReload = game.EventTable("UZG_WeaponReload")
local ZombieHit = game.EventTable("UZG_ZombieHit")

print("[UZG] Weapon modules loaded!")

local activeWeapon = nil

-- Flash an image component
local function FlashImage(image)

    local originalColor = image.ImageColor3

    image.ImageColor3 = Vector3.new(1, 0.25, 0.25)

    task.delay(0.12, function()

        if image:IsAlive() then
            image.ImageColor3 = originalColor
        end
    end)
end

-- Apply damage feedback to a zombie
local function FlashZombie(zombie)

    if not zombie or not zombie:IsAlive() then
        return
    end

    local foundImage = false

    -- Check the zombie root
    if zombie:HasComponent("Image") then

        FlashImage(zombie)
        foundImage = true
    end

    -- Check every descendant
    for _, descendant in zombie:GetDescendants() do

        if descendant:HasComponent("Image") then

            FlashImage(descendant)
            foundImage = true
        end
    end

    if not foundImage then
        warn("[UZG] No Image component found on zombie:", zombie.Name)
    end
end

-- Receive confirmed server hits
ZombieHit.OnClientEvent:Connect(function(zombie)

    FlashZombie(zombie)

    -- Hit confirmation on the crosshair
    if activeWeapon and activeWeapon.Crosshair then

        local crosshair = activeWeapon.Crosshair

        if crosshair:IsAlive() then

            crosshair.TextColor3 = Vector3.new(1, 0.2, 0.2)

            task.delay(0.12, function()

                if crosshair:IsAlive() then
                    crosshair.TextColor3 = Vector3.new(1, 1, 1)
                end
            end)
        end
    end
end)

-- Initialize weapon
local function InitializeWeapon()

    local overlay = game.Overlay

    if not overlay then
        return
    end

    activeWeapon = WeaponController.new(
        OlympiaConfig,
        overlay
    )

    print("[UZG] Active weapon:", OlympiaConfig.DisplayName)
end

-- Get a ray from the center of the camera view
local function GetCenterRay()

    local screen = game.World.Screen

    if not screen then
        warn("[UZG] ERROR: World.Screen is nil!")
        return nil, nil
    end

    local viewport = screen.AbsoluteSize

    print(
        "[UZG] Viewport:",
        viewport.x,
        viewport.y
    )

    if viewport.x <= 0 or viewport.y <= 0 then
        warn("[UZG] ERROR: Invalid viewport size!")
        return nil, nil
    end

    local center = Vector3.new(
        viewport.x * 0.5,
        viewport.y * 0.5,
        0
    )

    print(
        "[UZG] Calculating center ray:",
        center.x,
        center.y
    )

    local origin, direction =
        game.World.ScreenToRay(center)

    if not origin or not direction then
        warn("[UZG] ERROR: ScreenToRay returned nil!")
        return nil, nil
    end

    print("[UZG] Center ray created!")

    return origin, direction
end

-- Fire the active weapon
local function FireWeapon()

    print("[UZG] FireWeapon called!")

    local origin, direction = GetCenterRay()

    if not origin or not direction then
        warn("[UZG] Shot cancelled: invalid ray.")
        return
    end

    local fired = activeWeapon:TryShoot()

    if not fired then

        print(
            "[UZG] Shot rejected:",
            "State:", activeWeapon.State,
            "Ammo:", activeWeapon.Ammo,
            "Cooldown:", activeWeapon.FireCooldown
        )

        return
    end

    WeaponShot:FireServer(
        origin,
        direction
    )

    print("[UZG] Shot request sent to server!")
end

-- Main update
function Update(dt: number)

    if not activeWeapon then
        InitializeWeapon()
    end

    if not activeWeapon then
        return
    end

    activeWeapon:Update(dt)

    -- Reload
    if game.Input.KeyPressed(game.Input.Key.R) then

        if activeWeapon:TryReload() then
            WeaponReload:FireServer()
        end
    end

    -- Shoot
    if game.Input.ButtonPressed(game.Input.Button.Left) then

        print("[UZG] Left click detected!")

        FireWeapon()
    end
end