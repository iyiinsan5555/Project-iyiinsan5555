local PlayerService = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CustomInstanceCreator = require(ReplicatedStorage:WaitForChild("Modules").CustomInstanceCreatorModule)

local IsFalling = false
local Flying = false
local DoubleJumpTime = 0.5 -- Time in seconds within which the second jump must occur
local FlyConnection = nil
local LastTimeFlyRequest = 0

local Player = PlayerService.LocalPlayer
local Character = script.Parent.Parent --Just get the character, could change later
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

local Camera = workspace:WaitForChild("Camera")

local ControlModule = require(Player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
local VelocityCalculator = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("VelocityCalculator"))


Humanoid.StateChanged:Connect(function()
    if Enum.HumanoidStateType.FallingDown or Enum.HumanoidStateType.Freefall then
        IsFalling = true
    else
        IsFalling = false
    end
end)


local function StartFly()

    if LastTimeFlyRequest + DoubleJumpTime > tick() then
        return
    end

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
    CustomVelocity.TweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, false, 0)

    --CustomVelocity.Changed:Connect(function(NewVelocity, PreviousVelocity)
        --print("New velocity: "..tostring(NewVelocity), " Old velocity: "..tostring(PreviousVelocity))
    --end)

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
        
        -- Use MoveVector to play animations

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

    if LastTimeFlyRequest + 0.15 > time() then
        return
    end

    LastTimeFlyRequest = time()

    local HumanoidState = Humanoid:GetState()

    if not Flying and IsFalling and not (HumanoidState == Enum.HumanoidStateType.Running or HumanoidState == Enum.HumanoidStateType.Jumping) then
        StartFly()
    elseif Flying and HumanoidState == Enum.HumanoidStateType.Physics then
        EndFly()
    end

end

UserInputService.JumpRequest:Connect(OnJumpRequest)