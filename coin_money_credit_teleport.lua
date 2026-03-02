-- Roblox LocalScript (safe mode):
-- 1) magnet zombie head(s) to crosshair
-- 2) touch Workspace.Money periodically

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LOCAL_PLAYER = Players.LocalPlayer

local CROSSHAIR_DISTANCE = 8
local MONEY_TOUCH_INTERVAL = 3
local MONEY_TOUCH_HOLD = 0.1
local MONEY_OFFSET = Vector3.new(0, 2.5, 0)

local elapsed = 0

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

	return tycoons:FindFirstChild("D")
end

local function gatherZombieHeads()
	local heads = {}
	local tycoonD = findTycoonD()
	if not tycoonD then
		return heads
	end

	local round = tycoonD:FindFirstChild("Round")
	if round then
		local zombie = round:FindFirstChild("Zombie")
		if zombie then
			local head = zombie:FindFirstChild("Head")
			if head and head:IsA("BasePart") then
				table.insert(heads, head)
			end
		end
	end

	for _, descendant in ipairs(tycoonD:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Name == "Head" then
			local parentModel = descendant.Parent
			if parentModel and parentModel:IsA("Model") and parentModel.Name == "Zombie" then
				table.insert(heads, descendant)
			end
		end
	end

	return heads
end

local function magnetHeadsToCrosshair()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end

	local targetCFrame = camera.CFrame + (camera.CFrame.LookVector * CROSSHAIR_DISTANCE)
	for _, head in ipairs(gatherZombieHeads()) do
		if head and head.Parent then
			head.CFrame = targetCFrame
			head.AssemblyLinearVelocity = Vector3.zero
			head.AssemblyAngularVelocity = Vector3.zero
		end
	end
end

local function touchMoneyPart()
	local moneyPart = Workspace:FindFirstChild("Money")
	if not moneyPart or not moneyPart:IsA("BasePart") then
		return
	end

	local rootPart = getRootPart()
	if not rootPart then
		return
	end

	local startCFrame = rootPart.CFrame
	rootPart.CFrame = CFrame.new(moneyPart.Position + MONEY_OFFSET)
	task.wait(MONEY_TOUCH_HOLD)
	rootPart.CFrame = startCFrame
end

RunService.RenderStepped:Connect(function(deltaTime)
	magnetHeadsToCrosshair()

	elapsed += deltaTime
	if elapsed >= MONEY_TOUCH_INTERVAL then
		elapsed = 0
		touchMoneyPart()
	end
end)
