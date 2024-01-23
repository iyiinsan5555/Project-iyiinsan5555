
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HitboxManager = require(ReplicatedStorage:WaitForChild("Modules").HitboxManager)
task.wait(2)
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
