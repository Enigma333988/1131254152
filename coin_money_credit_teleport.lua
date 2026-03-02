-- Roblox LocalScript: force all zombie heads to stay in crosshair locally.
-- Example paths: Workspace.Zombies.Basic.Head / Workspace.Zombies.Skeleton.Head

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local ZOMBIES_FOLDER = Workspace:WaitForChild("Zombies")
local CROSSHAIR_DISTANCE = 8

local function placeAllHeadsToCrosshair()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end

	local targetCFrame = camera.CFrame + (camera.CFrame.LookVector * CROSSHAIR_DISTANCE)

	for _, zombie in ipairs(ZOMBIES_FOLDER:GetChildren()) do
		if zombie:IsA("Model") then
			local head = zombie:FindFirstChild("Head")
			if head and head:IsA("BasePart") then
				head.CFrame = targetCFrame
				head.AssemblyLinearVelocity = Vector3.zero
				head.AssemblyAngularVelocity = Vector3.zero
			end
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
