-- Roblox LocalScript: auto-collects physical drops/money and deposits at terminal.
-- Sources:
--   - Workspace.Tycoon.Tycoons.D.Drops (all levels, all physical collectible parts)
--   - Workspace.Money (all physical collectible parts)
-- Deposit terminal:
--   - Workspace.Tycoon.Tycoons.D.Buttons_E.Put.Zone

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LOCAL_PLAYER = Players.LocalPlayer

local TYCOON_ROOT = Workspace:WaitForChild("Tycoon"):WaitForChild("Tycoons"):WaitForChild("D")
local DROPS_ROOT = TYCOON_ROOT:WaitForChild("Drops")
local TERMINAL_ZONE = TYCOON_ROOT:WaitForChild("Buttons_E"):WaitForChild("Put"):WaitForChild("Zone")
local MONEY_ROOT = Workspace:WaitForChild("Money")

local SCAN_INTERVAL = 0.2
local TOUCH_OFFSET = Vector3.new(0, 2.2, 0)
local TOUCH_HOLD = 0.09

local function getCharacterAndRoot()
	local character = LOCAL_PLAYER.Character
	if not character then
		return nil, nil
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart or not rootPart:IsA("BasePart") then
		return nil, nil
	end

	return character, rootPart
end

local function isPhysicalCollectible(part)
	if not part:IsA("BasePart") then
		return false
	end

	if part.Anchored then
		return false
	end

	if part.Transparency >= 1 then
		return false
	end

	return true
end

local function findCollectibleParts(root)
	local items = {}
	for _, descendant in ipairs(root:GetDescendants()) do
		if isPhysicalCollectible(descendant) then
			table.insert(items, descendant)
		end
	end
	return items
end

local function touchByTeleport(rootPart, targetPart)
	if not targetPart or not targetPart.Parent then
		return
	end

	rootPart.CFrame = CFrame.new(targetPart.Position + TOUCH_OFFSET)
	task.wait(TOUCH_HOLD)
end

local function collectList(rootPart, list)
	for _, part in ipairs(list) do
		if part and part.Parent and part:IsDescendantOf(Workspace) then
			touchByTeleport(rootPart, part)
		end
	end
end

local function collectAndDeposit()
	local _, rootPart = getCharacterAndRoot()
	if not rootPart then
		return
	end

	local startCFrame = rootPart.CFrame

	local dropParts = findCollectibleParts(DROPS_ROOT)
	local moneyParts = findCollectibleParts(MONEY_ROOT)

	collectList(rootPart, dropParts)
	collectList(rootPart, moneyParts)

	touchByTeleport(rootPart, TERMINAL_ZONE)
	rootPart.CFrame = startCFrame
end

while task.wait(SCAN_INTERVAL) do
	collectAndDeposit()
end
