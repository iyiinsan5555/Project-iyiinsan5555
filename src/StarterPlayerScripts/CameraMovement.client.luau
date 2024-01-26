local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerService = game:GetService("Players")

local Modules = ReplicatedStorage:WaitForChild("Modules")

local CameraMovementModule = require(Modules:WaitForChild("CameraMovementModule"))

local Player = PlayerService.LocalPlayer

local CameraMovement = CameraMovementModule.new(Player)

CameraMovement:Start()

CameraMovement.LerpAmount = 0.25
CameraMovement.MovingMultiplier = 1