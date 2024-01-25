--Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PlayerService = game:GetService("Players")

--Modules 
local GoodSignal = require(ReplicatedStorage:WaitForChild("Modules").GoodSignal)
local RaycastVisualizer = require(ReplicatedStorage:WaitForChild("Modules").RaycastVisualizer)

local HitboxManager = {}
HitboxManager.__index = HitboxManager

HitboxManager.DetectionModes = {
    ["MultiplePlayer"] = "MultiplePlayer", --Detects multiple players but hits only one time (Defualt)
    ["SingleHit"] = "SingleHit", --Detects only one player and hits only one time
    ["Continuous"] = "Continuous", --Can detect multiple players and hit continuous (You can set how fast it hits)
    ["MultiplePlayerButOnlyHitsHead"] = "MultiplePlayerButOnlyHitsHead" --Works like MultiplePlayer(It's the defualt one) but it only hits to head
}

HitboxManager.HitboxCastingModes = {
    ["HitEveryPlayerOnRay"] = "HitEveryPlayerOnRay", -- Sends rays and add things that hit to the blacklist, it continuous until raycast doesn't hit anything and if there is a player on blacklist, the player will get damaged
    ["Continuous"] = "Continuous", -- Sends ray and damages player if hit's a player continuous (with debounce time)
    ["SingleRay"] = "SingleRay", -- Sends only one ray and hits only one player, only one time

}

HitboxManager.CastModes = {
    ["Raycast"] = "Raycast",
    ["Spherecast"] = "Spherecast",
    ["Shapecast"] = "Shapecast" -- Coming soon
}

HitboxManager.HitboxModes = {
    ["Range"] = "Range",
    ["Cast"] = "Cast"
}

RaycastVisualizer.Settings.CreateBillboard = false
RaycastVisualizer.Settings.VisualizationLifeTime = 2

function GetCFrame(self_CFrame)
    if typeof(self_CFrame) == "Instance" then
        return self_CFrame.CFrame
    elseif typeof(self_CFrame) == "CFrame" then
        return self_CFrame
    end
end


function HitboxManager.new()
    local self = setmetatable({}, HitboxManager)

    self.HitboxMode = "Range" -- Range, Raycast(Could be spherecast, spahecast or blockcast etc.)

    self.DetectionMode = "MultiplePlayer"
    self.Visualize = false  -- Doesn't suggest in-game, if you want to visualize hitbox set it to true
    self.PlayerHitList = {} -- The Player's names that hit by hitbox shown there
    self.CurrentlyTouchingParts = {} -- Shows the touching parts, it shows all parts that's in hitbox
    self.Connections = {} -- To store connections
    self.DebounceList = {}

    self.Touched = GoodSignal.new() -- Using GoodSignal to make connection with other scripts
    self.StateChanged = GoodSignal.new()
    self.Hit = GoodSignal.new()

    self.OverlapParams = OverlapParams.new() -- OverlapParams for Hitbox

    self.Size = Vector3.new(1, 1, 1) or 1
    self.CFrame = CFrame.new(0, 0, 0)
    self.Position = Vector3.new(0, 0, 0)

    self.Duration = math.huge
    self.ContinuousDebounce = 0.5

    self.Shape = Enum.PartType.Block --Or you can use Enum.PartType.Ball

    self.StartTime = time()

    self.States = {
        ["Ready"] = true,
        ["Running"] = false,
        ["Destroying"] = false,
        ["Destroyed"] = false,
    }

    self.CastMode = "Raycast"
    self.HitboxCastingMode = HitboxManager.HitboxCastingModes.HitEveryPlayerOnRay

    self.RaycastInfo = {
        origin = Vector3.new(0, 0, 0),
        direction = Vector3.new(0, 10, 0),
        raycastParams = RaycastParams.new(),
    }

    self.RaycastInfo.raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    self.RaycastInfo.raycastParams.FilterDescendantsInstances = {}

    self.SpherecastInfo = {
        position = Vector3.new(0, 0, 0),
        radius = 1,
        direction = Vector3.new(0, 10, 0),
        raycastParams = RaycastParams.new()
    }

    self.SpherecastInfo.raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    self.SpherecastInfo.raycastParams.FilterDescendantsInstances = {}

    self.CastHitList = {}

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


  function HitboxManager:SendCast()

    local CastMode = self.CastMode

    if CastMode == HitboxManager.CastModes.Raycast then

        local origin = self.RaycastInfo.origin
        local direction = self.RaycastInfo.direction
        local raycastParams = self.RaycastInfo.raycastParams

        local Raycast = workspace:Raycast(origin, direction, raycastParams)

        --Visualizing cast
        if self.Visualize then
            RaycastVisualizer:VisualizeRaycast(origin, direction)
        end

        if Raycast then
            return Raycast
        else
            return nil
        end

    elseif CastMode == HitboxManager.CastModes.Spherecast then

        local position = self.SpherecastInfo.position
        local radius = self.SpherecastInfo.radius
        local direction = self.SpherecastInfo.direction
        local raycastParams = self.SpherecastInfo.raycastParams

        local Spherecast = workspace:Spherecast(position, radius, direction, raycastParams)

        --Visualizing cast
        if self.Visualize then
            RaycastVisualizer:VisualizeSpherecast(position, radius, direction)
        end

        if Spherecast then
            return Spherecast
        else
            return nil
        end

    end

  end


  function HitboxManager:GetBoundingPartsForCast(HitboxCastingMode :string)

    if HitboxCastingMode == HitboxManager.HitboxCastingModes.HitEveryPlayerOnRay then

            local CastHitList = {}
                
            repeat

                local Cast = self:SendCast()
                local CastHitPart = Cast and Cast.Instance

                self[self.CastMode.."Info"].raycastParams:AddToFilter(CastHitPart) -- We are excluding parts that we hit and doing it until no hits

                table.insert(CastHitList, CastHitPart)
                
            until self:SendCast() == nil

            return CastHitList

    elseif  HitboxCastingMode == HitboxManager.HitboxCastingModes.SingleRay then

            local Cast = self:SendCast()
            local CastHitPart = Cast and Cast.Instance

            return CastHitPart
            -- No need to make function for Continuous, I will make the different on other function
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

    self.CurrentlyTouchingParts = BoundingParts

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

        if self.DebounceList[PlayerName] then

            if self.DebounceList[PlayerName] + self.ContinuousDebounce < time()then
                self.DebounceList[PlayerName] = time()
            else
                return
            end

        else
            self.DebounceList[PlayerName] = time()
        end

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


function HitboxManager:HitboxingForCast()
    
    local HitboxCastingMode = self.HitboxCastingMode

    if HitboxCastingMode == HitboxManager.HitboxCastingModes.SingleRay then
        
        local CastHitPart = self:GetBoundingPartsForCast(HitboxManager.HitboxCastingModes.SingleRay)
        if not CastHitPart then return end
        local Character = CastHitPart and CastHitPart:FindFirstAncestorOfClass("Model") or CastHitPart.Parent
        local Humanoid = Character and Character:FindFirstChild("Humanoid")

        if Humanoid then
            local Player = PlayerService:GetPlayerFromCharacter(Character)
            local PlayerName = Player.Name

            self:AddToPlayerHitList(PlayerName)

            self.Hit:Fire(CastHitPart, Humanoid)
        end

        self:Destroy()

    elseif HitboxCastingMode == HitboxManager.HitboxCastingModes.HitEveryPlayerOnRay then

        local CastHitList = self:GetBoundingPartsForCast(HitboxManager.HitboxCastingModes.HitEveryPlayerOnRay)
        local HumanoidList = {}

        for _, Part in pairs(CastHitList)  do

            local Character = Part:FindFirstAncestorOfClass("Model") or Part.Parent
            local Humanoid = Character and Character:FindFirstChild("Humanoid")

            if Humanoid then

                local Player = PlayerService:GetPlayerFromCharacter(Character)
                local PlayerName = Player.Name

                if not HumanoidList[PlayerName] then

                    HumanoidList[PlayerName] = Humanoid

                    self:AddToPlayerHitList(PlayerName)

                    self.Hit:Fire(Part, Humanoid)
                end
            end

        end

        self:Destroy()

    elseif HitboxCastingMode == HitboxManager.HitboxCastingModes.Continuous then

        local Debounce = self.ContinuousDebounce
        local LastCastTime = 0

        self.Connections["Heartbeat2"] = RunService.Heartbeat:Connect(function()

            if LastCastTime + Debounce < time() then

                LastCastTime = time()

                local CastHitPart = self:GetBoundingPartsForCast(HitboxManager.HitboxCastingModes.SingleRay) -- Using single ray to get cast hit part
                if not CastHitPart then return end
                local Character = CastHitPart and CastHitPart:FindFirstAncestorOfClass("Model") or CastHitPart.Parent
                local Humanoid = Character and Character:FindFirstChild("Humanoid")

                if Humanoid then
                    local Player = PlayerService:GetPlayerFromCharacter(Character)
                    local PlayerName = Player.Name
        
                    self:AddToPlayerHitList(PlayerName)

                    self.Hit:Fire(CastHitPart, Humanoid)
                end

            end

        end)

    end


end

function HitboxManager:Start()

    self.StartTime = time()
    self:ChangeState("Running")

    if self.HitboxMode == "Range" then

        self.Connections["Heartbeat1"] = RunService.Heartbeat:Connect(function()

            self:FireTouching()
            if self.Visualize then
                self:VisualizeBasePart()
            end

            if self.StartTime + self.Duration < time() then
                self:Destroy()
            end

        end)

    elseif self.HitboxMode == "Cast" then

        self:HitboxingForCast()

        if self.StartTime + self.Duration < time() then  -- For "continuous" hitbox casting mode
            self:Destroy()
        end

    end

end


function HitboxManager:ReturnStoredDate()

    local TouchingPartsTable = table.clone(self.CurrentlyTouchingParts)
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
    table.clear(self.CurrentlyTouchingParts )

    setmetatable(self, nil)

    return StoredData

end



return HitboxManager


--[[
    ---Goal---
    My goal is getting a ray params and converting it to a raycast
    it could have same abilities as basepart hitboxs
]]