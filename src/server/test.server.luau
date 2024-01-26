
--[[local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local HitboxManager = require(ReplicatedStorage:WaitForChild("Modules").HitboxManager)


task.wait(5)

local Hitbox = HitboxManager.new()
Hitbox.HitboxMode = HitboxManager.HitboxModes.Cast
Hitbox.CastMode = HitboxManager.CastModes.Spherecast
Hitbox.HitboxCastingMode = HitboxManager.HitboxCastingModes.HitEveryPlayerOnRay
Hitbox.SpherecastInfo.direction = Vector3.new(0, 20,0)
Hitbox.SpherecastInfo.radius = 5

Hitbox.Visualize = true

Hitbox.StateChanged:Connect(function(New, Old)
    print(New, Old)
end)

Hitbox.Hit:Connect(function(HitPart, Humanoid)
    print(HitPart.Name.." has been hit")

    Humanoid:TakeDamage(95)
end)


Hitbox:Start()

]]