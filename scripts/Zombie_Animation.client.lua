
-- UZG - World Scale Sprite Animation

local FRAME_DURATION = 0.18

-- Dimensions based on the zombie collider
local SPRITE_WIDTH = 12
local SPRITE_HEIGHT = 16

local SPRITE_FRAMES = {
    "sprites/Zombie/Zombie_01.png",
    "sprites/Zombie/Zombie_02.png",
    "sprites/Zombie/Zombie_03.png"
}

-- Create billboard
local billboard = Instance.new("BillboardGui")
billboard.Name = "ZombieBillboard"
billboard.Parent = self

-- Create sprite
local sprite = Instance.new("ImageLabel")
sprite.Name = "ZombieSprite"
sprite.Size = UDim2.new(1, 0, 1, 0)
sprite.BackgroundTransparency = 1
sprite.ResampleMode = "Pixelated"
sprite.ScaleType = "Fit"
sprite.Image = SPRITE_FRAMES[1]
sprite.Parent = billboard

-- Animation state
local currentFrame = 1
local animationTimer = 0

-- Update sprite scale and animation
function Update(dt: number)

    -- Get camera references
    local camera = game.World.Camera
    local screen = game.World.Screen

    if not camera or not screen then
        return
    end

    -- Calculate distance from camera to zombie
    local distance = (camera.Position - self.Position).Magnitude
    distance = math.max(distance, 0.1)

    -- Calculate screen scale
    local viewportHeight = screen.AbsoluteSize.Y
    local fov = camera.CameraLens.fovY

    local pixelsPerUnit =
        viewportHeight / (2 * distance * math.tan(fov / 2))

    -- Resize billboard to match collider proportions
    billboard.BillboardGui.height = SPRITE_HEIGHT * pixelsPerUnit
    billboard.BillboardGui.width = SPRITE_WIDTH * pixelsPerUnit

    -- Animate sprite
    animationTimer += dt

    if animationTimer >= FRAME_DURATION then
        animationTimer -= FRAME_DURATION

        currentFrame += 1

        if currentFrame > #SPRITE_FRAMES then
            currentFrame = 1
        end

        sprite.Image = SPRITE_FRAMES[currentFrame]
    end
end

print("[UZG] World-scale zombie sprite initialized!")
