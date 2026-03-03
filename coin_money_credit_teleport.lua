-- Enemy magnet to crosshair (HumanoidCollider)
-- Target path example:
-- Workspace.Game.Enemies.Enemy_UndeadKappa.HumanoidCollider

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local SETTINGS = {
    Enabled = true,
    DistanceFromCamera = 8, -- studs in front of crosshair
    MaxTargetsPerFrame = 100,
}

local function getEnemiesFolder()
    local gameFolder = Workspace:FindFirstChild("Game")
    if not gameFolder then
        return nil
    end

    return gameFolder:FindFirstChild("Enemies")
end

local function getCollider(enemyModel)
    if not enemyModel or not enemyModel:IsA("Model") then
        return nil
    end

    local collider = enemyModel:FindFirstChild("HumanoidCollider")
    if collider and collider:IsA("BasePart") then
        return collider
    end

    return nil
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

        local collider = getCollider(enemy)
        if collider then
            collider.CanCollide = false
            collider.AssemblyLinearVelocity = Vector3.zero
            collider.AssemblyAngularVelocity = Vector3.zero
            collider.CFrame = magnetCF
            moved += 1
        end
    end
end)
