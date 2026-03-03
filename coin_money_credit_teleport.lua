-- Телепортирует головы/корневые части монстров в точку прицела (мыши)
-- Подходит для моделей с "Head" (MeshPart/Part) и/или "HumanoidRootPart"

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local mouse = localPlayer:GetMouse()

local TELEPORT_INTERVAL = 0.15
local HEIGHT_OFFSET = 2

local function getAimPosition()
    if mouse and mouse.Hit then
        return mouse.Hit.Position
    end
    return nil
end

local function isMonsterModel(model)
    if not model:IsA("Model") then
        return false
    end

    -- Исключаем своего персонажа
    if localPlayer.Character and model == localPlayer.Character then
        return false
    end

    -- Простая эвристика: есть "Head" или "HumanoidRootPart"
    return model:FindFirstChild("Head") ~= nil or model:FindFirstChild("HumanoidRootPart") ~= nil
end

local function getTeleportPart(model)
    local head = model:FindFirstChild("Head")
    if head and head:IsA("BasePart") then
        return head
    end

    local root = model:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then
        return root
    end

    return nil
end

local function teleportMonstersToCrosshair()
    local aimPos = getAimPosition()
    if not aimPos then
        return
    end

    for _, instance in ipairs(workspace:GetChildren()) do
        if isMonsterModel(instance) then
            local part = getTeleportPart(instance)
            if part then
                part.CFrame = CFrame.new(aimPos + Vector3.new(0, HEIGHT_OFFSET, 0))
                part.AssemblyLinearVelocity = Vector3.zero
                part.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end
end

while true do
    teleportMonstersToCrosshair()
    task.wait(TELEPORT_INTERVAL)
end
