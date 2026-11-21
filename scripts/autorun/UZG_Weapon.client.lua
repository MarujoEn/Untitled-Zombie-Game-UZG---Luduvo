
-- UZG - Weapon Client

-- Load modules
local WeaponController =
    require("./systems/WeaponController")

local OlympiaConfig =
    require("../weapons/olympia")

print("[UZG] Weapon modules loaded!")

local activeWeapon = nil

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
        activeWeapon:TryReload()
    end

    -- Shoot
    if game.Input.ButtonPressed(game.Input.Button.Left) then
        activeWeapon:TryShoot()
    end
end
