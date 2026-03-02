local RunService = game:GetService("RunService")

local CROSSHAIR_DISTANCE = 8

local function getZombieRoot()
	local world = workspace
	local zombies = world:FindFirstChild("Zombies")
	if zombies then
		return zombies
	end

	return world:FindFirstChild("Monsters")
end

local function isHeadPart(instance)
	if not instance then
		return false
	end

	if not instance:IsA("BasePart") then
		return false
	end

	if instance.Name ~= "Head" then
		return false
	end

	return instance.Parent ~= nil
end

local function magnetHeadsToCrosshair()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	local zombiesRoot = getZombieRoot()
	if not zombiesRoot then
		return
	end

	local targetCFrame = camera.CFrame + (camera.CFrame.LookVector * CROSSHAIR_DISTANCE)

	for _, descendant in ipairs(zombiesRoot:GetDescendants()) do
		if isHeadPart(descendant) then
			descendant.CFrame = targetCFrame
			descendant.AssemblyLinearVelocity = Vector3.zero
			descendant.AssemblyAngularVelocity = Vector3.zero
		end
	end
end

RunService.RenderStepped:Connect(function()
	local ok = pcall(magnetHeadsToCrosshair)
	if not ok then
		-- keep silent to avoid error spam in executor overlays
	end
end)
