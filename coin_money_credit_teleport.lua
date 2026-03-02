-- Roblox LocalScript: creates wool balls at the local player's feet.
-- Template source:
-- FullName: Workspace.Tycoon.Tycoons.D.Drops.2.Wool
-- Parent: Workspace.Tycoon.Tycoons.D.Drops.2

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LOCAL_PLAYER = Players.LocalPlayer

local TYCOON = Workspace:WaitForChild("Tycoon")
local TYCOONS = TYCOON:WaitForChild("Tycoons")
local DROP_POINT = TYCOONS:WaitForChild("D"):WaitForChild("Drops"):WaitForChild("2")
local WOOL_TEMPLATE = DROP_POINT:WaitForChild("Wool")

local SPAWN_INTERVAL = 0.15
local FEET_OFFSET = Vector3.new(0, -3, 0)

local elapsed = 0

local function setInstancePosition(instance, position)
	if instance:IsA("Model") then
		instance:PivotTo(CFrame.new(position))
	elseif instance:IsA("BasePart") then
		instance.CFrame = CFrame.new(position)
		instance.AssemblyLinearVelocity = Vector3.zero
		instance.AssemblyAngularVelocity = Vector3.zero
	end
end

local function createBallAtFeet(character)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end

	local ball = WOOL_TEMPLATE:Clone()
	ball.Parent = DROP_POINT

	local spawnPosition = rootPart.Position + FEET_OFFSET
	setInstancePosition(ball, spawnPosition)
end

RunService.RenderStepped:Connect(function(deltaTime)
	elapsed += deltaTime
	if elapsed < SPAWN_INTERVAL then
		return
	end
	elapsed = 0

	local character = LOCAL_PLAYER.Character
	if character then
		createBallAtFeet(character)
	end
end)
