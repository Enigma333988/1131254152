-- Roblox LocalScript: auto-collects drops/money and deposits wool into terminal with minimal visible teleport.
-- Wool source root: Workspace.Tycoon.Tycoons.D.Drops (all levels)
-- Deposit terminal: Workspace.Tycoon.Tycoons.D.Buttons_E.Put.Zone
-- Money source: Workspace.Money

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LOCAL_PLAYER = Players.LocalPlayer

local TYCOON_ROOT = Workspace:WaitForChild("Tycoon"):WaitForChild("Tycoons"):WaitForChild("D")
local DROPS_ROOT = TYCOON_ROOT:WaitForChild("Drops")
local TERMINAL_ZONE = TYCOON_ROOT:WaitForChild("Buttons_E"):WaitForChild("Put"):WaitForChild("Zone")
local MONEY_ROOT = Workspace:WaitForChild("Money")

local SCAN_INTERVAL = 0.2
local TOUCH_STEP_DELAY = 0.02
local WOOL_NAME = "Wool"

local function getCharacterRoot()
	local character = LOCAL_PLAYER.Character
	if not character then
		return nil
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart or not rootPart:IsA("BasePart") then
		return nil
	end

	return rootPart
end

local function isCollectibleWool(instance)
	return instance:IsA("BasePart")
		and instance.Name == WOOL_NAME
		and not instance.Anchored
		and instance:IsDescendantOf(DROPS_ROOT)
end

local function isCollectibleMoney(instance)
	return instance:IsA("BasePart")
		and not instance.Anchored
		and instance:IsDescendantOf(MONEY_ROOT)
end

local function touchPart(rootPart, targetPart)
	if not targetPart or not targetPart.Parent then
		return
	end

	local fireTouch = firetouchinterest
	if typeof(fireTouch) == "function" then
		fireTouch(rootPart, targetPart, 0)
		fireTouch(rootPart, targetPart, 1)
		task.wait(TOUCH_STEP_DELAY)
		return
	end

	local startCFrame = rootPart.CFrame
	rootPart.CFrame = CFrame.new(targetPart.Position + Vector3.new(0, 2.2, 0))
	task.wait(TOUCH_STEP_DELAY)
	rootPart.CFrame = startCFrame
end

local function findCollectibles(root, predicate)
	local parts = {}
	for _, descendant in ipairs(root:GetDescendants()) do
		if predicate(descendant) then
			table.insert(parts, descendant)
		end
	end
	return parts
end

local function collectAll(rootPart, items)
	for _, item in ipairs(items) do
		if item and item.Parent and item:IsDescendantOf(Workspace) then
			touchPart(rootPart, item)
		end
	end
end

local function collectAndDeposit()
	local rootPart = getCharacterRoot()
	if not rootPart then
		return
	end

	local woolParts = findCollectibles(DROPS_ROOT, isCollectibleWool)
	local moneyParts = findCollectibles(MONEY_ROOT, isCollectibleMoney)

	collectAll(rootPart, woolParts)
	collectAll(rootPart, moneyParts)

	if TERMINAL_ZONE and TERMINAL_ZONE.Parent then
		touchPart(rootPart, TERMINAL_ZONE)
	end
end

while task.wait(SCAN_INTERVAL) do
	collectAndDeposit()
end
