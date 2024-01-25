
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local HitboxManager = require(ReplicatedStorage:WaitForChild("Modules").HitboxManager)


local RaycastHitbox = HitboxManager.new()
RaycastHitbox.CastMode = HitboxManager.CastModes.Raycast
RaycastHitbox.HitboxCastingMode = HitboxManager.HitboxCastingModes.Continuous
RaycastHitbox.HitboxMode = HitboxManager.HitboxModes.Cast
RaycastHitbox.RaycastInfo.origin = Vector3.new(0, 3, 0)
RaycastHitbox.RaycastInfo.direction = Vector3.new(0,0,20)
RaycastHitbox.Visualize = true

RaycastHitbox:Start()

RaycastHitbox.Hit:Connect(function(HitPart, Humanoid)
    print(HitPart)
    Humanoid:TakeDamage(5)

end)


--[[local TweenPart = Instance.new("Part")
TweenPart.Parent = workspace
TweenPart.Anchored = true

local Tween = TweenService:Create(TweenPart, TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut,-1,true),{CFrame = CFrame.new(Vector3.new(0, 5, 20)) * CFrame.Angles(0, math.rad(90), 0)})
Tween:Play()

local New_Hitbox = HitboxManager.new()
New_Hitbox.Shape = Enum.PartType.Ball
New_Hitbox.CFrame = TweenPart
New_Hitbox.Size = 5
New_Hitbox.DetectionMode = HitboxManager.DetectionModes.Continuous
New_Hitbox.Duration = math.huge
New_Hitbox.ContinuousDebounce = 0.5

New_Hitbox:Start()

New_Hitbox.Touched:Connect(function(HitPart, Humanoid)
    Humanoid:TakeDamage(5)
    print(HitPart, Humanoid)
end)

New_Hitbox.StateChanged:Connect(function(NewState, PreviousState)
    print("New: "..NewState, "Previous: ".. PreviousState)
end)

task.wait(10)

--local StoredData = New_Hitbox:Destroy()
--print(StoredData)]]