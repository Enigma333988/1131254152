-- Roblox LocalScript: pulls drops/money to player, then teleports player to terminal every 3 seconds.
-- Sources:
--   - Workspace.Tycoon.Tycoons.D.Drops
--   - Workspace.Money
-- Deposit terminal:
--   - Workspace.Tycoon.Tycoons.D.Buttons_E.Put.Zone

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LOCAL_PLAYER = Players.LocalPlayer

local TYCOON_ROOT = Workspace:WaitForChild("Tycoon"):WaitForChild("Tycoons"):WaitForChild("D")
local DROPS_ROOT = TYCOON_ROOT:WaitForChild("Drops")
local TERMINAL_ZONE = TYCOON_ROOT:WaitForChild("Buttons_E"):WaitForChild("Put"):WaitForChild("Zone")
local MONEY_ROOT = Workspace:WaitForChild("Money")

local CYCLE_INTERVAL = 3
local PULL_RADIUS = 4
local PLAYER_OFFSET = Vector3.new(0, 2.5, 0)
local HOLD_DELAY = 0.08

local function getRootPart()
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

local function collectTouchParts(root)
	local parts = {}
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("BasePart") and not descendant.Anchored and descendant.Transparency < 1 then
			table.insert(parts, descendant)
		end
	end
	return parts
end

local function pullPartToPlayer(part, playerPosition)
	if not part or not part.Parent or part.Anchored then
		return
	end

	local offset = Vector3.new(
		(math.random() - 0.5) * PULL_RADIUS,
		0.4,
		(math.random() - 0.5) * PULL_RADIUS
	)
	part.CFrame = CFrame.new(playerPosition + offset)
	part.AssemblyLinearVelocity = Vector3.zero
	part.AssemblyAngularVelocity = Vector3.zero
end

local function touchPartByTeleport(rootPart, part)
	if not part or not part.Parent then
		return
	end

	rootPart.CFrame = CFrame.new(part.Position + PLAYER_OFFSET)
	task.wait(HOLD_DELAY)
end

local function runCycle()
	local rootPart = getRootPart()
	if not rootPart then
		return
	end

	local startCFrame = rootPart.CFrame
	local playerPosition = rootPart.Position

	local dropParts = collectTouchParts(DROPS_ROOT)
	local moneyParts = collectTouchParts(MONEY_ROOT)

	for _, part in ipairs(dropParts) do
		pullPartToPlayer(part, playerPosition)
	end

	for _, part in ipairs(moneyParts) do
		pullPartToPlayer(part, playerPosition)
	end

	-- Fallback for money that does not get collected by pull-only behavior.
	for _, part in ipairs(moneyParts) do
		if part and part.Parent and part:IsDescendantOf(Workspace) then
			touchPartByTeleport(rootPart, part)
		end
	end

	touchPartByTeleport(rootPart, TERMINAL_ZONE)
	rootPart.CFrame = startCFrame
end

while task.wait(CYCLE_INTERVAL) do
	runCycle()
end
