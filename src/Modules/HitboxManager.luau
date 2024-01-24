--Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PlayerService = game:GetService("Players")

--Modules 
local GoodSignal = require(ReplicatedStorage.Modules.GoodSignal)

local HitboxManager = {}
HitboxManager.__index = HitboxManager

HitboxManager.DetectionModes = {
    ["MultiplePlayer"] = "MultiplePlayer", --Detects multiple players but hits only one time (Defualt)
    ["SingleHit"] = "SingleHit", --Detects only one player and hits only one time
    ["Continuous"] = "Continuous", --Can detect multiple players and hit continuous (You can set how fast it hits)
    ["MultiplePlayerButOnlyHitsHead"] = "MultiplePlayerButOnlyHitsHead" --Works like MultiplePlayer(It's the defualt one) but it only hits to head
}


function GetCFrame(self_CFrame)
    if typeof(self_CFrame) == "Instance" then
        return self_CFrame.CFrame
    elseif typeof(self_CFrame) == "CFrame" then
        return self_CFrame
    end
end


function HitboxManager.new()
    local self = setmetatable({}, HitboxManager)

    self.HitboxMode = "BasePart" -- BasePart, Raycast(Could be spherecast, spahecast or blockcast etc.)

    self.DetectionMode = "MultiplePlayer"
    self.Visualize = true  -- Doesn't suggest in-game, if you want to visualize hitbox set it to true
    self.PlayerHitList = {} -- The Player's names that hit by hitbox shown there
    self.CurrentlyTouchingParts = {} -- Shows the touching parts, it shows all parts that's in hitbox
    self.Connections = {} -- To store connections

    self.Touched = GoodSignal.new() -- Using GoodSignal to make connection with other scripts
    self.StateChanged = GoodSignal.new()

    self.OverlapParams = OverlapParams.new() -- OverlapParams for Hitbox

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


function HitboxManager:GetState()

    for State, IsSet in pairs(self.States) do
      if IsSet then 
        return State
      end
    end

    error("No state set!")
end


function HitboxManager:ChangeState(NewState)

    local PreviousState = self:GetState()

    if self.States[NewState] ~= nil then

      for State,_ in pairs(self.States) do
        self.States[State] = false
      end

      self.States[NewState] = true

      if PreviousState ~= NewState then
        self.StateChanged:Fire(NewState, PreviousState)
      end

    else
      error("Invalid state: " .. NewState)
    end

  end


function HitboxManager:VisualizeBasePart()

    if not self.Visualizer then
 
         local Visualizer = Instance.new("Part")
         Visualizer.Color = Color3.fromRGB(255, 0, 0)
         Visualizer.Shape = self.Shape
         Visualizer.CFrame = GetCFrame(self.CFrame)
         Visualizer.Parent = workspace.Terrain
         Visualizer.CanCollide , Visualizer.CanTouch, Visualizer.CanQuery = false, false, false
         Visualizer.Transparency = 0.5
         Visualizer.Anchored = true

         if self.Shape == Enum.PartType.Ball then
            Visualizer.Size = Vector3.new(self.Size * 2,self.Size * 2,self.Size * 2)
        else
            Visualizer.Size = self.Size
         end
 
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


function HitboxManager:AddToPlayerHitList(PlayerName :string)

    local PlayerHitList = self.PlayerHitList

    if not table.find(PlayerHitList, PlayerName) then
        table.insert(PlayerHitList, PlayerName)
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
        local BoundingParts = workspace:GetPartBoundsInRadius(LastCFrame.Position, self.Size, self.OverlapParams)

        return BoundingParts
    end

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

        if Part.Name == "Head" then
            self:HitboxingOnlyHead(Part)
        end

    end

end


function HitboxManager:Hitboxing(HitPart, Humanoid)

    local DetectionMode = self.DetectionMode
    local Character = Humanoid.Parent
    local Player = PlayerService:GetPlayerFromCharacter(Character)
    local PlayerName = Player.Name

    if DetectionMode == "SingleHit" then

        self:AddToPlayerHitList(PlayerName)

        self.Touched:Fire(HitPart, Humanoid)

        self:Destroy()

    elseif DetectionMode == "MultiplePlayer" then

        if table.find(self.PlayerHitList, PlayerName) then
            return
        else
            self:AddToPlayerHitList(PlayerName)
        end

        self.Touched:Fire(HitPart, Humanoid)

    elseif DetectionMode == "Continuous" then

        self:AddToPlayerHitList(PlayerName)

        self.Touched:Fire(HitPart, Humanoid)

    end

end

function HitboxManager:HitboxingOnlyHead(Head)

    local DetectionMode = self.DetectionMode
    local Character = Head.Parent
    local Humanoid = Character:FindFirstChild("Humanoid")
    local Player = PlayerService:GetPlayerFromCharacter(Character)
    local PlayerName = Player.Name

    if not Humanoid then
        return
    end

    if DetectionMode == "MultiplePlayerButOnlyHitsHead" then

        if table.find(self.PlayerHitList, PlayerName) then
            return
        else
            self:AddToPlayerHitList(PlayerName)
        end

        self.Touched:Fire(Head, Humanoid)

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