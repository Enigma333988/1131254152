-- Teleport all skill pickups from Workspace.Debris.Skills to the local player.
-- Useful when pickups are physical Parts/Models that are collected on touch/proximity.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LOCAL_PLAYER = Players.LocalPlayer
local ROOT_PATH = { "Debris", "Skills" }
local TELEPORT_INTERVAL = 0.1
local POSITION_OFFSET = Vector3.new(0, 0, -2)

local function getCharacterRootPart()
    local character = LOCAL_PLAYER.Character or LOCAL_PLAYER.CharacterAdded:Wait()
    return character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart")
end

local function findSkillsContainer()
    local current = workspace

    for _, childName in ipairs(ROOT_PATH) do
        current = current:FindFirstChild(childName)
        if not current then
            return nil
        end
    end

    return current
end

local function moveInstanceToCFrame(instance, targetCFrame)
    if instance:IsA("BasePart") then
        instance.CFrame = targetCFrame
        return
    end

    if instance:IsA("Model") then
        if instance.PrimaryPart then
            instance:SetPrimaryPartCFrame(targetCFrame)
            return
        end

        local pivotPart = instance:FindFirstChildWhichIsA("BasePart")
        if pivotPart then
            instance.PrimaryPart = pivotPart
            instance:SetPrimaryPartCFrame(targetCFrame)
        end
    end
end

local function collectSkillsLoop()
    while true do
        local rootPart = getCharacterRootPart()
        local skillsContainer = findSkillsContainer()

        if rootPart and skillsContainer then
            local targetCFrame = rootPart.CFrame + POSITION_OFFSET

            for _, skill in ipairs(skillsContainer:GetChildren()) do
                moveInstanceToCFrame(skill, targetCFrame)
            end
        end

        task.wait(TELEPORT_INTERVAL)
    end
end

if RunService:IsClient() then
    task.spawn(collectSkillsLoop)
end
