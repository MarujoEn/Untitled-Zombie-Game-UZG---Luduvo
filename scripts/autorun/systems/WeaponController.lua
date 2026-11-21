
-- UZG - Generic Weapon Controller

local WeaponController = {}
WeaponController.__index = WeaponController

-- Create a new weapon instance
function WeaponController.new(configuration, overlay)

    local self = setmetatable({}, WeaponController)

    -- Store configuration
    self.Config = configuration

    -- Initial weapon state
    self.Ammo = configuration.MaxAmmo
    self.State = "Idle"

    self.StateTimer = 0
    self.FireCooldown = 0

    -- Create the weapon interface
    local screen = Instance.new("ScreenGui")
    screen.Name = configuration.Id .. "Screen"
    screen.Parent = overlay

    local sprite = Instance.new("ImageLabel")
    sprite.Name = configuration.Id .. "Sprite"

    sprite.Size = configuration.Screen.Size
    sprite.Position = configuration.Screen.Position

    sprite.BackgroundTransparency = 1
    sprite.ResampleMode = "Pixelated"
    sprite.ScaleType = "Fit"

    sprite.Image = configuration.Sprites.Idle
    sprite.Parent = screen

    self.Screen = screen
    self.Sprite = sprite

    print("[UZG] Weapon created:", configuration.DisplayName)

    return self
end

-- Change the displayed weapon animation
function WeaponController:SetAnimation(animation)

    local image = self.Config.Sprites[animation]

    if image then
        self.Sprite.Image = image
        self.State = animation
    end
end

-- Attempt to fire the weapon
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

-- Attempt to reload the weapon
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

-- Update weapon timers and animations
function WeaponController:Update(dt)

    -- Update fire cooldown
    self.FireCooldown = math.max(
        0,
        self.FireCooldown - dt
    )

    -- No active animation to update
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
