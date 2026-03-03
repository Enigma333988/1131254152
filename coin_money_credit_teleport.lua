-- Enemy magnet to crosshair (without HumanoidCollider)
-- Targets model root parts first: HumanoidRootPart / PrimaryPart / Head.

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local camera = Workspace.CurrentCamera

local SETTINGS = {
    Enabled = true,
    DistanceFromCamera = 8, -- studs in front of crosshair
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

    local targetPos = camera.CFrame.Position + (camera.CFrame.LookVector * SETTINGS.DistanceFromCamera)
    return CFrame.new(targetPos, targetPos + camera.CFrame.LookVector)
end

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
