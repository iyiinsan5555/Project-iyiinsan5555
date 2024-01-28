--Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")


--Modules
local Modules = ReplicatedStorage:WaitForChild("Modules")

local GoodSignal = require(Modules:WaitForChild("GoodSignal"))

--Definations


local LockSystem = {}
LockSystem.__index = LockSystem

function LockSystem.new(Player :Player, Camera :Camera)

    local self = setmetatable({}, LockSystem)

    self.Player = Player
    self.Camera = Camera

    self.Locked = false

    self.Range = 100
    self.CameraSpeed = 20
    self.CameraOffset = Vector3.new(3, 4, -9)
    self.RequiresLineOfSight = true

    self.SwitchDebounce = 0.3
    self.SwitchSens = 2
    self.SwitchRange = 50

    self.Target = nil

    self.Targets = {}
    self.TargetsInViewOfCamera = {}
    self.PotantialTargets = {}
    self.Connections = {}

    self.Character = Player.Character or Player.CharacterAdded:Wait()

    Player.CharacterAdded:Connect(function(character)
        self.Character = character
    end)

    self.PotantialTargets = {
        RightTarget = nil,
        LeftTarget = nil,
        UpTarget = nil,
        DownTarget = nil
    }

    self.TargetChanged = GoodSignal.new()

    return self
end


function LockSystem:GetTargetsInRange()

    local Character :Model = self.Character
    local HumanoidRootPart :BasePart = Character:WaitForChild("HumanoidRootPart")

    if not HumanoidRootPart then
        warn("Character has no HumanoidRootPart")
        return
    end

    local PartsInRange :table = workspace:GetPartBoundsInRadius(HumanoidRootPart.Position, self.Range)

    for _, Part :BasePart in pairs(PartsInRange) do

        if not Part or not Part:IsA("BasePart") then
            return
        end

        local FoundCharacter :Model = Part:FindFirstAncestorOfClass("Model") or Part.Parent
        local FoundHumanoid :Humanoid = FoundCharacter and FoundCharacter:FindFirstChild("Humanoid")

        if not FoundHumanoid then
            continue
        end

        if not table.find(self.Targets, FoundCharacter) and not (FoundCharacter == Character) then
            table.insert(self.Targets, FoundCharacter)
        end
    end

    return self.Targets
end


function LockSystem:GetTargetInViewOfCamera()

    local Targets :table = self:GetTargetsInRange()

    local Nearest = 1

    local Character :Model = self.Character
    local HumanoidRootPart :BasePart = Character:FindFirstChild("HumanoidRootPart")

    if not HumanoidRootPart then
        warn("Character has no HumanoidRootPart")
        return
    end

    for _, TargetCharacter :Model in pairs(Targets) do

        local Distance :number = (TargetCharacter.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude

        local CameraToTarget :Vector3 = (TargetCharacter.HumanoidRootPart.Position - self.Camera.CFrame.Position).Unit
        local CameraLookVector :Vector3 = self.Camera.CFrame.LookVector

        local DotProduct :Vector3 = CameraToTarget:Dot(CameraLookVector)
        local Difference = math.abs(1 - DotProduct)
        --print("passed 119")
        if Distance < self.Range and DotProduct > 0.5 then
            --print("passed 121")

            if not table.find(self.TargetsInViewOfCamera, TargetCharacter) then
                table.insert(self.TargetsInViewOfCamera, TargetCharacter)
            end

            if Difference < Nearest then
                --print("passed 128")
                Nearest = Difference
                self.Target = TargetCharacter
            end
        end
    end

    return self.Target
end


function LockSystem:GetPotantialTargets()

    local Character = self.Character
    local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")

    if not HumanoidRootPart then
        warn("Character has no HumanoidRootPart")
        return
    end

    local TargetsInViewOfCamera = self.TargetsInViewOfCamera

    local NearestRight = self.SwitchRange
    local NearestLeft = -self.SwitchRange
    --local NearestUp = self.SwitchRange
    --local NearestDown = -self.SwitchRange

    for _, TargetCharacter in pairs(TargetsInViewOfCamera) do
        if TargetCharacter and self.Target and TargetCharacter ~= self.Target then

            local Distance = HumanoidRootPart.CFrame:ToObjectSpace(TargetCharacter.HumanoidRootPart.CFrame)

            if not (Distance.Z < 0) then -- Is target's character in front of character
            print("Cant pass 162")
                continue
            end

            if Distance.X > 0 then
                if NearestRight then
                    if Distance.X < NearestRight then
                        NearestRight = Distance.X
                        self.PotantialTargets["RightTarget"] = TargetCharacter
                    end
                else
                    NearestRight = Distance.X
                    self.PotantialTargets["RightTarget"] = TargetCharacter
                end
            elseif Distance.X < 0 then
                if NearestLeft then
                    if Distance.X > NearestLeft then
                        NearestLeft = Distance.X
                        self.PotantialTargets["LeftTarget"] = TargetCharacter
                    end
                else
                    NearestLeft = Distance.X
                    self.PotantialTargets["LeftTarget"] = TargetCharacter
                end
            end

        end
    end

    for Key, TargetCharacter in pairs(self.PotantialTargets) do
        if TargetCharacter == self.Target then
            self.PotantialTargets[Key] = nil
        end
    end

    return self.PotantialTargets
end



function LockSystem:IsTargetInView(WantToCheckTarget :Model?)

    local Character = self.Character
    local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

    local Target = WantToCheckTarget or self.Target

    if not HumanoidRootPart or not Target:FindFirstChild("HumanoidRootPart") then
        warn("Character has no HumanoidRootPart")
        return
    end

    if WantToCheckTarget then
        if table.find(self.Targets, WantToCheckTarget) then
            table.remove(self.Targets, table.find(self.Targets, WantToCheckTarget))
        end
    else
        if table.find(self.Targets, self.Target) then
            table.remove(self.Targets, table.find(self.Targets, self.Target))
        end
    end

    local RayParams :RaycastParams = RaycastParams.new()
    RayParams.FilterType = Enum.RaycastFilterType.Exclude
    RayParams.FilterDescendantsInstances = {self.Targets, Character}

    local Origin :Vector3 = self.Camera.CFrame.Position
    local Direction :Vector3 = (Target.HumanoidRootPart.Position - Origin).Unit

    local Raycast :RaycastResult = workspace:Raycast(Origin, Direction * self.Range, RayParams)

    self:GetTargetsInRange()

    if Raycast then
        if (Raycast.Instance:FindFirstAncestorOfClass("Model") or Raycast.Instance.Parent) == Target then
            return true
        end
    end

    return false

end


function LockSystem:SelectTarget(OldTarget, NewTarget)

    if OldTarget then

        local LockHighlight :Highlight = OldTarget:FindFirstChild("LockHighlight")

        if LockHighlight then
            LockHighlight:Destroy()
        end
    end


    if NewTarget then
        local LockHighlight = Instance.new("Highlight")
        LockHighlight.Parent = NewTarget
        LockHighlight.FillTransparency = 1
		LockHighlight.FillColor = Color3.fromRGB(255, 255, 255)
		LockHighlight.OutlineTransparency = 0
		LockHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		LockHighlight.Name = "LockHighlight"
        --Add more effects later

        self.TargetChanged:Fire(NewTarget, OldTarget)

        self.Locked = true
    end

end


function LockSystem:Start()

    local Character :Model = self.Character
    local Camera :Camera = self.Camera

    if not Character then
        repeat
            task.wait(0.1)
        until Character and Character:FindFirstChild("HumanoidRootPart")
    end

    local HumanoidRootPart :BasePart = Character:FindFirstChild("HumanoidRootPart")
    local Humanoid :Humanoid = Character:FindFirstChildOfClass("Humanoid")

    if not Humanoid and HumanoidRootPart then
        warn("Character has no Humanoid and HumanoidRootPart")
        return
    end

    local Target :Model = self:GetTargetInViewOfCamera()

    if not Target then
        print(Target)
        print(self.Target)
        print("Returned 292")
        return
    end

    self:SelectTarget(nil, Target)

    if Target and Target:FindFirstChild("Humanoid") and self:IsTargetInView(Target) then
        --print("Passed 299")
        Camera.CameraType = Enum.CameraType.Scriptable

        UserInputService.MouseIconEnabled = false
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition

    else
        self:Stop()
        print("Returned 307")
        return
    end

    local LastSwitchTime = 0
    local LastDeltaTime = 0

    RunService:BindToRenderStep("LockSystem", Enum.RenderPriority.Camera.Value + 1, function(DeltaTime)
        DeltaTime = (LastDeltaTime + DeltaTime) / 2
        LastDeltaTime = DeltaTime
        --print("BindToRenderStep")

        if not self.Target and not self.Target:FindFirstChild("Humanoid") and not self.Target:FindFirstChild("HumanoidRootPart") and not HumanoidRootPart then
            self:GetTargetInViewOfCamera()
            print("Returned 320")
            return
        end

        Target = self.Target

        local Distance = (Target.HumanoidRootPart.Position - Character.HumanoidRootPart.Position).Magnitude
        local RequiresLineOfSight = self.RequiresLineOfSight
        local HastLineOfSight = self:IsTargetInView()
        local LineOfSight = (HastLineOfSight and RequiresLineOfSight) or not RequiresLineOfSight

        if not LineOfSight then
            --Find another target that's in the view
            print("Returned 334")
            self:Stop()
            return
        end

        if not (Distance < self.Range) and
        not Target:FindFirstChild("Humanoid") and
        not (Target:FindFirstChild("Humanoid").Health > 0)
        then
            self:Stop()
            print(Target:FindFirstChild("Humanoid"), Target:FindFirstChild("Humanoid").Health)
            print("Returned 343")
            return
        end

        Character = self.Character
        Target = self.Target

        local TargetPosition :Vector3 = Target.HumanoidRootPart.Position
        local CharacterPosition :Vector3 = Character.HumanoidRootPart.Position

        local LookTargetPosition = Vector3.new(TargetPosition.X, CharacterPosition.Y, TargetPosition.Z)
        local CalculatedCharacterCFrame :CFrame = CFrame.lookAt(CharacterPosition,
        LookTargetPosition,
        Character.HumanoidRootPart.CFrame.UpVector)

        Character:PivotTo(CalculatedCharacterCFrame)

        local HumanoidRootPartCFrame :CFrame = Character.HumanoidRootPart.CFrame

        local OffsetX = HumanoidRootPartCFrame.RightVector * self.CameraOffset.X
        local OffsetY = HumanoidRootPartCFrame.UpVector * self.CameraOffset.Y
        local OffsetZ = HumanoidRootPartCFrame.LookVector * self.CameraOffset.Z

        local Offset :Vector3 = OffsetX + OffsetY + OffsetZ
        local CameraPosition :Vector3  = HumanoidRootPart.Position + Offset

        local CalculatedCameraCFrame :CFrameValue = CFrame.lookAt(CameraPosition,
        TargetPosition,
        HumanoidRootPartCFrame.UpVector)

        Camera.CFrame = Camera.CFrame:Lerp(CalculatedCameraCFrame, DeltaTime * self.CameraSpeed)


        if LastSwitchTime + self.SwitchDebounce < time() then
            --print("Passed 377")
            local MouseDeltaX = UserInputService:GetMouseDelta().X
            local MouseDeltaY = UserInputService:GetMouseDelta().Y
            if MouseDeltaX > self.SwitchSens or MouseDeltaX < -self.SwitchSens or MouseDeltaY < -self.SwitchSens or MouseDeltaY > self.SwitchSens then
                --print("Passed 382")

                self:GetTargetInViewOfCamera()
                local PotantialTargets :table = self:GetPotantialTargets()
                local RightTarget = PotantialTargets["RightTarget"]
                local LeftTarget = PotantialTargets["LeftTarget"]
                local UpTarget = PotantialTargets["UpTarget"]
                local DownTarget = PotantialTargets["DownTarget"]


                if math.abs(MouseDeltaX) > math.abs(MouseDeltaY) then
                    --print(PotantialTargets)
                    if MouseDeltaX > self.SwitchSens and RightTarget and self:IsTargetInView(RightTarget) then
                        self:SelectTarget(Target, RightTarget)
                        self.Target = RightTarget
                    elseif MouseDeltaX < -self.SwitchSens and LeftTarget and self:IsTargetInView(LeftTarget) then
                        self:SelectTarget(Target, LeftTarget)
                        self.Target = LeftTarget
                    end
                else
                    if MouseDeltaY < -self.SwitchSens and UpTarget and self:IsTargetInView(UpTarget) then
                        self:SelectTarget(Target, UpTarget)
                        self.Target = UpTarget
                    elseif MouseDeltaY > self.SwitchSens and DownTarget and self:IsTargetInView(DownTarget) then
                        self:SelectTarget(Target, DownTarget)
                        self.Target = DownTarget
                    end
                end

                --[[if MouseDeltaX > self.SwitchSens and RightTarget and self:IsTargetInView(RightTarget) then
                    --print("Passed 390")
                    self:SelectTarget(Target, RightTarget)
                    self.Target = RightTarget
                elseif MouseDeltaX < -self.SwitchSens and LeftTarget and self:IsTargetInView(LeftTarget) then
                    self:SelectTarget(Target, LeftTarget)
                    self.Target = LeftTarget
                end
                print(MouseDeltaX, MouseDeltaY)]]

            end

            LastSwitchTime = time()
        end
    end)


    self.Connections["DeathConnection"] = Humanoid.Died:Connect(function()
        self:Stop()
    end)

end


function LockSystem:Stop()

    for _, Connection in pairs(self.Connections) do
        Connection:Disconnect()
        Connection = nil
    end

    RunService:UnbindFromRenderStep("LockSystem")

    self:SelectTarget(self.Target, nil)

    UserInputService.MouseIconEnabled = true
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default

    self.Camera.CameraType = Enum.CameraType.Custom

    self.Locked = false

end

return LockSystem