-- Roblox LocalScript:
-- 1) reliably collect drops/money via player touch teleports
-- 2) deposit in Put.Zone periodically

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LOCAL_PLAYER = Players.LocalPlayer

local MONEY_TOUCH_INTERVAL = 0.2
local DROPS_TOUCH_INTERVAL = 0.35
local DEPOSIT_INTERVAL = 3

local TOUCH_HOLD = 0.035
local ITEM_TOUCH_OFFSET = Vector3.new(0, 2.6, 0)
local PUT_TOUCH_OFFSET = Vector3.new(0, 3, 0)
local MAX_DROPS_PER_CYCLE = 18

local moneyElapsed = 0
local dropsElapsed = 0
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
	return instance:IsA("BasePart") and not instance.Anchored
end

local function touchTarget(rootPart, position, holdTime)
	local startCFrame = rootPart.CFrame
	rootPart.CFrame = CFrame.new(position)
	task.wait(holdTime)
	rootPart.CFrame = startCFrame
end

local function touchMoney()
	local rootPart = getRootPart()
	if not rootPart then
		return
	end

	local money = Workspace:FindFirstChild("Money")
	if not money then
		return
	end

	if money:IsA("BasePart") then
		touchTarget(rootPart, money.Position + ITEM_TOUCH_OFFSET, TOUCH_HOLD)
		return
	end

	for _, part in ipairs(money:GetDescendants()) do
		if isCollectablePart(part) then
			touchTarget(rootPart, part.Position + ITEM_TOUCH_OFFSET, TOUCH_HOLD)
			break
		end
	end
end

local function touchDrops()
	local rootPart = getRootPart()
	if not rootPart then
		return
	end

	local dropsRoot = getDropsRoot()
	if not dropsRoot then
		return
	end

	local touched = 0
	for _, part in ipairs(dropsRoot:GetDescendants()) do
		if touched >= MAX_DROPS_PER_CYCLE then
			break
		end

		if isCollectablePart(part) then
			touchTarget(rootPart, part.Position + ITEM_TOUCH_OFFSET, TOUCH_HOLD)
			touched += 1
		end
	end
end

local function touchPutZone()
	local rootPart = getRootPart()
	if not rootPart then
		return
	end

	local zone = getPutZone()
	if not zone then
		return
	end

	touchTarget(rootPart, zone.Position + PUT_TOUCH_OFFSET, 0.06)
end

RunService.RenderStepped:Connect(function(deltaTime)
	moneyElapsed += deltaTime
	if moneyElapsed >= MONEY_TOUCH_INTERVAL then
		moneyElapsed = 0
		touchMoney()
	end

	dropsElapsed += deltaTime
	if dropsElapsed >= DROPS_TOUCH_INTERVAL then
		dropsElapsed = 0
		touchDrops()
	end

	depositElapsed += deltaTime
	if depositElapsed >= DEPOSIT_INTERVAL then
		depositElapsed = 0
		touchPutZone()
	end
end)
