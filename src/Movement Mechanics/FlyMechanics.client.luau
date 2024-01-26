local PlayerService = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CustomInstanceCreator = require(ReplicatedStorage:WaitForChild("Modules").CustomInstanceCreatorModule)

local JumpDebounce = false
local Flying = false
local DoubleJumpTime = 0.5 -- Time in seconds within which the second jump must occur
local FlyConnection = nil
local LastTimeJumpRequest = 0

local Player = PlayerService.LocalPlayer
local Character = script.Parent.Parent --Just get the character, could change later
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

local Camera = workspace:WaitForChild("Camera")

local ControlModule = require(Player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
local VelocityCalculator = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("VelocityCalculator"))


local function StartFly()
    print("StartFly")

    Flying = true

    local LinearVelocity :LinearVelocity = CustomInstanceCreator:CreateInstance("LinearVelocity", "LinearVelocityForFlying", HumanoidRootPart)
    LinearVelocity.Attachment0 = HumanoidRootPart.RootRigAttachment
    LinearVelocity.ForceLimitsEnabled = false
	LinearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
    LinearVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    LinearVelocity.VectorVelocity = Vector3.new(0, 2, 0)

    local AlignOrientation :AlignOrientation = CustomInstanceCreator:CreateInstance("AlignOrientation", "AlignOrientationForFlying", HumanoidRootPart)
    AlignOrientation.RigidityEnabled = false
    AlignOrientation.MaxAngularVelocity = math.huge
    AlignOrientation.MaxTorque = math.huge
    AlignOrientation.Attachment0 = HumanoidRootPart.RootRigAttachment
    AlignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment

    LinearVelocity.Enabled = true
    AlignOrientation.Enabled = true

    local FlyPreviewPart = Instance.new("Part")
    FlyPreviewPart.Parent = Workspace.Terrain
    FlyPreviewPart.Anchored = true
    FlyPreviewPart.CanCollide, FlyPreviewPart.CanTouch, FlyPreviewPart.CanQuery = false, false, false
    FlyPreviewPart.Transparency = 0.5

    Humanoid:ChangeState(Enum.HumanoidStateType.Physics)

    local CustomVelocity = VelocityCalculator.new()
    CustomVelocity.MaxSpeed = 50  -- Will be change relevant with players power (like fly speed)

    CustomVelocity.Changed:Connect(function(NewVelocity, PreviousVelocity)
        print("New velocity: "..tostring(NewVelocity), " Old velocity: "..tostring(PreviousVelocity))
    end)

    FlyConnection = RunService.Heartbeat:Connect(function()

        print("Flying")

        local MoveVector :Vector3 = ControlModule:GetMoveVector()
        local CameraCFrame :CFrame = Camera.CFrame

        local Direction :Vector3 = CameraCFrame.RightVector * (MoveVector.X) + CameraCFrame.LookVector * (MoveVector.Z * -1)

        if Direction:Dot(Direction) > 0 then
            Direction = Direction.Unit
        end

        CustomVelocity:SetVelocityWithTween(Direction * 1000000)

        LinearVelocity.VectorVelocity = CustomVelocity.Velocity

        AlignOrientation.CFrame = Camera.CFrame

    end)

end

local function EndFly()
    print("EndFly")

    FlyConnection:Disconnect()
    FlyConnection = nil
    Flying = false

    CustomInstanceCreator:EditInstance("LinearVelocityForFlying", "Enabled", false)
    CustomInstanceCreator:EditInstance("AlignOrientationForFlying", "Enabled", false)

    Humanoid:ChangeState(Enum.HumanoidStateType.Freefall)

end

local function OnJumpRequest()

    local currentTime = time()
    if currentTime - LastTimeJumpRequest < 0.175 then
        -- If the last jump request was less than 0.175 seconds ago, ignore this request
        return
    end

    LastTimeJumpRequest = currentTime

    print("OnJumpRequest", LastTimeJumpRequest)


    if Flying == true then
        EndFly()
    end


    if JumpDebounce then
        StartFly()
    else
        JumpDebounce = true
        task.wait(DoubleJumpTime)
        JumpDebounce = false
    end

end

UserInputService.JumpRequest:Connect(OnJumpRequest)