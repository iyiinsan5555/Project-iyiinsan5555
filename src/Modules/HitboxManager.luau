--Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

--Modules 
local GoodSignal = require(ReplicatedStorage.Modules.GoodSignal)

local HitboxManager = {}
HitboxManager.__index = HitboxManager

function HitboxManager.new()
    local self = setmetatable({}, HitboxManager)

    self.HitboxMode = "BasePart" -- BasePart, Raycast(Could be spherecast, spahecast or blockcast etc.)

    self.DetectionMode = "Multi" -- Multi (Can hit several humanoids but only hits one time to each humanoid), Single (Can hit only one humanoid and get deleted after the first hit), Constant (Hits too fast(0.06 seconds) and too much time and too much humanoids)
    self.Visualize = true  -- Doesn't suggest in-game
    self.AutoDestroy = true -- Think about it
    self.HitList = {}
    self.TouchingParts = {}
    self.Connections = {}

    self.Touched = GoodSignal.new()

    self.OverlapParams = OverlapParams.new()

    self.Size = Vector3.new(1, 1, 1) or 1
    self.Position = Vector3.new(0, 0, 0)
    self.CFrame = CFrame.new(0, 0, 0)
    self.Position = Vector3.new(0, 0, 0)

    self.Duration = 10

    self.Shape = Enum.PartType.Block --Or you can use Enum.PartType.Ball

    self.StartTime = time()

    self.States = {
        ["Ready"] = true,
        ["Running"] = false,
        ["Stopping"] = false,
        ["Stopped"] = false,
    }

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


function HitboxManager:Get_State()

    local States = self.States

    for Key, State in pairs(States) do

        if State == true then
            print(Key)
            return Key
        end

    end

    print("No state found")
    return false

end

function HitboxManager:Change_State(State :string)

    if self.States[State] ~= nil then
        for k in pairs(self.States) do
            self.States[k] = false
        end
        self.States[State] = true
    else
        error("Invalid state: " .. State)
    end

end


function HitboxManager:Visualize_BasePart()

   if not self.Visualizer then

        local Visualizer = Instance.new("Part")
        Visualizer.Color = Color3.fromRGB(255, 0, 0)
        Visualizer.Shape = self.Shape
        Visualizer.Size = self.Size
        Visualizer.CFrame = Get_CFrame[typeof(self.CFrame)](self.CFrame)
        Visualizer.Parent = workspace   
        Visualizer.CanCollide , Visualizer.CanTouch, Visualizer.CanQuery = false, false, false
        Visualizer.Transparency = 0.5
        Visualizer.Anchored = true

        self.Visualizer = Visualizer

    else
        self.Visualizer.CFrame = Get_CFrame[typeof(self.CFrame)](self.CFrame)
   end

    if not self:Get_State() == "Running" then
        warn("Can't visualize basepart, because hitbox isn't running")

        if self.Visualizer then
            self.Visualizer:Destroy()
            self.Visualizer = nil
        end
        return
    end

end


function HitboxManager:Add_Touching_Parts(Part) -- Rewrite

    if not table.find(self.TouchingParts, Part) then
        table.insert(self.TouchingParts, Part)
    end

end


function HitboxManager:Hitboxing_BasePart()

    local DetectionMode = self.DetectionMode
    local BoundingParts = BasePart_Hitbox[self.Shape](self)

    for _, Part in pairs(BoundingParts) do

        local Character = Part:FindFirstAncestorOfClass("Model") or Part.Parent
        local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")

        if Humanoid then
            HitboxManager.DetectionMode_Functions[DetectionMode](self, Humanoid, Part)
        end

    end

end

HitboxManager.DetectionMode_Functions = {
    ["Constant"] = function(self, Humanoid, Part)
        print("Constant")
        --self:Add_Touching_Parts(Part)

        local Character_Name = Humanoid.Parent.Name
        self.HitList[Character_Name] = Humanoid

        self.Touched:Fire(Part, Humanoid)

    end,

    ["Single"] = function(self, Humanoid, Part)
        print("Single")
        --self:Add_Touching_Parts(Part)

        local Character_Name = Humanoid.Parent.Name
        self.HitList[Character_Name] = Humanoid

        self.Touched:Fire(Part, Humanoid)

        self:Stop_Hitboxing_BasePart()

        --You would need to break loop if the detection mode is Single, check it later
    end,

    ["Multi"] = function(self, Humanoid, Part)
        print("Multi")
        --self:Add_Touching_Parts(Part)

        local Character_Name = Humanoid.Parent.Name
        if table.find(self.HitList, Character_Name) then
            return
        else
            self.HitList[Character_Name] = Humanoid
        end

        self.Touched:Fire(Part, Humanoid)

    end


}

function HitboxManager:Start_Hitboxing_BasePart()

    self.StartTime = time()
    self:Change_State("Running")

    self.Connections["BasePart_Hitboxing"] = RunService.Heartbeat:Connect(function()

        self:Hitboxing_BasePart()
        if self.Visualize then
            self:Visualize_BasePart()
        end

        if self.StartTime + self.Duration < time() then
            self:Stop_Hitboxing_BasePart()
        end

    end)


end


function HitboxManager:Stop_Hitboxing_BasePart()

    print("Stopping")

    self:Change_State("Stopping")

    --So i have to stop hitboxing here
    if self.Connections["BasePart_Hitboxing"] then

        local Connection = self.Connections["BasePart_Hitboxing"]
        Connection:Disconnect()
        Connection = nil

    end

    self.Visualize = false

    if self.Visualizer then
        self.Visualizer:Destroy()
        self.Visualizer = nil
    end

    self.HitList = {}
    self.TouchingParts = {}

    self:Change_State("Stopped")

end



return HitboxManager