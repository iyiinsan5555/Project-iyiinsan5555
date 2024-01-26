local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Modules = ReplicatedStorage:WaitForChild("Modules")

local GoodSignal = require(Modules:WaitForChild("GoodSignal"))


local VelocityCalculator = {}
VelocityCalculator.__index = VelocityCalculator


function VelocityCalculator.new()
    local self = setmetatable({}, VelocityCalculator)

    self.ForcedVelocity = true -- It starts slow and gets faster to catch actual speed

    self.Velocity = Vector3.new(0, 0, 0)
    --self.AvarageSpeed = 10
    self.MaxSpeed = 15

    self.Vector3Value = Instance.new("Vector3Value")
    self.TweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, false, 0)

    self.Changed = GoodSignal.new()
    self.SpeedChanged = GoodSignal.new()

    self.Connections = {}

    self.Vector3Value.Changed:Connect(function(Value)
        self.Velocity = Value
    end)

    return self
end


function VelocityCalculator:GetVelocity()
    return self.Vector3Value.Value
end


function VelocityCalculator:CalculateSpeed(Velocity)
    return Velocity.Magnitude
end


function VelocityCalculator:CalculateSpeedDifference(Velocity1 :Vector3, Velocity2 :Vector3)
    local Difference = Velocity1 - Velocity2

    return Difference.Magnitude
end


function VelocityCalculator:SetVelocity(Velocity :Vector3)
    self.Vector3Value.Value = Velocity
end

function VelocityCalculator:SetVelocityWithTween(TargetVelocity :Vector3)

    local Speed = self:CalculateSpeed(TargetVelocity)

    if Speed > self.MaxSpeed then
        local Direction = TargetVelocity.Unit
        TargetVelocity = Direction * self.MaxSpeed
    end

    local Tween = TweenService:Create(self.Vector3Value, self.TweenInfo, {Value = TargetVelocity})

    local PreviousVeloicity = self.Vector3Value.Value

    if (PreviousVeloicity - TargetVelocity).Magnitude > self.TweenInfo.Time then
        task.delay(self.TweenInfo.Time, function()
            self.Changed:Fire(TargetVelocity, PreviousVeloicity)
        end)
    end

    Tween:Play()

end


function VelocityCalculator:IncreaseVelocity(Amount :Vector3)

    local TargetVelocity = self.Vector3Value.Value + Amount

    self:SetVelocityWithTween(TargetVelocity)

end


function VelocityCalculator:DecreaseVelocity(Amount :Vector3)

    local TargetVelocity = self.Vector3Value.Value - Amount

    self:SetVelocityWithTween(TargetVelocity)

end



return VelocityCalculator