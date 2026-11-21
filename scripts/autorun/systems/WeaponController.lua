
-- UZG - Generic Weapon Controller

local WeaponController = {}
WeaponController.__index = WeaponController

--------------------------------------------------
-- CREATE WEAPON
--------------------------------------------------

function WeaponController.new(configuration, overlay)

    local self = setmetatable({}, WeaponController)

    -- Store configuration
    self.Config = configuration

    -- Initial weapon state
    self.Ammo = configuration.MaxAmmo
    self.State = "Idle"

    self.StateTimer = 0
    self.FireCooldown = 0

    --------------------------------------------------
    -- WEAPON INTERFACE
    --------------------------------------------------

    local screen = Instance.new("ScreenGui")

    screen.Name = configuration.Id .. "Screen"
    screen.Parent = overlay

    --------------------------------------------------
    -- WEAPON SPRITE
    --------------------------------------------------

    local sprite = Instance.new("ImageLabel")

    sprite.Name = configuration.Id .. "Sprite"

    sprite.Size = configuration.Screen.Size
    sprite.Position = configuration.Screen.Position

    sprite.BackgroundTransparency = 1
    sprite.ResampleMode = "Pixelated"
    sprite.ScaleType = "Fit"

    sprite.ZIndex = 1

    sprite.Image = configuration.Sprites.Idle
    sprite.Parent = screen

    

    --------------------------------------------------
    -- CROSSHAIR - INPUT ISOLATED
    --------------------------------------------------

    local crosshair = Instance.new("Frame")

    crosshair.Name = "UZG_Crosshair"

    crosshair.Size = UDim2.new(0, 24, 0, 24)

    crosshair.Position = UDim2.new(
        0.5, 0,
        0.5, 0
    )

    crosshair.AnchorPoint = Vector2.new(0.5, 0.5)

    crosshair.BackgroundTransparency = 1
    crosshair.BorderSizePixel = 0
    crosshair.ZIndex = 10

    -- Explicitly prevent pointer interaction.
    crosshair.UIClickable = false

    -- Disable input for the entire crosshair hierarchy.
    crosshair.Disabled = true

    --------------------------------------------------
    -- VERTICAL LINE
    --------------------------------------------------

    local verticalLine = Instance.new("Frame")

    verticalLine.Name = "CrosshairVertical"

    verticalLine.Size = UDim2.new(0, 2, 0, 14)

    verticalLine.Position = UDim2.new(
        0.5, 0,
        0.5, 0
    )

    verticalLine.AnchorPoint = Vector2.new(0.5, 0.5)

    verticalLine.BackgroundColor3 = Vector3.new(1, 1, 1)
    verticalLine.BackgroundTransparency = 0
    verticalLine.BorderSizePixel = 0
    verticalLine.ZIndex = 10

    verticalLine.UIClickable = false
    verticalLine.Parent = crosshair

    --------------------------------------------------
    -- HORIZONTAL LINE
    --------------------------------------------------

    local horizontalLine = Instance.new("Frame")

    horizontalLine.Name = "CrosshairHorizontal"

    horizontalLine.Size = UDim2.new(0, 14, 0, 2)

    horizontalLine.Position = UDim2.new(
        0.5, 0,
        0.5, 0
    )

    horizontalLine.AnchorPoint = Vector2.new(0.5, 0.5)

    horizontalLine.BackgroundColor3 = Vector3.new(1, 1, 1)
    horizontalLine.BackgroundTransparency = 0
    horizontalLine.BorderSizePixel = 0
    horizontalLine.ZIndex = 10

    horizontalLine.UIClickable = false
    horizontalLine.Parent = crosshair

    --------------------------------------------------
    -- DISPLAY CROSSHAIR
    --------------------------------------------------

    crosshair.Parent = screen

    self.Crosshair = crosshair

    print(
        "[UZG] Crosshair initialized:",
        "UIClickable:", crosshair.UIClickable,
        "Disabled:", crosshair.Disabled
    )


    self.Crosshair = crosshair

    print(
        "[UZG] Crosshair initialized:",
        "UIClickable:",
        crosshair:HasComponent("UIClickable")
    )


    --------------------------------------------------
    -- STORE REFERENCES
    --------------------------------------------------

    self.Screen = screen
    self.Sprite = sprite
    self.Crosshair = crosshair

    print("[UZG] Weapon created:", configuration.DisplayName)

    return self
end

--------------------------------------------------
-- CHANGE WEAPON ANIMATION
--------------------------------------------------

function WeaponController:SetAnimation(animation)

    local image = self.Config.Sprites[animation]

    if image then
        self.Sprite.Image = image
        self.State = animation
    end

end

--------------------------------------------------
-- SHOOT
--------------------------------------------------

function WeaponController:TryShoot()

    if self.State ~= "Idle" then
        return false
    end

    if self.FireCooldown > 0 then
        return false
    end

    if self.Ammo <= 0 then
        print("[UZG] Empty! Press R to reload.")
        return false
    end

    self.Ammo -= 1

    self.FireCooldown = self.Config.FireInterval
    self.StateTimer = self.Config.ShootAnimationDuration

    self:SetAnimation("Shoot")

    print(
        "[UZG] Shot fired!",
        self.Ammo,
        "/",
        self.Config.MaxAmmo
    )

    return true
end

--------------------------------------------------
-- RELOAD
--------------------------------------------------

function WeaponController:TryReload()

    if self.State ~= "Idle" then
        return false
    end

    if self.Ammo >= self.Config.MaxAmmo then
        return false
    end

    self.StateTimer = self.Config.ReloadDuration

    self:SetAnimation("Reload")

    print("[UZG] Reloading:", self.Config.DisplayName)

    return true
end

--------------------------------------------------
-- UPDATE
--------------------------------------------------

function WeaponController:Update(dt)

    -- Update fire cooldown
    self.FireCooldown = math.max(
        0,
        self.FireCooldown - dt
    )

    -- No active animation
    if self.State == "Idle" then
        return
    end

    self.StateTimer -= dt

    if self.StateTimer <= 0 then

        -- Complete reload
        if self.State == "Reload" then

            self.Ammo = self.Config.MaxAmmo

            print(
                "[UZG] Reload complete!",
                self.Ammo,
                "/",
                self.Config.MaxAmmo
            )

        end

        self:SetAnimation("Idle")

    end

end

return WeaponController
