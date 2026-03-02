-- Roblox LocalScript: on LMB snap aim to the nearest visible monster head in FOV.
-- Example monster path: Workspace.Monsters.Stalker.Head
-- Place in StarterPlayerScripts.

local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local CAMERA = Workspace.CurrentCamera
local MONSTERS_FOLDER = Workspace:WaitForChild("Monsters")
local MAX_FOV_RADIUS_PX = 260

local function isAliveMonster(model)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	return humanoid and humanoid.Health > 0
end

local function isVisibleFromCamera(targetPart)
	local origin = CAMERA.CFrame.Position
	local direction = targetPart.Position - origin

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Blacklist
	rayParams.FilterDescendantsInstances = {CAMERA}
	rayParams.IgnoreWater = true

	local result = Workspace:Raycast(origin, direction, rayParams)
	if not result then
		return true
	end

	return result.Instance and result.Instance:IsDescendantOf(targetPart.Parent)
end

local function getClosestHeadInView()
	local viewportCenter = CAMERA.ViewportSize / 2
	local bestHead = nil
	local bestScore = math.huge

	for _, monster in ipairs(MONSTERS_FOLDER:GetChildren()) do
		if monster:IsA("Model") and isAliveMonster(monster) then
			local head = monster:FindFirstChild("Head")
			if head and head:IsA("BasePart") then
				local screenPoint, onScreen = CAMERA:WorldToViewportPoint(head.Position)
				if onScreen and screenPoint.Z > 0 then
					local delta = Vector2.new(screenPoint.X, screenPoint.Y) - viewportCenter
					local score = delta.Magnitude
					if score <= MAX_FOV_RADIUS_PX and score < bestScore and isVisibleFromCamera(head) then
						bestScore = score
						bestHead = head
					end
				end
			end
		end
	end

	return bestHead
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end

	local head = getClosestHeadInView()
	if not head then
		return
	end

	local cameraPosition = CAMERA.CFrame.Position
	CAMERA.CFrame = CFrame.new(cameraPosition, head.Position)
end)
