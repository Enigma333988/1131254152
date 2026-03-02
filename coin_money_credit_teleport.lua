local RunService = game:GetService("RunService")

local MAX_TARGET_DISTANCE = 250

local function getEnemyRoot()
	local zombies = workspace:FindFirstChild("Zombies")
	if zombies then
		return zombies
	end

	return workspace:FindFirstChild("Monsters")
end

local function getCharacterHead()
	local camera = workspace.CurrentCamera
	if not camera then
		return nil
	end

	local root = getEnemyRoot()
	if not root then
		return nil
	end

	local bestHead = nil
	local bestDistance = math.huge
	local cameraPos = camera.CFrame.Position

	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Name == "Head" and descendant.Parent then
			local distance = (descendant.Position - cameraPos).Magnitude
			if distance < bestDistance and distance <= MAX_TARGET_DISTANCE then
				bestDistance = distance
				bestHead = descendant
			end
		end
	end

	return bestHead
end

local function applyAimbot()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	local targetHead = getCharacterHead()
	if not targetHead then
		return
	end

	camera.CFrame = CFrame.new(camera.CFrame.Position, targetHead.Position)
end

RunService.RenderStepped:Connect(function()
	local ok = pcall(applyAimbot)
	if not ok then
		-- silence runtime overlay spam
	end
end)
