-- Roblox LocalScript:
-- 1) magnet zombie head to crosshair (local visual assist)
--    Path: Workspace.Tycoon.Tycoons.D.Round.Zombie.Head
-- 2) periodically touch Workspace.Money part to trigger its MoneyScript

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LOCAL_PLAYER = Players.LocalPlayer

local TYCOON_D = Workspace:WaitForChild("Tycoon"):WaitForChild("Tycoons"):WaitForChild("D")
local ZOMBIE_HEAD = TYCOON_D:WaitForChild("Round"):WaitForChild("Zombie"):WaitForChild("Head")
local MONEY_PART = Workspace:WaitForChild("Money")

local CROSSHAIR_DISTANCE = 8
local MONEY_TOUCH_INTERVAL = 3
local MONEY_TOUCH_HOLD = 0.08

local elapsed = 0

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

local function magnetZombieHeadToCrosshair()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end

	if not ZOMBIE_HEAD or not ZOMBIE_HEAD:IsA("BasePart") or not ZOMBIE_HEAD.Parent then
		return
	end

	local targetPosition = camera.CFrame.Position + (camera.CFrame.LookVector * CROSSHAIR_DISTANCE)
	ZOMBIE_HEAD.CFrame = CFrame.new(targetPosition)
	ZOMBIE_HEAD.AssemblyLinearVelocity = Vector3.zero
	ZOMBIE_HEAD.AssemblyAngularVelocity = Vector3.zero
end

local function touchMoneyPart()
	if not MONEY_PART or not MONEY_PART:IsA("BasePart") or not MONEY_PART.Parent then
		return
	end

	local rootPart = getRootPart()
	if not rootPart then
		return
	end

	local startCFrame = rootPart.CFrame
	rootPart.CFrame = CFrame.new(MONEY_PART.Position + Vector3.new(0, 2.5, 0))
	task.wait(MONEY_TOUCH_HOLD)
	rootPart.CFrame = startCFrame
end

RunService.RenderStepped:Connect(function(deltaTime)
	magnetZombieHeadToCrosshair()

	elapsed += deltaTime
	if elapsed >= MONEY_TOUCH_INTERVAL then
		elapsed = 0
		touchMoneyPart()
	end
end)
