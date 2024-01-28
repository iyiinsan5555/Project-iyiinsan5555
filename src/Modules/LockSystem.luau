--Services //Getting services you know
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")


--Modules //Getting modules that i will use
local Modules = ReplicatedStorage:WaitForChild("Modules")

local GoodSignal = require(Modules:WaitForChild("GoodSignal"))



local LockSystem = {}
LockSystem.__index = LockSystem  

function LockSystem.new(Player :Player, Camera :Camera)

    local self = setmetatable({}, LockSystem)

    self.Player = Player
    self.Camera = Camera

    self.Locked = false --Is player locked to target

    self.Range = 100 --Range of locking to targets (used in GetPartBoundsInRadius)
    self.CameraSpeed = 20 --Speed of camera lerping (used in lerp function)
    self.CameraOffset = Vector3.new(3, 4, -9) --Camera offset of player
    self.RequiresLineOfSight = true  --If true we send a ray to see if target is in line of sight

    self.SwitchDebounce = 0.3 --The debounce of switching targets
    self.SwitchSens = 2 --The sensitivity of switching, used with mouse delta
    self.SwitchRange = 50 --The range of switching targets (we are using it to find potential switchable targets)

    self.Target = nil --The target, player is locked to

    self.Targets = {} --Table of target's in range
    self.TargetsInViewOfCamera = {} --Table of target's in view of camera and in range
    self.PotantialTargets = {} --Table of switchable targets
    self.Connections = {} --Table of connections, used to stop connections

    self.Character = Player.Character or Player.CharacterAdded:Wait() --Getting character to use it

    Player.CharacterAdded:Connect(function(character) --Updateting character when it added
        self.Character = character
    end)

    self.TargetChanged = GoodSignal.new() --Signal to TargetChanged, fires when target changed

    return self
end


function LockSystem:GetTargetsInRange()

    local PlayerCharacter :Model = self.Character --Getting character to use it
    local HumanoidRootPart :BasePart = PlayerCharacter:WaitForChild("HumanoidRootPart")

    if not HumanoidRootPart then --If can't find HumanoidRootPart then returns
        warn("PlayerCharacter has no HumanoidRootPart")
        return
    end

    local PartsInRange :table = workspace:GetPartBoundsInRadius(HumanoidRootPart.Position, self.Range) --Getting all bounding parts in range

    for _, Part :BasePart in pairs(PartsInRange) do --Looping through all bounding parts

        if not Part or not Part:IsA("BasePart") then --If part is not a BasePart then skips it
            continue
        end

        local FoundCharacter :Model = Part:FindFirstAncestorOfClass("Model") or Part.Parent --Getting potential target character
        local FoundHumanoid :Humanoid = FoundCharacter and FoundCharacter:FindFirstChild("Humanoid") --Trying to find Humanoid in potential target

        if not FoundHumanoid then --If potential target has no Humanoid then skips it(potential target is not character)
            continue
        end

        if not table.find(self.Targets, FoundCharacter) and not (FoundCharacter == PlayerCharacter) then --If potential target is a NPC or Player and not our character then we add it to our table
            table.insert(self.Targets, FoundCharacter)
        end
    end

    return self.Targets --Returning to table of targets in range
end


function LockSystem:GetTargetInViewOfCamera()

    local Targets :table = self:GetTargetsInRange() --Getting targets in range

    local Nearest = 1 --Used with DotProduct and defines the max value of "Difference" can get

    local PlayerCharacter :Model = self.Character --Getting player's character to use it
    local HumanoidRootPart :BasePart = PlayerCharacter:FindFirstChild("HumanoidRootPart") --Getting HumanoidRootPart

    if not HumanoidRootPart then --Returning if no HumanoidRootPart
        warn("Character has no HumanoidRootPart")
        return
    end

    for _, TargetCharacter :Model in pairs(Targets) do --Looping through all targets in range

        local Distance :number = (TargetCharacter.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude --Calculating distance of target and our character

        local CameraToTarget :Vector3 = (TargetCharacter.HumanoidRootPart.Position - self.Camera.CFrame.Position).Unit --Calculating the vector from camera to target and make it unit(1 stud vector)
        local CameraLookVector :Vector3 = self.Camera.CFrame.LookVector --Getting Camera CFrame's LookVector

        local DotProduct :Vector3 = CameraToTarget:Dot(CameraLookVector) --Using Dot function to find the angle between CameraLookVector and CameraToTarget, it returns value -1 to 1. 1 is they are looking at same direction, -1 is is looking at opposite direction, 0 is they are looking at perpendicular direction
        local Difference = math.abs(1 - DotProduct) --Calcuating difference between DotProduct and 1 with abs function to prevent negative values
        --print("passed 119")
        if Distance < self.Range and DotProduct > 0.5 then --Checking is distance is less than Range and DotProduct is more than 0.5 (it means that target is in view of camera)
            --print("passed 121")
            if not table.find(self.TargetsInViewOfCamera, TargetCharacter) then --Checking if we already add target to table of targets in view of camera
                table.insert(self.TargetsInViewOfCamera, TargetCharacter) --If didn't add, add it
            end

            if Difference < Nearest then --Nearest is the maximum value of Difference, so if the value of Difference is less then Nearest, we change the value of Nearest to select to target that's center of camera
                --print("passed 128")
                Nearest = Difference
                self.Target = TargetCharacter --Selecting the target
            end
        end
    end

    return self.Target --Returning to target
end


function LockSystem:GetPotantialTargets() --Using it to get left and right characters

    local PlayerCharacter = self.Character --Getting character to define HumanoidRootPart
    local HumanoidRootPart = PlayerCharacter:FindFirstChild("HumanoidRootPart")

    if not HumanoidRootPart then --If no HumanoidRootPart then returns
        warn("Character has no HumanoidRootPart")
        return
    end

    local TargetsInViewOfCamera = self.TargetsInViewOfCamera --Getting table of targets in view of camera (we inserted them in this table in previous function)

    local NearestRight = self.SwitchRange --Defining variables to find nearest target
    local NearestLeft = -self.SwitchRange

    for _, TargetCharacter in pairs(TargetsInViewOfCamera) do
        if TargetCharacter and self.Target and TargetCharacter ~= self.Target then --Checking if TargetCharacter is valid and not equal to our target

            local Distance = HumanoidRootPart.CFrame:ToObjectSpace(TargetCharacter.HumanoidRootPart.CFrame) --Calculating to distance with using CFrame:ToObjectSpace to find distance between character and target (in local space)

            if not (Distance.Z < 0) then -- Is target's character in front of character
                print("Cant pass 162")
                continue
            end

            if Distance.X > 0 then --Checking if target is on right or left, if it's bigger than 0 it's on right, if it's smaller than 0 it's on left
                if NearestRight then
                    if Distance.X < NearestRight then --If distance is smaller then nearest then we change NearestRight to Distance.X to find the nearest target
                        NearestRight = Distance.X
                        self.PotantialTargets["RightTarget"] = TargetCharacter --Adding to to our PotentialTargets table
                    end
                else --If there is no defined nearest then we define it
                    NearestRight = Distance.X
                    self.PotantialTargets["RightTarget"] = TargetCharacter
                end
            elseif Distance.X < 0 then --If the Distance.X is smaller than 0 it's on left
                if NearestLeft then
                    if Distance.X > NearestLeft then --Doing similar thing as above
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

    return self.PotantialTargets --Returning to PotentialTargets table
end



function LockSystem:IsTargetInView(WantToCheckTarget :Model?) --Sends Raycast to check if target is in view (not blocked by any object)

    local PlayerCharacter = self.Character --Getting character as always
    local HumanoidRootPart = PlayerCharacter:WaitForChild("HumanoidRootPart") --Getting HumanoidRootPart

    local Target = WantToCheckTarget or self.Target --Checking if we want to check special target or our self.Target

    if not HumanoidRootPart or not Target:FindFirstChild("HumanoidRootPart") then --Checking if we have HumanoidRootPart
        warn("Character has no HumanoidRootPart")
        return
    end

    if WantToCheckTarget then --Removing from table to prevent not hitting our target
        if table.find(self.Targets, WantToCheckTarget) then
            table.remove(self.Targets, table.find(self.Targets, WantToCheckTarget))
        end
    else
        if table.find(self.Targets, self.Target) then
            table.remove(self.Targets, table.find(self.Targets, self.Target))
        end
    end

    local RayParams :RaycastParams = RaycastParams.new() --Creating RaycastParams
    RayParams.FilterType = Enum.RaycastFilterType.Exclude --Making it Exclude to not hit our other targets
    RayParams.FilterDescendantsInstances = {self.Targets, PlayerCharacter} --Adding our targets (also PlayerCharacter) to FilterDescendantsInstances

    local Origin :Vector3 = self.Camera.CFrame.Position --Setting Raycast's Origin to camera position
    local Direction :Vector3 = (Target.HumanoidRootPart.Position - Origin).Unit --Getting direction in 1 stud

    local Raycast :RaycastResult = workspace:Raycast(Origin, Direction * self.Range, RayParams) --Sending the raycast

    if Raycast then --If Raycast hits
        if (Raycast.Instance:FindFirstAncestorOfClass("Model") or Raycast.Instance.Parent) == Target then --And if the hit object is our target
            return true --Return true (yes it's in view)
        end
    end

    return false --Else return false (it's not in view)
end


function LockSystem:SelectTarget(OldTarget :Model?, NewTarget :Model?)

    if OldTarget then --Checking if we have OldTarget
        local LockHighlight :Highlight = OldTarget:FindFirstChild("LockHighlight") --If old target has LockHighlight then we destroy it

        if LockHighlight then
            LockHighlight:Destroy()
        end
    end

    if NewTarget then --Checking if we have NewTarget and adding effects to our target
        local LockHighlight = Instance.new("Highlight")
        LockHighlight.Parent = NewTarget
        LockHighlight.FillTransparency = 1
		LockHighlight.FillColor = Color3.fromRGB(255, 255, 255)
		LockHighlight.OutlineTransparency = 0
		LockHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		LockHighlight.Name = "LockHighlight"
        --Add more effects later

        self.TargetChanged:Fire(NewTarget, OldTarget) --Firing TargetChanged event

        self.Locked = true --And we set Locked to true
    end

end


function LockSystem:Start() --The main function for LockSystem

    local PlayerCharacter :Model = self.Character --Getting Player's character
    local Camera :Camera = self.Camera --Getting Camera

    if not PlayerCharacter then --If there is no Player's character we are waiting until found character that has HumanoidRootPart
        repeat
            task.wait(0.1) --Delay to prevent bugs
        until PlayerCharacter and PlayerCharacter:FindFirstChild("HumanoidRootPart")
    end

    local HumanoidRootPart :BasePart = PlayerCharacter:FindFirstChild("HumanoidRootPart") --Getting HumanoidRootPart
    local Humanoid :Humanoid = PlayerCharacter:FindFirstChildOfClass("Humanoid") --Getting Humanoid

    if not Humanoid and HumanoidRootPart then --Checking if Humanoid and HumanoidRootPart is valid
        warn("PlayerCharacter has no Humanoid and HumanoidRootPart")
        return
    end

    local Target :Model = self:GetTargetInViewOfCamera() --Getting target by calling self:GetTargetInViewOfCamera()

    if not Target then --Checking if Target is valid, if not returning
        print("Returned 276")
        return
    end

    self:SelectTarget(nil, Target) --Giving our effect to Selected Target

    if Target and Target:FindFirstChild("Humanoid") and self:IsTargetInView(Target) then --Checking if Target is valid and has Humanoid and is line of sight
        --print("Passed 299")
        Camera.CameraType = Enum.CameraType.Scriptable --Making camera to Scriptable

        UserInputService.MouseIconEnabled = false --Disabling mouse icon
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition --Locking mouse to it's current position

    else --Else stop LockSystem and return
        self:Stop()
        print("Returned 291")
        return
    end

    local LastSwitchTime = 0
    local LastDeltaTime = 0

    RunService:BindToRenderStep("LockSystem", Enum.RenderPriority.Camera.Value + 1, function(DeltaTime)
        DeltaTime = (LastDeltaTime + DeltaTime) / 2
        LastDeltaTime = DeltaTime

        if not self.Target and not self.Target:FindFirstChild("Humanoid") and not self.Target:FindFirstChild("HumanoidRootPart") and not HumanoidRootPart then
            self:GetTargetInViewOfCamera()
            print("Returned 320")
            return
        end

        Target = self.Target

        local Distance = (Target.HumanoidRootPart.Position - PlayerCharacter.HumanoidRootPart.Position).Magnitude
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

        PlayerCharacter = self.Character
        Target = self.Target

        local TargetPosition :Vector3 = Target.HumanoidRootPart.Position
        local CharacterPosition :Vector3 = PlayerCharacter.HumanoidRootPart.Position

        local LookTargetPosition = Vector3.new(TargetPosition.X, CharacterPosition.Y, TargetPosition.Z)
        local CalculatedCharacterCFrame :CFrame = CFrame.lookAt(CharacterPosition,
        LookTargetPosition,
        PlayerCharacter.HumanoidRootPart.CFrame.UpVector)

        PlayerCharacter:PivotTo(CalculatedCharacterCFrame)

        local HumanoidRootPartCFrame :CFrame = PlayerCharacter.HumanoidRootPart.CFrame

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