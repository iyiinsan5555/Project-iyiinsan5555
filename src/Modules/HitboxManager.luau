--Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PlayerService = game:GetService("Players")

--Modules 
local GoodSignal = require(ReplicatedStorage.Modules.GoodSignal)

local HitboxManager = {}
HitboxManager.__index = HitboxManager

HitboxManager.DetectionModes = {
    ["Multi"] = "Multi",
    ["Single"] = "Single",
    ["Constant"] = "Constant"
}

function HitboxManager.new()
    local self = setmetatable({}, HitboxManager)

    self.HitboxMode = "BasePart" -- BasePart, Raycast(Could be spherecast, spahecast or blockcast etc.)

    self.DetectionMode = "Multi" -- Multi (Can hit several humanoids but only hits one time to each humanoid), Single (Can hit only one humanoid and get deleted after the first hit), Constant (Hits too fast(0.06 seconds) and too much time and too much humanoids)
    self.Visualize = true  -- Doesn't suggest in-game
    self.PlayerHitList = {}
    self.CurrentlyTouchingParts = {}
    self.Connections = {}

    self.Touched = GoodSignal.new()

    self.OverlapParams = OverlapParams.new()

    self.Size = Vector3.new(1, 1, 1) or 1
    self.CFrame = CFrame.new(0, 0, 0)
    self.Position = Vector3.new(0, 0, 0)

    self.Duration = math.huge

    self.Shape = Enum.PartType.Block --Or you can use Enum.PartType.Ball

    self.StartTime = time()

    self.States = {
        ["Ready"] = true,
        ["Running"] = false,
        ["Destroying"] = false,
        ["Destroyed"] = false,
    }

    return self
end


function GetCFrame(self_CFrame)
    if typeof(self_CFrame) == "Instance" then
        return self_CFrame.CFrame
    elseif typeof(self_CFrame) == "CFrame" then
        return self_CFrame
    end
end



function HitboxManager:GetBoundingParts(Shape)

    if Shape == Enum.PartType.Block then

        local LastCFrame = GetCFrame(self.CFrame)
        local BoundingParts = workspace:GetPartBoundsInBox(LastCFrame, self.Size, self.OverlapParams)

        return BoundingParts

    elseif Shape == Enum.PartType.Ball then

        if typeof(self.Size) == "Vector3" then
            warn("You need to give number for size, if you want to use Ball shape. Currently calculating near value(Don't forget and don't use Vector3 for ball shape)")
            self.Size = self.Size.Magnitude
        end

        local LastCFrame = GetCFrame(self.CFrame)
        local BoundingParts = workspace:GetPartBoundsInRadius(LastCFrame, self.Size, self.OverlapParams)

        return BoundingParts
    end

end


function HitboxManager:GetState()

    local States = self.States

    for Key, State in pairs(States) do

        if State == true then
            print(Key)
            return Key
        end

    end

    error("No state found")
    return false

end

function HitboxManager:ChangeState(State :string)

    if self.States[State] ~= nil then
        for Key in pairs(self.States) do
            self.States[Key] = false
        end
        self.States[State] = true
    else
        error("Invalid state: " .. State)
    end

end


function HitboxManager:VisualizeBasePart()

   if not self.Visualizer then

        local Visualizer = Instance.new("Part")
        Visualizer.Color = Color3.fromRGB(255, 0, 0)
        Visualizer.Shape = self.Shape
        Visualizer.Size = self.Size
        Visualizer.CFrame = GetCFrame(self.CFrame)
        Visualizer.Parent = workspace.Terrain
        Visualizer.CanCollide , Visualizer.CanTouch, Visualizer.CanQuery = false, false, false
        Visualizer.Transparency = 0.5
        Visualizer.Anchored = true

        self.Visualizer = Visualizer

    else
        self.Visualizer.CFrame = GetCFrame(self.CFrame)
   end

    if not (self:GetState() == "Running") then
        --warn("Can't visualize basepart, because hitbox isn't running")

        if self.Visualizer then
            self.Visualizer:Destroy()
            self.Visualizer = nil
        end
        return
    end

end


function HitboxManager:AddTouchingParts(BoundingParts :table)

    self.TouchingParts = BoundingParts

end


function HitboxManager:FireTouching()

    local BoundingParts = self:GetBoundingParts(self.Shape)

    for _, Part in pairs(BoundingParts) do

        local Character = Part:FindFirstAncestorOfClass("Model") or Part.Parent
        local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")

        self:AddTouchingParts(BoundingParts)

        if Humanoid then
            self:Hitboxing(Part, Humanoid)
        end

    end

end

function HitboxManager:AddToPlayerHitList(PlayerName :string)

    local PlayerHitList = self.PlayerHitList
    
    if not table.find(PlayerHitList, PlayerName) then
        table.insert(PlayerHitList, PlayerName)
    end

end


function HitboxManager:Hitboxing(HitPart, Humanoid)

    local DetectionMode = self.DetectionMode
    local Character = Humanoid.Parent
    local Player = PlayerService:GetPlayerFromCharacter(Character)
    local PlayerName = Player.Name

    if DetectionMode == "Single" then

        self:AddToPlayerHitList(PlayerName)

        self.Touched:Fire(HitPart, Humanoid)

        self:Destroy()

    elseif DetectionMode == "Multi" then

        if table.find(self.PlayerHitList, PlayerName) then
            return
        else
            self:AddToPlayerHitList(PlayerName)
        end

        self.Touched:Fire(HitPart, Humanoid)

    elseif DetectionMode == "Constant" then

        self:AddToPlayerHitList(PlayerName)

        self.Touched:Fire(HitPart, Humanoid)

    end

end

function HitboxManager:Start()

    self.StartTime = time()
    self:ChangeState("Running")

    self.Connections["Heartbeat1"] = RunService.Heartbeat:Connect(function()

        self:FireTouching()
        if self.Visualize then
            self:VisualizeBasePart()
        end

        if self.StartTime + self.Duration < time() then
            self:Destroy()
        end

    end)

end

function HitboxManager:ReturnStoredDate()

    local TouchingPartsTable = table.clone(self.TouchingParts)
    local PlayerHitListTable = table.clone(self.PlayerHitList)

    local StoredData = {
        ["TouchingParts"] = TouchingPartsTable,
        ["PlayerHitList"] =  PlayerHitListTable
    }

    return StoredData
end


function HitboxManager:Destroy()

    self:ChangeState("Destroying")

    local StoredData = self:ReturnStoredDate()

    for _, Connection in pairs(self.Connections) do
        Connection:Disconnect()
        Connection = nil
    end

    self.Visualize = false

    self:VisualizeBasePart()

    self:ChangeState("Destroyed")

    table.clear(self.PlayerHitList)
    table.clear(self.Connections)
    table.clear(self.TouchingParts)

    setmetatable(self, nil)

    return StoredData

end



return HitboxManager