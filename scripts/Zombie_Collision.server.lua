
-- UZG - Zombie AI, Health and Combat
-- Version: Zombie Body v4 - Enlarged Combat Hitbox
-- Attach directly to Zombie_Collision Part.

--------------------------------------------------
-- CONFIGURATION
--------------------------------------------------

local MAX_HEALTH = 100

-- Physical movement collider
local COLLIDER_SIZE = Vector3.new(2, 3.2, 2)
local HIP_HEIGHT = 2.0

-- Enlarged combat hitbox
local HITBOX_NAME = "UZG_ZombieHitbox"
local HITBOX_SIZE = Vector3.new(13, 16, 13)

local HITBOX_COLLISION_GROUP = "UZG_ZombieHitbox"

-- Movement
local WALK_SPEED = 8
local MAX_SLOPE_ANGLE = 50
local REPATH_INTERVAL = 0.6

-- Combat
local ATTACK_DAMAGE = 15
local ATTACK_RANGE = 3.0
local ATTACK_INTERVAL = 1.5

-- Death
local DEATH_CLEANUP_DELAY = 0.35

local DEBUG_TEST_DAMAGE = false

--------------------------------------------------
-- PHYSICAL BODY
--------------------------------------------------

self.Size = COLLIDER_SIZE
self.Collider = "Capsule"

self.Transparency = 1
self.ShadowOff = true
self.Anchored = false

--------------------------------------------------
-- CHARACTER COMPONENTS
--------------------------------------------------

if not self:HasComponent("Character") then
    self:AddComponent("Character")
end

if not self:HasComponent("Health") then
    self:AddComponent("Health")
end

if not self:HasComponent("CharacterPhysics") then
    self:AddComponent("CharacterPhysics")
end

if not self:HasComponent("Locomotion") then
    self:AddComponent("Locomotion")
end

--------------------------------------------------
-- CHARACTER CONFIGURATION
--------------------------------------------------

self.MaxHealth = MAX_HEALTH
self.Health = MAX_HEALTH
self.Invulnerable = false

self.attr.UZG_Zombie = true

self.WalkSpeed = WALK_SPEED
self.MaxSlopeAngle = MAX_SLOPE_ANGLE
self.AutoRotate = true
self.HipHeight = HIP_HEIGHT

--------------------------------------------------
-- HITBOX COLLISION GROUP
--------------------------------------------------

pcall(function()
    game.Physics.RegisterCollisionGroup(
        HITBOX_COLLISION_GROUP
    )
end)

-- Prevent physical obstruction.
game.Physics.SetCollisionRule(
    HITBOX_COLLISION_GROUP,
    "Default",
    false
)

game.Physics.SetCollisionRule(
    HITBOX_COLLISION_GROUP,
    "Character",
    false
)

game.Physics.SetCollisionRule(
    HITBOX_COLLISION_GROUP,
    "CharacterNoCollide",
    false
)

game.Physics.SetCollisionRule(
    HITBOX_COLLISION_GROUP,
    HITBOX_COLLISION_GROUP,
    false
)

--------------------------------------------------
-- REMOVE PREVIOUS HITBOX
--------------------------------------------------

local oldHitbox = self:FindFirstChild(HITBOX_NAME)

if oldHitbox then
    oldHitbox:Destroy()
end

--------------------------------------------------
-- CREATE COMBAT HITBOX
--------------------------------------------------

local hitbox = Instance.new("Part")

hitbox.Name = HITBOX_NAME

-- Dimensions: 13 x 16 x 13
hitbox.Size = HITBOX_SIZE
hitbox.Collider = "Box"

-- Invisible to players
hitbox.Transparency = 1
hitbox.ShadowOff = true

hitbox.Anchored = false
hitbox.CollisionGroup = HITBOX_COLLISION_GROUP

-- Parent the hitbox to the zombie.
hitbox.Parent = self

--------------------------------------------------
-- POSITION HITBOX
--------------------------------------------------

local hitboxVerticalOffset =
    (HITBOX_SIZE.y * 0.5)
    - (COLLIDER_SIZE.y * 0.5)
    - HIP_HEIGHT

-- Position relative to the zombie.
hitbox.LocalPosition = Vector3.new(
    0,
    hitboxVerticalOffset,
    0
)

-- Weld the hitbox to the zombie.
-- Set its position BEFORE creating the weld.
hitbox.Other = self

--------------------------------------------------
-- HITBOX INITIALIZATION
--------------------------------------------------

print(
    "[UZG] Zombie hitbox initialized:",
    hitbox.Name,
    "Size:", hitbox.Size,
    "LocalPosition:", hitbox.LocalPosition
)

--------------------------------------------------
-- DEBUG DAMAGE TEST
--------------------------------------------------

if DEBUG_TEST_DAMAGE then

    self:TakeDamage(35)

    print(
        "[UZG] Damage test:",
        self.Health,
        "/",
        self.MaxHealth
    )

end

--------------------------------------------------
-- INITIALIZATION
--------------------------------------------------

print(
    "[UZG] Zombie Body v4 initialized:",
    self.Name,
    "Size:",
    self.Size,
    "Collider:",
    self.Collider,
    "HP:",
    self.Health,
    "/",
    self.MaxHealth
)

--------------------------------------------------
-- INTERNAL STATE
--------------------------------------------------

local elapsed = 0
local following = false
local attackCooldown = 0
local currentTarget = nil

local deathScheduled = false

--------------------------------------------------
-- MOVEMENT CONTROL
--------------------------------------------------

local function StopZombie()

    if following then
        game.Navigation.Stop(self)
        following = false
    end

    currentTarget = nil

end

--------------------------------------------------
-- FIND NEAREST PLAYER
--------------------------------------------------

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

--------------------------------------------------
-- ATTACK
--------------------------------------------------

local function AttackTarget(target)

    if attackCooldown > 0 then
        return
    end

    if not target or target.Health <= 0 then
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

--------------------------------------------------
-- DEATH
--------------------------------------------------

local function BeginDeath()

    if deathScheduled then
        return
    end

    deathScheduled = true

    StopZombie()

    local zombieName = self.Name

    print(
        "[UZG] Zombie death scheduled:",
        zombieName
    )

    -- Preserve final client-side hit feedback.

    task.delay(DEATH_CLEANUP_DELAY, function()

        if self:IsAlive() then

            self:Destroy()

            print(
                "[UZG] Zombie destroyed:",
                zombieName
            )

        end

    end)

end

--------------------------------------------------
-- MAIN UPDATE
--------------------------------------------------

function Update(dt: number)

    -- Dead zombies cannot move or attack.

    if self.Health <= 0 then

        BeginDeath()
        return

    end

    -- Update attack cooldown.

    attackCooldown = math.max(
        0,
        attackCooldown - dt
    )

    -- Recalculate target periodically.

    elapsed += dt

    if elapsed >= REPATH_INTERVAL then

        elapsed = 0

        currentTarget = GetNearestPlayer()

        if not currentTarget then

            StopZombie()

        else

            local distance =
                (currentTarget.Position - self.Position).Magnitude

            if distance > ATTACK_RANGE then

                game.Navigation.MoveTo(
                    self,
                    currentTarget.Position
                )

                following = true

            else

                if following then
                    game.Navigation.Stop(self)
                    following = false
                end

            end

        end
    end

    -- Attack check.

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

        StopZombie()

    end

end

print("[UZG] Zombie combat initialized!")
