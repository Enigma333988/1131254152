-- Roblox LocalScript: force all monster heads to stay in crosshair locally.
-- Example monster path: Workspace.Monsters.Stalker.Head
-- Place in StarterPlayerScripts.

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local CAMERA = Workspace.CurrentCamera
local MONSTERS_FOLDER = Workspace:WaitForChild("Monsters")
local CROSSHAIR_DISTANCE = 8

local function placeAllHeadsToCrosshair()
	local targetCFrame = CAMERA.CFrame + (CAMERA.CFrame.LookVector * CROSSHAIR_DISTANCE)

	for _, monster in ipairs(MONSTERS_FOLDER:GetChildren()) do
		if monster:IsA("Model") then
			local head = monster:FindFirstChild("Head")
			if head and head:IsA("BasePart") then
				head.CFrame = targetCFrame
				head.AssemblyLinearVelocity = Vector3.zero
				head.AssemblyAngularVelocity = Vector3.zero
			end
		end
	end
end

RunService.RenderStepped:Connect(placeAllHeadsToCrosshair)
