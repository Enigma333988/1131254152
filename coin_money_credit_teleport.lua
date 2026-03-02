-- Roblox LocalScript:
-- 1) pull drop balls + money to player for quick touch pickup
-- 2) periodically teleport player to Put.Zone to deposit and return

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LOCAL_PLAYER = Players.LocalPlayer

local COLLECT_INTERVAL = 0.12
local DEPOSIT_INTERVAL = 3
local PLAYER_PULL_OFFSET = Vector3.new(0, 2.5, 0)
local PUT_TOUCH_OFFSET = Vector3.new(0, 3, 0)
local MAX_PARTS_PER_SWEEP = 140

local collectElapsed = 0
local depositElapsed = 0

local function getRootPart()
	local character = LOCAL_PLAYER and LOCAL_PLAYER.Character
	if not character then
		return nil
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if rootPart and rootPart:IsA("BasePart") then
		return rootPart
	end

	return nil
end

local function findTycoonD()
	local tycoon = Workspace:FindFirstChild("Tycoon")
	if not tycoon then
		return nil
	end

	local tycoons = tycoon:FindFirstChild("Tycoons")
	if not tycoons then
		return nil
	end

	local tycoonD = tycoons:FindFirstChild("D")
	if tycoonD and tycoonD:IsA("Model") then
		return tycoonD
	end

	return nil
end

local function getDropsRoot()
	local tycoonD = findTycoonD()
	if not tycoonD then
		return nil
	end

	return tycoonD:FindFirstChild("Drops")
end

local function getPutZone()
	local tycoonD = findTycoonD()
	if not tycoonD then
		return nil
	end

	local buttons = tycoonD:FindFirstChild("Buttons_E")
	if not buttons then
		return nil
	end

	local put = buttons:FindFirstChild("Put")
	if not put then
		return nil
	end

	local zone = put:FindFirstChild("Zone")
	if zone and zone:IsA("BasePart") then
		return zone
	end

	return nil
end

local function isCollectablePart(instance)
	return instance:IsA("BasePart") and not instance.Anchored and instance.CanTouch ~= false
end

local function pullPartToPlayer(part, targetPosition)
	if not part or not part.Parent then
		return
	end

	part.CFrame = CFrame.new(targetPosition)
	part.AssemblyLinearVelocity = Vector3.zero
	part.AssemblyAngularVelocity = Vector3.zero
end

local function collectDropsAndMoney()
	local rootPart = getRootPart()
	if not rootPart then
		return
	end

	local pulled = 0
	local targetPosition = rootPart.Position + PLAYER_PULL_OFFSET

	local dropsRoot = getDropsRoot()
	if dropsRoot then
		for _, part in ipairs(dropsRoot:GetDescendants()) do
			if pulled >= MAX_PARTS_PER_SWEEP then
				break
			end

			if isCollectablePart(part) then
				pullPartToPlayer(part, targetPosition)
				pulled += 1
			end
		end
	end

	local moneyRoot = Workspace:FindFirstChild("Money")
	if moneyRoot then
		if moneyRoot:IsA("BasePart") then
			pullPartToPlayer(moneyRoot, targetPosition)
		else
			for _, part in ipairs(moneyRoot:GetDescendants()) do
				if pulled >= MAX_PARTS_PER_SWEEP then
					break
				end

				if isCollectablePart(part) then
					pullPartToPlayer(part, targetPosition)
					pulled += 1
				end
			end
		end
	end
end

local function depositToTerminal()
	local zone = getPutZone()
	if not zone then
		return
	end

	local rootPart = getRootPart()
	if not rootPart then
		return
	end

	local startCFrame = rootPart.CFrame
	rootPart.CFrame = CFrame.new(zone.Position + PUT_TOUCH_OFFSET)
	task.wait(0.07)
	rootPart.CFrame = startCFrame
end

RunService.RenderStepped:Connect(function(deltaTime)
	collectElapsed += deltaTime
	if collectElapsed >= COLLECT_INTERVAL then
		collectElapsed = 0
		collectDropsAndMoney()
	end

	depositElapsed += deltaTime
	if depositElapsed >= DEPOSIT_INTERVAL then
		depositElapsed = 0
		depositToTerminal()
	end
end)
