local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PlayerService = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")

local Modules = ReplicatedStorage:WaitForChild("Modules")

local CameraShakerModule = require(Modules:WaitForChild("CameraShaker"):WaitForChild("CameraShaker"))
local CameraShakeInstance = require(Modules:WaitForChild("CameraShaker"):WaitForChild("CameraShakeInstance"))
local LockSystemModule = require(Modules:WaitForChild("LockSystem"))

local Player = PlayerService.LocalPlayer
local Camera = workspace:WaitForChild("Camera")
local Character = script.Parent.Parent
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

local LastShakeTime = 0

local CameraShaker = CameraShakerModule.new(Enum.RenderPriority.Camera.Value + 1, function(ShakeCFrame)
    Camera.CFrame = Camera.CFrame * ShakeCFrame
end)

CameraShaker:Start()

RunService.Heartbeat:Connect(function()

    if LastShakeTime + 0.1 < tick() then

        local CharacterVelocity = HumanoidRootPart.AssemblyLinearVelocity

        LastShakeTime = tick()

        if Humanoid.MoveDirection.Magnitude > 0 then

            local ShakeInstance = CameraShakeInstance.new(CharacterVelocity.Magnitude / 15, 2, 0.1, 0.1)
            ShakeInstance.RotationInfluence = Vector3.new(0, 0, 0.5)

            CameraShaker:Shake(ShakeInstance)

        else

            local t = tick()
            local sinOffset = Vector3.new(math.sin(t * 2) * 0.1, math.sin(t * 2.5) * 0.1, math.sin(t * 3) * 0.1)
            local Multiplier = 1
            local LerpAmount = 0.2

            Humanoid.CameraOffset = Humanoid.CameraOffset:Lerp((Humanoid.MoveDirection * 0.3 * Multiplier ) + sinOffset, LerpAmount)

        end

    end
end)

local LockSystem = LockSystemModule.new(Player, Camera)

LockSystem.Range = 300

LockSystem.TargetChanged:Connect(function(NewTarget, OldTarget)
    print("Target Changed", NewTarget, OldTarget)
end)

ContextActionService:BindAction("LockCamera", function(_, InputState, _)
    if not (InputState == Enum.UserInputState.Begin) then
        return
    end
    if LockSystem.Locked == false then
        LockSystem:Start()
    else
        LockSystem:Stop()
    end
end, true, Enum.KeyCode.L)
