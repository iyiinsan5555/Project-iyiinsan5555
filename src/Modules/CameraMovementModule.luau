local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")

local CameraShakerModule = require(Modules:WaitForChild("CameraShaker"):WaitForChild("CameraShaker"))
local CameraShakePresets = require(Modules:WaitForChild("CameraShaker"):WaitForChild("CameraShakePresets"))

local LastShakeTime = 0

local CameraMovement = {}
CameraMovement.__index = CameraMovement


function CameraMovement.new(Player :Player, Camera :Camera)
    local self = setmetatable({}, CameraMovement)

    self.MovingMultiplier = 1.5

    self.Connections = {}
    self.LerpAmount = 0.25

    self.Player = Player
    self.Character = Player.Character or Player.CharacterAdded:Wait()

    self.CameraShaker = CameraShakerModule.new(Enum.RenderPriority.Camera.Value + 1, function(ShakeCFrame)
        Camera.CFrame = Camera.CFrame * ShakeCFrame
    end)

    return self
end


function CameraMovement:Start()
    self.CameraShaker:Start()

    self.Connections["BindToRenderStep"] = RunService:BindToRenderStep("CameraMovement", Enum.RenderPriority.Camera.Value + 1, function()

        if not self.Player.Character then
            return
        end

        if LastShakeTime + 0.5 < tick() then
            LastShakeTime = tick()
            self.CameraShaker:Shake(CameraShakePresets.Running)
        end

        local Player = self.Player

        self.Character = Player.Character

        local Humanoid = self.Character:FindFirstChild("Humanoid")

        if not Humanoid then
            return
        end

        local t = tick()
        local sinOffset = Vector3.new(math.sin(t * 2) * 0.1, math.sin(t * 2.5) * 0.1, math.sin(t * 3) * 0.1)
        local Multiplier = self.MovingMultiplier

        if Humanoid.MoveDirection.Magnitude > 0 then
            sinOffset = Vector3.new(math.sin(t * 2.5) * 0.25 * Multiplier, math.sin(t * 2.5) * 0.2 * Multiplier, math.sin(t * 2) * 0.25 * Multiplier)
        end

        Humanoid.CameraOffset = Humanoid.CameraOffset:Lerp((Humanoid.MoveDirection * 0.3 * Multiplier ) + sinOffset, self.LerpAmount)

    end)
end


function CameraMovement:Destroy()

    for _, Connection in pairs(self.Connections) do
        Connection:Disconnect()
        Connection = nil
    end

    setmetatable(self, nil)

end



return CameraMovement