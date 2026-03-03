-- Телепортирует тело (HumanoidRootPart) ближайшего врага
-- Цель ставится в прицел на фиксированной дистанции и разворачивается головой к персонажу

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer

local TELEPORT_INTERVAL = 0.08
local TELEPORT_DISTANCE = 20
local HEIGHT_OFFSET = 1.5

local function getCharacterRootPart()
    local character = localPlayer.Character
    if not character then
        return nil
    end

    local root = character:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then
        return root
    end

    return nil
end

local function isMonsterModel(model)
    if not model:IsA("Model") then
        return false
    end

    if localPlayer.Character and model == localPlayer.Character then
        return false
    end

    local root = model:FindFirstChild("HumanoidRootPart")
    return root ~= nil and root:IsA("BasePart")
end

local function findNearestMonsterRoot()
    local playerRoot = getCharacterRootPart()
    if not playerRoot then
        return nil
    end

    local nearestRoot = nil
    local nearestDistance = math.huge

    for _, instance in ipairs(Workspace:GetChildren()) do
        if isMonsterModel(instance) then
            local monsterRoot = instance:FindFirstChild("HumanoidRootPart")
            if monsterRoot and monsterRoot:IsA("BasePart") then
                local distance = (monsterRoot.Position - playerRoot.Position).Magnitude
                if distance < nearestDistance then
                    nearestDistance = distance
                    nearestRoot = monsterRoot
                end
            end
        end
    end

    return nearestRoot
end

local function getCrosshairTargetPosition()
    local camera = Workspace.CurrentCamera
    if not camera then
        return nil
    end

    local targetPosition = camera.CFrame.Position + (camera.CFrame.LookVector * TELEPORT_DISTANCE)
    return targetPosition + Vector3.new(0, HEIGHT_OFFSET, 0)
end

local function teleportNearestMonsterToCrosshairDistanceFacingPlayer()
    local playerRoot = getCharacterRootPart()
    if not playerRoot then
        return
    end

    local targetPosition = getCrosshairTargetPosition()
    if not targetPosition then
        return
    end

    local nearestMonsterRoot = findNearestMonsterRoot()
    if not nearestMonsterRoot then
        return
    end

    nearestMonsterRoot.CFrame = CFrame.lookAt(targetPosition, playerRoot.Position)
    nearestMonsterRoot.AssemblyLinearVelocity = Vector3.zero
    nearestMonsterRoot.AssemblyAngularVelocity = Vector3.zero
end

while true do
    teleportNearestMonsterToCrosshairDistanceFacingPlayer()
    task.wait(TELEPORT_INTERVAL)
end
