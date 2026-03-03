-- Enemy magnet to crosshair (without HumanoidCollider)
-- Targets enemy root parts and loot sacks.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local SETTINGS = {
    Enabled = true,
    ToggleKey = Enum.KeyCode.T,
    DistanceFromCamera = 8, -- studs in front of crosshair
    DistanceFromCharacter = 21, -- keep targets farther from your character
    MaxTargetsPerFrame = 100,
    MaxLootPerFrame = 100,
    PreferredPartNames = { "HumanoidRootPart", "Head", "Torso", "UpperTorso", "LowerTorso" },
    LootSackName = "Meshes/LootsackLP",
}

local function getGameFolder()
    return Workspace:FindFirstChild("Game")
end

local function getEnemiesFolder()
    local gameFolder = getGameFolder()
    if not gameFolder then
        return nil
    end

    return gameFolder:FindFirstChild("Enemies")
end

local function getDebrisFolder()
    local gameFolder = getGameFolder()
    if not gameFolder then
        return nil
    end

    return gameFolder:FindFirstChild("Debris")
end

local function getCharacterRootPart()
    local character = LocalPlayer and LocalPlayer.Character
    if not character then
        return nil
    end

    local root = character:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then
        return root
    end

    return nil
end

local function getTargetPart(enemyModel)
    if not enemyModel or not enemyModel:IsA("Model") then
        return nil
    end

    for _, partName in ipairs(SETTINGS.PreferredPartNames) do
        local part = enemyModel:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            return part
        end
    end

    if enemyModel.PrimaryPart and enemyModel.PrimaryPart:IsA("BasePart") then
        return enemyModel.PrimaryPart
    end

    return enemyModel:FindFirstChildWhichIsA("BasePart")
end

local function getMagnetCFrame()
    if not camera then
        camera = Workspace.CurrentCamera
    end

    if not camera then
        return nil
    end

    local lookVector = camera.CFrame.LookVector
    local camTarget = camera.CFrame.Position + (lookVector * SETTINGS.DistanceFromCamera)

    local rootPart = getCharacterRootPart()
    local targetPos = camTarget

    if rootPart then
        local charTarget = rootPart.Position + (lookVector * SETTINGS.DistanceFromCharacter)
        targetPos = charTarget
    end

    -- Face targets toward the player/camera so they stand "front-first".
    return CFrame.new(targetPos, targetPos - lookVector)
end

local function movePartToMagnet(part, magnetCF)
    if not part or not part:IsA("BasePart") then
        return false
    end

    part.CanCollide = false
    part.AssemblyLinearVelocity = Vector3.zero
    part.AssemblyAngularVelocity = Vector3.zero
    part.CFrame = magnetCF

    return true
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then
        return
    end

    if input.KeyCode == SETTINGS.ToggleKey then
        SETTINGS.Enabled = not SETTINGS.Enabled
        print(string.format("[enemy-magnet] %s", SETTINGS.Enabled and "ENABLED" or "DISABLED"))
    end
end)

RunService.RenderStepped:Connect(function()
    if not SETTINGS.Enabled then
        return
    end

    local magnetCF = getMagnetCFrame()
    if not magnetCF then
        return
    end

    local enemiesFolder = getEnemiesFolder()
    if enemiesFolder then
        local movedTargets = 0

        for _, enemy in ipairs(enemiesFolder:GetChildren()) do
            if movedTargets >= SETTINGS.MaxTargetsPerFrame then
                break
            end

            local targetPart = getTargetPart(enemy)
            if movePartToMagnet(targetPart, magnetCF) then
                movedTargets += 1
            end
        end
    end

    local debrisFolder = getDebrisFolder()
    if debrisFolder then
        local movedLoot = 0

        for _, instance in ipairs(debrisFolder:GetDescendants()) do
            if movedLoot >= SETTINGS.MaxLootPerFrame then
                break
            end

            if instance:IsA("MeshPart") and instance.Name == SETTINGS.LootSackName then
                if movePartToMagnet(instance, magnetCF) then
                    movedLoot += 1
                end
            end
        end
    end
end)
