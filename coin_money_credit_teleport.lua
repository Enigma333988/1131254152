-- Телепортирует только тело (HumanoidRootPart) самого близкого врага в точку прицела
-- Каждый тик пересчитывает ближайшую цель к вашему персонажу

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local mouse = localPlayer:GetMouse()

local TELEPORT_INTERVAL = 0.08
local HEIGHT_OFFSET = 1.5

local function getAimPosition()
    if mouse and mouse.Hit then
        return mouse.Hit.Position
    end
    return nil
end

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

    for _, instance in ipairs(workspace:GetChildren()) do
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

local function teleportNearestMonsterToCrosshair()
    local aimPos = getAimPosition()
    if not aimPos then
        return
    end

    local nearestMonsterRoot = findNearestMonsterRoot()
    if not nearestMonsterRoot then
        return
    end

    nearestMonsterRoot.CFrame = CFrame.new(aimPos + Vector3.new(0, HEIGHT_OFFSET, 0))
    nearestMonsterRoot.AssemblyLinearVelocity = Vector3.zero
    nearestMonsterRoot.AssemblyAngularVelocity = Vector3.zero
end

while true do
    teleportNearestMonsterToCrosshair()
    task.wait(TELEPORT_INTERVAL)
end
