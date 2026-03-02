-- Roblox LocalScript: auto-collects all dropped wool balls and deposits them into terminal.
-- Collect source root: Workspace.Tycoon.Tycoons.D.Drops (all levels)
-- Deposit terminal: Workspace.Tycoon.Tycoons.D.Buttons_E.Put.Zone

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LOCAL_PLAYER = Players.LocalPlayer

local TYCOON_ROOT = Workspace:WaitForChild("Tycoon"):WaitForChild("Tycoons"):WaitForChild("D")
local DROPS_ROOT = TYCOON_ROOT:WaitForChild("Drops")
local TERMINAL_ZONE = TYCOON_ROOT:WaitForChild("Buttons_E"):WaitForChild("Put"):WaitForChild("Zone")

local SCAN_INTERVAL = 0.2
local TOUCH_STEP_DELAY = 0.03
local BALL_NAME = "Wool"

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

local function isCollectibleBall(instance)
	if not instance:IsA("BasePart") then
		return false
	end

	if instance.Name ~= BALL_NAME then
		return false
	end

	if instance.Anchored then
		return false
	end

	if not instance:IsDescendantOf(DROPS_ROOT) then
		return false
	end

	return true
end

local function findAllBalls()
	local balls = {}
	for _, descendant in ipairs(DROPS_ROOT:GetDescendants()) do
		if isCollectibleBall(descendant) then
			table.insert(balls, descendant)
		end
	end
	return balls
end

local function touchPosition(rootPart, position)
	rootPart.CFrame = CFrame.new(position + Vector3.new(0, 2.2, 0))
	task.wait(TOUCH_STEP_DELAY)
end

local function collectAndDeposit()
	local rootPart = getCharacterRoot()
	if not rootPart then
		return
	end

	local startCFrame = rootPart.CFrame
	local balls = findAllBalls()

	for _, ball in ipairs(balls) do
		if ball.Parent and ball:IsDescendantOf(Workspace) then
			touchPosition(rootPart, ball.Position)
		end
	end

	touchPosition(rootPart, TERMINAL_ZONE.Position)
	rootPart.CFrame = startCFrame
end

while task.wait(SCAN_INTERVAL) do
	collectAndDeposit()
end
