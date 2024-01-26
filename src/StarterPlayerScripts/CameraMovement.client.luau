local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerService = game:GetService("Players")

local Modules = ReplicatedStorage:WaitForChild("Modules")

local CameraMovementModule = require(Modules:WaitForChild("CameraMovementModule"))
local CameraShakerModule = require(Modules:WaitForChild("CameraShaker"):WaitForChild("CameraShaker"))
--local CameraShakePresets = require(Modules:WaitForChild("CameraShaker"):WaitForChild("CameraShakePresets"))

local Player = PlayerService.LocalPlayer
local Camera = workspace:WaitForChild("Camera")

local CameraMovement = CameraMovementModule.new(Player, Camera)

CameraMovement:Start()

CameraMovement.LerpAmount = 0.25
CameraMovement.MovingMultiplier = 1

--[[task.wait(5)

local CameraShaker = CameraShakerModule.new(Enum.RenderPriority.Camera.Value + 1, function(ShakeCFrame)
    Camera.CFrame = Camera.CFrame * ShakeCFrame
end)

CameraShaker:Start()

task.spawn(function()
    while task.wait(3) do
        CameraShaker:Shake(CameraShakePresets.FastFlying)
    end
end)]]