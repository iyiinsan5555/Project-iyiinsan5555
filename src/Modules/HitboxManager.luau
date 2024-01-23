--Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--Modules 
local GoodSignal = require(ReplicatedStorage.Modules.GoodSignal)

local HitboxManager = {}
HitboxManager.__index = HitboxManager

function HitboxManager.new()
    local self = setmetatable({}, HitboxManager)

    self.HitboxMode = "BasePart" -- BasePart, Raycast(Could be spherecast, spahecast or blockcast etc.)

    self.DetectionMode = "Multi" -- Multi (Can hit several humanoids and get deleted after the duration), Single (Can hit only one humanoid and get deleted after the first hit)
    self.Visualizer = true  -- Doesn't suggest in-game
    self.AutoDestroy = true -- Think about it
    self.HitList = {}
    self.TouchingParts = {}
    self.Connections = {}
    
    self.Touched = GoodSignal.new()
    self.ToucheEnded = GoodSignal.new()

    self.OverlapParams = OverlapParams.new()

    self.Size = Vector3.new(1, 1, 1) or 1
    self.Position = Vector3.new(0, 0, 0)
    self.CFrame = CFrame.new(0, 0, 0)
    self.Position = Vector3.new(0, 0, 0)

    self.Duration = 1

    self.Shape = Enum.PartType.Block --Or you can use Enum.PartType.Ball


    return self
end

local Get_CFrame = {
    ["Instance"] = function(Instance)
        return Instance.CFrame
    end,
    ["CFrame"] = function(cframe)
        return cframe
    end
}

local ShapeName = {
    [Enum.PartType.Block] = "Block",
    [Enum.PartType.Ball] = "Ball",
}

local BasePart_Hitbox = {
    
    [Enum.PartType.Block] = function(self)

        local Goal_CFrame = Get_CFrame[typeof(self.CFrame)](self.CFrame)

        local BoundingParts = workspace:GetPartBoundsInBox(Goal_CFrame, self.Size, self.OverlapParams)

        return BoundingParts
        
    end,

    [Enum.PartType.Ball] = function(self)

        local Goal_CFrame = Get_CFrame[typeof(self.CFrame)](self.CFrame)

        if typeof(self.Size) == "Vector3" then
            warn("You need to give number for size, if you want to use Ball shape")
        end

        local BoundingParts = workspace:GetPartBoundsInRadius(Goal_CFrame.Position, self.Size, self.OverlapParams)

        return BoundingParts
        
    end,

}


function HitboxManager:Visualize_BasePart()

    local CFrame = Get_CFrame[typeof(self.CFrame)](self.CFrame)

    local Visualizer = Instance.new("Part")
    Visualizer.Color = Color3.fromRGB(255, 0, 0)
    Visualizer.Shape = self.Shape
    Visualizer.Size = self.Size
    Visualizer.CFrame = CFrame
    Visualizer.Parent = workspace.Terrain
    Visualizer.CanCollide , Visualizer.CanTouch, Visualizer.CanQuery = false, false, false
    Visualizer.Transparency = 0.5

    self.Visualizer = Visualizer

    self.Connections["Visualizer"] = RunService.Heartbeat:Connect(function()
        Visualizer.CFrame = Get_CFrame[typeof(self.CFrame)](self.CFrame)
    end)

end


function HitboxManager:Add_Touching_Parts(Part)

    if not table.find(self.TouchingParts, Part) then
        table.insert(self.TouchingParts, Part)
    end
    
end


function HitboxManager:Hitboxing_BasePart()
    
    local DetectionMode = self.DetectionMode
    local BoundingParts = BasePart_Hitbox[self.Shape](self)

    for _, Part in pairs(BoundingParts) do

        local Character = Part:FindFirstAncestorOfClass("Model") or Part.Parent
        local Humanoid = Character:FindFirstChildOfClass("Humanoid")

        if Humanoid then
            HitboxManager.DetectionMode_Functions[DetectionMode](self, Humanoid, Part)
        end

    end

end

function HitboxManager:Add_HitList(Humanoid)
    
    local Character_Name = Humanoid.Parent.Name

    self.HitList[Character_Name] = Humanoid
    
end

HitboxManager.DetectionMode_Functions = {
    ["Multi"] = function(self, Humanoid, Part)

        self:Add_Touching_Parts(Part)
        self:Add_HitList(Humanoid)

        self.Touched:Fire(Part, Humanoid)

    end,

    ["Single"] = function(self, Humanoid, Part)

        self:Add_Touching_Parts(Part)
        self:Add_HitList(Humanoid)

        self.Touched:Fire(Part, Humanoid)

        self:Stop_Hitboxing_BasePart()

        --You would need to break loop if the detection mode is Single, check it later
    end

}
    



return HitboxManager