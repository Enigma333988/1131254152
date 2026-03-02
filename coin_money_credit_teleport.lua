-- Roblox Lua script: teleport "Coin", "Money", and "Credit" objects to the local character.
-- Place this as a LocalScript (e.g. StarterPlayerScripts).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local TARGET_NAMES = {
	Coin = true,
	Money = true,
	Credit = true,
}

local LOCAL_PLAYER = Players.LocalPlayer
local character = LOCAL_PLAYER.Character or LOCAL_PLAYER.CharacterAdded:Wait()

local function getRootPart(model)
	return model:FindFirstChild("HumanoidRootPart")
		or model:FindFirstChild("Torso")
		or model:FindFirstChild("UpperTorso")
end

local function moveInstanceToCharacter(inst)
	if not inst or not inst.Parent then
		return
	end

	local rootPart = getRootPart(character)
	if not rootPart then
		return
	end

	if inst:IsA("BasePart") then
		inst.CFrame = rootPart.CFrame
		inst.AssemblyLinearVelocity = Vector3.zero
		inst.AssemblyAngularVelocity = Vector3.zero
		return
	end

	if inst:IsA("Model") then
		local primary = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")
		if primary then
			inst:PivotTo(rootPart.CFrame)
		end
	end
end

local function onCharacterAdded(newCharacter)
	character = newCharacter
end

LOCAL_PLAYER.CharacterAdded:Connect(onCharacterAdded)

RunService.Heartbeat:Connect(function()
	for _, inst in ipairs(workspace:GetDescendants()) do
		if TARGET_NAMES[inst.Name] then
			moveInstanceToCharacter(inst)
		end
	end
end)
