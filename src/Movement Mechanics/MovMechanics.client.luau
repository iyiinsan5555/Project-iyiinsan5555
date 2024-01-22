local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local JumpDebounce = false
local Flying = false
local DoubleJumpTime = 0.5 -- Time in seconds within which the second jump must occur
local FlyConnection = nil
local LastTimeJumpRequest = 0


local function StartFly()
    print("StartFly")

    FlyConnection = RunService.Heartbeat:Connect(function(DeltaTime)
        print(DeltaTime, "Flying")
    end)

end

local function EndFly()
    print("EndFly")

    FlyConnection:Disconnect()
    FlyConnection = nil

end

local function OnJumpRequest()

    if LastTimeJumpRequest + 0.25 < time() then
        return
    end

    LastTimeJumpRequest = time()

    print("OnJumpRequest",LastTimeJumpRequest)

    if Flying then
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