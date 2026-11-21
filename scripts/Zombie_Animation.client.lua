-- UZG - World Scale Zombie Animation
-- Version: Zombie Body v3

--------------------------------------------------
-- CONFIGURATION
--------------------------------------------------

local FRAME_DURATION = 0.18

-- Physical zombie body dimensions
local COLLIDER_HEIGHT = 3.2
local HIP_HEIGHT = 2.0

-- Visual sprite dimensions
local SPRITE_WORLD_WIDTH = 9.6
local SPRITE_WORLD_HEIGHT = 12.8

-- Animation settings
local MOVEMENT_THRESHOLD = 0.45

-- Rendering settings
local MIN_VIEW_DISTANCE = 1.5
local MAX_SCREEN_HEIGHT_FACTOR = 1.4

local SPRITE_FRAMES = {
    "sprites/Zombie/Zombie_01.png",
    "sprites/Zombie/Zombie_02.png",
    "sprites/Zombie/Zombie_03.png"
}

--------------------------------------------------
-- CREATE BILLBOARD
--------------------------------------------------

local billboard = Instance.new("BillboardGui")

billboard.Name = "ZombieBillboard"
billboard.Parent = self

local billboardSettings = billboard.BillboardGui

-- Position the billboard so the sprite's bottom
-- aligns approximately with the physical ground.
local verticalOffset =
    (SPRITE_WORLD_HEIGHT * 0.5)
    - (COLLIDER_HEIGHT * 0.5)
    - HIP_HEIGHT

billboardSettings.unitsOffset = Vector3.new(
    0,
    verticalOffset,
    0
)

billboardSettings.alwaysOnTop = false

-- Initial dimensions
billboardSettings.width = 1
billboardSettings.height = 1

--------------------------------------------------
-- CREATE SPRITE
--------------------------------------------------

local sprite = Instance.new("ImageLabel")

sprite.Name = "ZombieSprite"

sprite.AnchorPoint = Vector2.new(0.5, 1)
sprite.Position = UDim2.new(0.5, 0, 1, 0)
sprite.Size = UDim2.new(1, 0, 1, 0)

sprite.BackgroundTransparency = 1
sprite.ResampleMode = "Pixelated"
sprite.ScaleType = "Fit"

sprite.Image = SPRITE_FRAMES[1]

sprite.Parent = billboard

--------------------------------------------------
-- ANIMATION STATE
--------------------------------------------------

local currentFrame = 1
local animationTimer = 0

local previousPosition = self.Position

--------------------------------------------------
-- UPDATE BILLBOARD SIZE
--------------------------------------------------

local function UpdateBillboardSize()

    local camera = game.World.Camera
    local screen = game.World.Screen

    if not camera or not screen then
        return
    end

    local viewportHeight = screen.AbsoluteSize.y
    local fov = camera.CameraLens.fovY

    if viewportHeight <= 0 or fov <= 0 then
        return
    end

    -- Calculate camera-to-zombie distance
    local distance = (
        camera.Position - self.Position
    ).Magnitude

    distance = math.max(
        distance,
        MIN_VIEW_DISTANCE
    )

    -- Convert world dimensions into screen points
    local pixelsPerUnit =
        viewportHeight /
        (2 * distance * math.tan(fov * 0.5))

    local projectedHeight =
        SPRITE_WORLD_HEIGHT * pixelsPerUnit

    -- Prevent extreme sizes at very close distances
    projectedHeight = math.min(
        projectedHeight,
        viewportHeight * MAX_SCREEN_HEIGHT_FACTOR
    )

    projectedHeight = math.max(
        projectedHeight,
        1
    )

    local projectedWidth =
        projectedHeight *
        (SPRITE_WORLD_WIDTH / SPRITE_WORLD_HEIGHT)

    billboardSettings.height = projectedHeight
    billboardSettings.width = projectedWidth

end

--------------------------------------------------
-- UPDATE WALK ANIMATION
--------------------------------------------------

local function UpdateAnimation(dt)

    local currentPosition = self.Position

    local movementSpeed = 0

    if dt > 0 then

        movementSpeed =
            (currentPosition - previousPosition).Magnitude / dt

    end

    previousPosition = currentPosition

    local isMoving =
        movementSpeed > MOVEMENT_THRESHOLD

    if not isMoving then

        animationTimer = 0

        if currentFrame ~= 1 then

            currentFrame = 1
            sprite.Image = SPRITE_FRAMES[1]

        end

        return
    end

    -- Animate only while moving
    animationTimer += dt

    while animationTimer >= FRAME_DURATION do

        animationTimer -= FRAME_DURATION

        currentFrame += 1

        if currentFrame > #SPRITE_FRAMES then
            currentFrame = 1
        end

        sprite.Image = SPRITE_FRAMES[currentFrame]

    end

end

--------------------------------------------------
-- MAIN UPDATE
--------------------------------------------------

function Update(dt: number)

    if not self:IsAlive() then
        return
    end

    UpdateBillboardSize()
    UpdateAnimation(dt)

end

--------------------------------------------------
-- INITIALIZATION
--------------------------------------------------

print("[UZG] Zombie Body v3 animation initialized!")