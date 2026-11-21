
-- UZG - First Person Camera Lock
-- Script: scripts/autorun/UZG_Player.client.lua

local CAMERA_DISTANCE = 0.35

function Update(dt: number)

    local camera = game.World.Camera

    if not camera then
        return
    end

    local cameraOrbit = camera.CameraOrbit

    if not cameraOrbit then
        return
    end

    -- Keep the camera in first-person mode.
    if cameraOrbit.distance ~= CAMERA_DISTANCE then
        cameraOrbit.distance = CAMERA_DISTANCE
    end

end

print("[UZG] First-person camera lock initialized!")
