
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local HitboxManager = require(ReplicatedStorage:WaitForChild("Modules").HitboxManager)

local Hitbox = HitboxManager.new()
Hitbox.Shape = Enum.PartType.Block
Hitbox.CFrame = CFrame.new(Vector3.new(0, 17, 0)) * CFrame.Angles(0, math.rad(90), 0)
Hitbox.Size = Vector3.new(10, 10, 10)
Hitbox.DetectionMode = "Single"

Hitbox:Start_Hitboxing_BasePart()

Hitbox.Touched:Connect(function(HitPart, Humanoid)
    print(HitPart, Humanoid)
    Humanoid:TakeDamage(10)
end)

local TweenPart = Instance.new("Part")

task.wait(15)

TweenPart.Parent = workspace
TweenPart.Anchored = true
TweenPart.Position = Vector3.new(0, 5, 0)

local Tween = TweenService:Create(TweenPart, TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut,-1,true),{CFrame = CFrame.new(Vector3.new(0, 5, 20)) * CFrame.Angles(0, math.rad(90), 0)})
Tween:Play()

local New_Hitbox = HitboxManager.new()
New_Hitbox.Shape = Enum.PartType.Block
New_Hitbox.CFrame = TweenPart
New_Hitbox.Size = Vector3.new(10, 10, 10)
New_Hitbox.DetectionMode = "Constant"
New_Hitbox.Duration = math.huge

New_Hitbox:Start_Hitboxing_BasePart()

New_Hitbox.Touched:Connect(function(HitPart, Humanoid)
    Humanoid:TakeDamage(1)
end)