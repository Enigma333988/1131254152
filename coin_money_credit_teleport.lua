-- Enemy magnet to crosshair (without HumanoidCollider)
-- Targets model root parts first: HumanoidRootPart / PrimaryPart / Head.

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
    DistanceFromCharacter = 16, -- keep enemies farther from your character
    MaxTargetsPerFrame = 100,
    PreferredPartNames = { "HumanoidRootPart", "Head", "Torso", "UpperTorso", "LowerTorso" },
}

local function getEnemiesFolder()
    local gameFolder = Workspace:FindFirstChild("Game")
    if not gameFolder then
        return nil
    end

    return gameFolder:FindFirstChild("Enemies")
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

    -- Face enemies toward the player/camera so they stand "front-first".
    return CFrame.new(targetPos, targetPos - lookVector)
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

    local enemiesFolder = getEnemiesFolder()
    if not enemiesFolder then
        return
    end

    local magnetCF = getMagnetCFrame()
    if not magnetCF then
        return
    end

    local moved = 0

    for _, enemy in ipairs(enemiesFolder:GetChildren()) do
        if moved >= SETTINGS.MaxTargetsPerFrame then
            break
        end

        local targetPart = getTargetPart(enemy)
        if targetPart then
            targetPart.CanCollide = false
            targetPart.AssemblyLinearVelocity = Vector3.zero
            targetPart.AssemblyAngularVelocity = Vector3.zero
            targetPart.CFrame = magnetCF
            moved += 1
        end
    end
end)
