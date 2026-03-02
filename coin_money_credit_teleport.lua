-- Roblox LocalScript:
-- 1) every 10s: pull all Wool drops to player, then touch Put.Zone to deposit
-- 2) continuously: quickly touch Money parts as they appear

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LOCAL_PLAYER = Players.LocalPlayer

local WOOL_CYCLE_INTERVAL = 10
local MONEY_PASS_INTERVAL = 0.05
local MONEY_TOUCH_HOLD = 0.02
local MONEY_BATCH_SIZE = 40

local WOOL_PULL_OFFSET = Vector3.new(0, 2.5, 0)
local ZONE_TOUCH_OFFSET = Vector3.new(0, 3, 0)
local ZONE_TOUCH_HOLD = 0.08

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

local function touchPosition(rootPart, position, hold)
	local startCFrame = rootPart.CFrame
	rootPart.CFrame = CFrame.new(position)
	task.wait(hold)
	rootPart.CFrame = startCFrame
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

	local d = tycoons:FindFirstChild("D")
	if d and d:IsA("Model") then
		return d
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

	local buttonsE = tycoonD:FindFirstChild("Buttons_E")
	if not buttonsE then
		return nil
	end

	local put = buttonsE:FindFirstChild("Put")
	if not put then
		return nil
	end

	local zone = put:FindFirstChild("Zone")
	if zone and zone:IsA("BasePart") then
		return zone
	end

	return nil
end

local function gatherWoolParts()
	local result = {}
	local drops = getDropsRoot()
	if not drops then
		return result
	end

	for _, instance in ipairs(drops:GetDescendants()) do
		if instance:IsA("BasePart") and instance.Name == "Wool" and not instance.Anchored then
			table.insert(result, instance)
		end
	end

	return result
end

local function pullWoolToPlayer()
	local rootPart = getRootPart()
	if not rootPart then
		return
	end

	local target = rootPart.Position + WOOL_PULL_OFFSET
	for _, woolPart in ipairs(gatherWoolParts()) do
		if woolPart and woolPart.Parent then
			woolPart.CFrame = CFrame.new(target)
			woolPart.AssemblyLinearVelocity = Vector3.zero
			woolPart.AssemblyAngularVelocity = Vector3.zero
		end
	end
end

local function depositWoolToTerminal()
	local rootPart = getRootPart()
	if not rootPart then
		return
	end

	local zone = getPutZone()
	if not zone then
		return
	end

	touchPosition(rootPart, zone.Position + ZONE_TOUCH_OFFSET, ZONE_TOUCH_HOLD)
end

local function gatherMoneyParts()
	local found = {}
	local unique = {}

	local rootMoney = Workspace:FindFirstChild("Money")
	if rootMoney then
		if rootMoney:IsA("BasePart") then
			unique[rootMoney] = true
			table.insert(found, rootMoney)
		else
			for _, item in ipairs(rootMoney:GetDescendants()) do
				if item:IsA("BasePart") and item.Name == "Money" then
					if not unique[item] then
						unique[item] = true
						table.insert(found, item)
					end
				end
			end
		end
	end

	for _, item in ipairs(Workspace:GetDescendants()) do
		if item:IsA("BasePart") and item.Name == "Money" and not unique[item] then
			unique[item] = true
			table.insert(found, item)
		end
	end

	return found
end

local function moneyCollectorLoop()
	while true do
		local rootPart = getRootPart()
		if not rootPart then
			task.wait(0.2)
		else
			local touched = 0
			for _, moneyPart in ipairs(gatherMoneyParts()) do
				if not rootPart or not rootPart.Parent then
					break
				end

				if moneyPart and moneyPart.Parent and moneyPart:IsA("BasePart") then
					touchPosition(rootPart, moneyPart.Position + WOOL_PULL_OFFSET, MONEY_TOUCH_HOLD)
					touched += 1
				end

				if touched >= MONEY_BATCH_SIZE then
					break
				end
			end

			task.wait(MONEY_PASS_INTERVAL)
		end
	end
end

local function woolAndDepositLoop()
	while true do
		pullWoolToPlayer()
		depositWoolToTerminal()
		task.wait(WOOL_CYCLE_INTERVAL)
	end
end

task.spawn(moneyCollectorLoop)
task.spawn(woolAndDepositLoop)
