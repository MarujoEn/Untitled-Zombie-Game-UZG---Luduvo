
-- UZG - Zombie AI, Health and Combat
-- Script: Zombie_Collision.server.lua
-- Attach directly to the Zombie_Collision Part.

-- Configuration
local MAX_HEALTH = 100

local WALK_SPEED = 8
local REPATH_INTERVAL = 0.6

-- Combat
local ATTACK_DAMAGE = 15
local ATTACK_RANGE = 5
local ATTACK_INTERVAL = 1.5

-- Optional health test
local DEBUG_TEST_DAMAGE = false

-- Invisible collision box; physics remain enabled.
self.Transparency = 1
self.ShadowOff = true

-- Prepare the zombie as a character.
if not self:HasComponent("Character") then
    self:AddComponent("Character")
end

-- Add health system.
if not self:HasComponent("Health") then
    self:AddComponent("Health")
end

-- Initialize health.
self.MaxHealth = MAX_HEALTH
self.Health = MAX_HEALTH
self.Invulnerable = false

-- Optional damage test.
if DEBUG_TEST_DAMAGE then
    self:TakeDamage(35)

    print("[UZG] Damage test:", self.Health, "/", self.MaxHealth)
end

-- Prepare physics and movement.
self.Anchored = false

if not self:HasComponent("CharacterPhysics") then
    self:AddComponent("CharacterPhysics")
end

if not self:HasComponent("Locomotion") then
    self:AddComponent("Locomotion")
end

self.WalkSpeed = WALK_SPEED
self.AutoRotate = true

print(
    "[UZG] Zombie initialized:",
    self.Name,
    "HP:",
    self.Health,
    "/",
    self.MaxHealth
)

-- Internal variables.
local elapsed = 0
local following = false

local attackCooldown = 0
local currentTarget = nil

-- Find the nearest living player.
local function GetNearestPlayer()

    local nearestCharacter = nil
    local nearestDistance = math.huge

    for player in game.World:Each("Player") do

        local character = player.Character

        if character and character.Health > 0 then

            local distance =
                (character.Position - self.Position).Magnitude

            if distance < nearestDistance then
                nearestDistance = distance
                nearestCharacter = character
            end

        end
    end

    return nearestCharacter, nearestDistance
end

-- Attack the current player target.
local function AttackTarget(target)

    if attackCooldown > 0 then
        return
    end

    target:TakeDamage(ATTACK_DAMAGE, self)

    attackCooldown = ATTACK_INTERVAL

    print(
        "[UZG] Zombie attacked:",
        target.Name,
        "Player HP:",
        target.Health,
        "/",
        target.MaxHealth
    )
end

-- Main server update.
function Update(dt: number)

    -- Dead zombies cannot move or attack.
    if self.Health <= 0 then

        if following then
            game.Navigation.Stop(self)
            following = false
        end

        currentTarget = nil
        return
    end

    -- Update attack cooldown.
    attackCooldown = math.max(0, attackCooldown - dt)

    -- Recalculate target periodically.
    elapsed += dt

    if elapsed >= REPATH_INTERVAL then

        elapsed = 0

        currentTarget = GetNearestPlayer()

        -- No living players found.
        if not currentTarget then

            if following then
                game.Navigation.Stop(self)
                following = false
            end

        else

            local distance =
                (currentTarget.Position - self.Position).Magnitude

            -- Chase the target if outside attack range.
            if distance > ATTACK_RANGE then

                game.Navigation.MoveTo(
                    self,
                    currentTarget.Position
                )

                following = true

            else

                -- Stop when close enough to attack.
                if following then
                    game.Navigation.Stop(self)
                    following = false
                end

            end
        end
    end

    -- Check attack range every update.
    if currentTarget and currentTarget.Health > 0 then

        local distance =
            (currentTarget.Position - self.Position).Magnitude

        if distance <= ATTACK_RANGE then

            if following then
                game.Navigation.Stop(self)
                following = false
            end

            AttackTarget(currentTarget)
        end

    else

        -- Forget dead or invalid targets.
        if following then
            game.Navigation.Stop(self)
            following = false
        end

        currentTarget = nil
    end
end

print("[UZG] Zombie combat initialized!")
