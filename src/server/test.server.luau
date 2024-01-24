
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local HitboxManager = require(ReplicatedStorage:WaitForChild("Modules").HitboxManager)

local TweenPart = Instance.new("Part")

local Tween = TweenService:Create(TweenPart, TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut,-1,true),{CFrame = CFrame.new(Vector3.new(0, 5, 20)) * CFrame.Angles(0, math.rad(90), 0)})
Tween:Play()

local New_Hitbox = HitboxManager.new()
New_Hitbox.Shape = Enum.PartType.Block
New_Hitbox.CFrame = TweenPart
New_Hitbox.Size = Vector3.new(10, 10, 10)
New_Hitbox.DetectionMode = HitboxManager.DetectionModes.Continuous
New_Hitbox.Duration = math.huge

New_Hitbox:Start()

New_Hitbox.Touched:Connect(function(_, Humanoid)
    Humanoid:TakeDamage(1)
end)

New_Hitbox.StateChanged:Connect(function(NewState, PreviousState)
    print("New:"..NewState, "Previous".. PreviousState)
end)

task.wait(10)

local StoredData = New_Hitbox:Destroy()
print(StoredData)