local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CustomInstanceCreator = require(ReplicatedStorage:WaitForChild("Modules").CustomInstanceCreatorModule)

local JumpDebounce = false
local Flying = false
local DoubleJumpTime = 0.5 -- Time in seconds within which the second jump must occur
local FlyConnection = nil
local LastTimeJumpRequest = 0

local Character = script.Parent.Parent --Just get the character, could change later
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")


local function StartFly()
    print("StartFly")

    Flying = true

    local VectorForce :VectorForce = CustomInstanceCreator:CreateInstance("VectorForce", "VectorForceForFlying", HumanoidRootPart)
    VectorForce.Attachment0 = HumanoidRootPart.RootRigAttachment
    VectorForce.RelativeTo = Enum.ActuatorRelativeTo.World
    VectorForce.Force = Vector3.new(0, 5000, 0)

    local AlignOrientation :AlignOrientation = CustomInstanceCreator:CreateInstance("AlignOrientation", "AlignOrientationForFlying", HumanoidRootPart)
    AlignOrientation.MaxTorque = math.huge
    AlignOrientation.MaxAngularVelocity = math.huge
    AlignOrientation.Responsiveness = 30
    AlignOrientation.Attachment0 = HumanoidRootPart.RootRigAttachment
    AlignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment

    VectorForce.Enabled = true

    Humanoid:ChangeState(Enum.HumanoidStateType.Physics)

    FlyConnection = RunService.Heartbeat:Connect(function(DeltaTime)
        print(DeltaTime, "Flying")
    end)

end

local function EndFly()
    print("EndFly")

    FlyConnection:Disconnect()
    FlyConnection = nil
    Flying = false

    CustomInstanceCreator:EditInstance("VectorForceForFlying", "Enabled", false)
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