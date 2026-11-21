
-- UZG - Weapon Client
-- Version: Input Event Driven v2

--------------------------------------------------
-- LOAD MODULES
--------------------------------------------------

local WeaponController =
    require("./systems/WeaponController")

local OlympiaConfig =
    require("../weapons/olympia")

--------------------------------------------------
-- NETWORK EVENTS
--------------------------------------------------

local WeaponShot = game.EventTable("UZG_WeaponShot")
local WeaponReload = game.EventTable("UZG_WeaponReload")
local ZombieHit = game.EventTable("UZG_ZombieHit")

print("[UZG] Weapon modules loaded!")

--------------------------------------------------
-- INPUT STATE
--------------------------------------------------

local leftClickRequested = false

-- IMPORTANT:
-- We register clicks directly through InputBegan.
-- Processed is intentionally ignored for shooting.
-- This bypasses UI-consumed mouse input.

game.Input.InputBegan:Connect(function(input, processed)

    if input.Button == game.Input.Button.Left then

        print(
            "[UZG DEBUG] LEFT CLICK DETECTED",
            "Processed:", processed
        )

        leftClickRequested = true

    end

    if input.Key == game.Input.Key.R then

        print(
            "[UZG DEBUG] RELOAD KEY DETECTED",
            "Processed:", processed
        )

    end

end)

--------------------------------------------------
-- WEAPON STATE
--------------------------------------------------

local activeWeapon = nil

--------------------------------------------------
-- INITIALIZE WEAPON
--------------------------------------------------

local function InitializeWeapon()

    local overlay = game.Overlay

    if not overlay then
        return
    end

    activeWeapon = WeaponController.new(
        OlympiaConfig,
        overlay
    )

    print(
        "[UZG] Active weapon:",
        OlympiaConfig.DisplayName
    )

end

--------------------------------------------------
-- IMAGE FEEDBACK
--------------------------------------------------

local function FlashImage(image)

    local originalColor = image.ImageColor3

    image.ImageColor3 = Vector3.new(
        1, 0.25, 0.25
    )

    task.delay(0.12, function()

        if image:IsAlive() then
            image.ImageColor3 = originalColor
        end

    end)

end

--------------------------------------------------
-- ZOMBIE HIT FEEDBACK
--------------------------------------------------

local function FlashZombie(zombie)

    if not zombie or not zombie:IsAlive() then
        return
    end

    local foundImage = false

    if zombie:HasComponent("UIImage") then

        FlashImage(zombie)
        foundImage = true

    end

    for _, descendant in zombie:GetDescendants() do

        if descendant:HasComponent("UIImage") then

            FlashImage(descendant)
            foundImage = true

        end

    end

    if not foundImage then

        warn(
            "[UZG] No UIImage found on zombie:",
            zombie.Name
        )

    end

end

--------------------------------------------------
-- CROSSHAIR HIT FEEDBACK
--------------------------------------------------

local function FlashCrosshair()

    if not activeWeapon then
        return
    end

    local crosshair = activeWeapon.Crosshair

    if not crosshair or not crosshair:IsAlive() then
        return
    end

    local originalColors = {}

    -- The crosshair is a Frame.
    -- Its visible elements are child Frames.

    for _, element in crosshair:GetDescendants() do

        if element:IsAlive() then

            originalColors[element] =
                element.BackgroundColor3

            element.BackgroundColor3 =
                Vector3.new(1, 0.2, 0.2)

        end

    end

    task.delay(0.12, function()

        for element, originalColor in pairs(originalColors) do

            if element:IsAlive() then

                element.BackgroundColor3 =
                    originalColor

            end

        end

    end)

end

--------------------------------------------------
-- RECEIVE SERVER HIT CONFIRMATION
--------------------------------------------------

ZombieHit.OnClientEvent:Connect(function(zombie)

    FlashZombie(zombie)
    FlashCrosshair()

end)

--------------------------------------------------
-- GET CENTER CAMERA RAY
--------------------------------------------------

local function GetCenterRay()

    local screen = game.World.Screen

    if not screen then

        warn("[UZG] World.Screen is nil!")
        return nil, nil

    end

    local viewport = screen.AbsoluteSize

    if viewport.x <= 0 or viewport.y <= 0 then

        warn("[UZG] Invalid viewport!")
        return nil, nil

    end

    local center = Vector3.new(
        viewport.x * 0.5,
        viewport.y * 0.5,
        0
    )

    local origin, direction =
        game.World.ScreenToRay(center)

    if not origin or not direction then

        warn("[UZG] ScreenToRay failed!")
        return nil, nil

    end

    return origin, direction

end

--------------------------------------------------
-- FIRE WEAPON
--------------------------------------------------

local function FireWeapon()

    if not activeWeapon then
        return
    end

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

--------------------------------------------------
-- MAIN UPDATE
--------------------------------------------------

function Update(dt: number)

    --------------------------------------------------
    -- INITIALIZE
    --------------------------------------------------

    if not activeWeapon then
        InitializeWeapon()
    end

    if not activeWeapon then
        return
    end

    --------------------------------------------------
    -- UPDATE WEAPON
    --------------------------------------------------

    activeWeapon:Update(dt)

    --------------------------------------------------
    -- RELOAD
    --------------------------------------------------

    if game.Input.KeyPressed(game.Input.Key.R) then

        if activeWeapon:TryReload() then

            WeaponReload:FireServer()

        end

    end

    --------------------------------------------------
    -- SHOOT - EVENT DRIVEN
    --------------------------------------------------

    if leftClickRequested then

        -- Consume the request immediately.
        -- One InputBegan event = one shooting attempt.

        leftClickRequested = false

        print("[UZG] Registered click consumed!")

        FireWeapon()

    end

end

print("[UZG] Weapon Client initialized!")
