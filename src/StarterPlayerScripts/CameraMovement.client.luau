local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

Player.CharacterAdded:Connect(function(character)
    Character = character
    Humanoid = Character:WaitForChild("Humanoid")
end)

local LerpAmount = 0.25



RunService:BindToRenderStep("CameraMovement", Enum.RenderPriority.Camera.Value + 1, function()

    local t = tick()
    local sinOffset = Vector3.new(math.sin(t * 2) * 0.1, math.sin(t * 2.5) * 0.1, math.sin(t * 3) * 0.1)

    if Humanoid.MoveDirection.Magnitude > 0 then
        sinOffset = Vector3.new(math.sin(t * 2.5) * 0.25, math.sin(t * 2.5) * 0.2, math.sin(t * 2) * 0.25)
    end

    Humanoid.CameraOffset = Humanoid.CameraOffset:Lerp((Humanoid.MoveDirection * 1 ) + sinOffset, LerpAmount)

end)