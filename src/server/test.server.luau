
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local HitboxManager = require(ReplicatedStorage:WaitForChild("Modules").HitboxManager)



local TweenPart = Instance.new("Part")
TweenPart.Parent = workspace
TweenPart.Anchored = true
TweenPart.CFrame = CFrame.new(0,5,10)

local Tween = TweenService:Create(TweenPart, TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut,-1,true),{CFrame = CFrame.new(Vector3.new(0, 5, 30)) * CFrame.Angles(0, math.rad(90), 0)})
Tween:Play()

local New_Hitbox = HitboxManager.new()
New_Hitbox.Shape = Enum.PartType.Ball
New_Hitbox.CFrame = TweenPart
New_Hitbox.Size = 5
New_Hitbox.DetectionMode = HitboxManager.DetectionModes.Continuous
New_Hitbox.Duration = math.huge
New_Hitbox.ContinuousDebounce = 0.5
New_Hitbox.Visualize = true
New_Hitbox.HitboxMode = HitboxManager.HitboxModes.Range

New_Hitbox:Start()

New_Hitbox.Touched:Connect(function(HitPart, Humanoid)
    Humanoid:TakeDamage(5)
    print(HitPart, Humanoid)
end)


--task.wait(10)

--local StoredData = New_Hitbox:Destroy()
--print(StoredData)

local RaycastHitbox = HitboxManager.new()
RaycastHitbox.CastMode = HitboxManager.CastModes.Spherecast
RaycastHitbox.HitboxCastingMode = HitboxManager.HitboxCastingModes.Continuous
RaycastHitbox.HitboxMode = HitboxManager.HitboxModes.Cast

RunService.Heartbeat:Connect(function()
    RaycastHitbox.SpherecastInfo.position = workspace.Part.Position
    RaycastHitbox.SpherecastInfo.direction = workspace.Part.CFrame.LookVector * 5
    RaycastHitbox.SpherecastInfo.radius = 2
end)

RaycastHitbox.StateChanged:Connect(function(NewState, PreviousState)
    print("New: "..NewState, "Previous: ".. PreviousState)
end)

RaycastHitbox.Visualize = true

RaycastHitbox:Start()

RaycastHitbox.Hit:Connect(function(HitPart, Humanoid)
    print(HitPart)
    Humanoid:TakeDamage(5)
    New_Hitbox:Destroy()
    RaycastHitbox:Destroy()
end)