-- Roblox LocalScript:
-- Magnet all zombie heads to crosshair
-- Toggle with keyboard key: T

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local MAGNET_DISTANCE = 8
local magnetEnabled = false

local function isZombieHead(instance)
	if not instance:IsA("BasePart") then
		return false
	end

	if instance.Name ~= "Head" then
		return false
	end

	local parentModel = instance.Parent
	if not parentModel or not parentModel:IsA("Model") then
		return false
	end

	local zombiesRoot = Workspace:FindFirstChild("Zombies")
	if not zombiesRoot then
		return false
	end

	return instance:IsDescendantOf(zombiesRoot)
end

local function gatherZombieHeads()
	local heads = {}
	local zombiesRoot = Workspace:FindFirstChild("Zombies")
	if not zombiesRoot then
		return heads
	end

	for _, descendant in ipairs(zombiesRoot:GetDescendants()) do
		if isZombieHead(descendant) then
			table.insert(heads, descendant)
		end
	end

	return heads
end

local function getCrosshairPosition()
	local camera = Workspace.CurrentCamera
	if not camera then
		return nil
	end

	return camera.CFrame.Position + (camera.CFrame.LookVector * MAGNET_DISTANCE)
end

local function magnetHeadsToCrosshair()
	if not magnetEnabled then
		return
	end

	local targetPosition = getCrosshairPosition()
	if not targetPosition then
		return
	end

	local targetCFrame = CFrame.new(targetPosition)
	for _, head in ipairs(gatherZombieHeads()) do
		if head and head.Parent then
			head.CFrame = targetCFrame
			head.AssemblyLinearVelocity = Vector3.zero
			head.AssemblyAngularVelocity = Vector3.zero
		end
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.T then
		magnetEnabled = not magnetEnabled
	end
end)

RunService.RenderStepped:Connect(function()
	magnetHeadsToCrosshair()
end)
