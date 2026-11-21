
-- UZG - Player Health System
-- Script: scripts/autorun/UZG_PlayerHealth.server.lua

-- Configuration
local PLAYER_MAX_HEALTH = 100

-- Optional health test
local DEBUG_TEST_DAMAGE = false

print("[UZG] Player Health System initialized!")

-- Configure each player's character.
local function InitializePlayerHealth(player, character)

    -- Set maximum and current health.
    character.MaxHealth = PLAYER_MAX_HEALTH
    character.Health = PLAYER_MAX_HEALTH

    -- Allow the character to receive damage.
    character.Invulnerable = false

    print(
        "[UZG] Player initialized:",
        player.Name,
        "HP:",
        character.Health,
        "/",
        character.MaxHealth
    )

    -- Optional damage test.
    if DEBUG_TEST_DAMAGE then

        character:TakeDamage(35)

        print(
            "[UZG] Player damage test:",
            character.Health,
            "/",
            character.MaxHealth
        )

    end
end

-- Listen for every new player character,
-- including characters created after respawning.
game.Players.CharacterAdded:Connect(InitializePlayerHealth)
