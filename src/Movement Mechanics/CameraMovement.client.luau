local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Modules = ReplicatedStorage:WaitForChild("Modules")

local CameraShakerModule = require(Modules:WaitForChild("CameraShaker"):WaitForChild("CameraShaker"))
local CameraShakeInstance = require(Modules:WaitForChild("CameraShaker"):WaitForChild("CameraShakeInstance"))

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
            print(CharacterVelocity.Magnitude / 10)
            local ShakeInstance = CameraShakeInstance.new(CharacterVelocity.Magnitude / 10, 2, 0.1, 0.1)
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