--[[
    Roblox LocalScript / executor script
    Aim-assist + local target teleport UI:
      - Select any online player
      - Toggle aim lock on/off
      - Camera will keep looking at selected target's HumanoidRootPart
      - Optional local teleport mode: moves target part in front of your crosshair locally

    Notes:
      - Intended for educational/demo use.
      - Works only on the local client.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

if not localPlayer then
    warn("LocalPlayer not available")
    return
end

local playerGui = localPlayer:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "AimTargetSelector"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = UDim2.fromOffset(300, 250)
frame.Position = UDim2.new(0, 20, 0.5, -125)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BorderSizePixel = 0
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 36)
title.BackgroundTransparency = 1
title.Text = "AIM TARGET"
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Parent = frame

local statusLabel = Instance.new("TextLabel")
statusLabel.Position = UDim2.new(0, 12, 0, 42)
statusLabel.Size = UDim2.new(1, -24, 0, 24)
statusLabel.BackgroundTransparency = 1
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 14
statusLabel.TextColor3 = Color3.fromRGB(190, 190, 190)
statusLabel.Text = "Target: none"
statusLabel.Parent = frame

local scrolling = Instance.new("ScrollingFrame")
scrolling.Name = "PlayerList"
scrolling.Position = UDim2.new(0, 12, 0, 72)
scrolling.Size = UDim2.new(1, -24, 1, -120)
scrolling.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
scrolling.BorderSizePixel = 0
scrolling.CanvasSize = UDim2.fromOffset(0, 0)
scrolling.ScrollBarThickness = 6
scrolling.Parent = frame

local listCorner = Instance.new("UICorner")
listCorner.CornerRadius = UDim.new(0, 6)
listCorner.Parent = scrolling

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
listLayout.Parent = scrolling

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(1, -24, 0, 34)
toggleButton.Position = UDim2.new(0, 12, 1, -82)
toggleButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 14
toggleButton.Text = "Aim: OFF"
toggleButton.AutoButtonColor = true
toggleButton.Parent = frame

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 6)
toggleCorner.Parent = toggleButton

local modeButton = Instance.new("TextButton")
modeButton.Size = UDim2.new(1, -24, 0, 30)
modeButton.Position = UDim2.new(0, 12, 1, -42)
modeButton.BackgroundColor3 = Color3.fromRGB(52, 86, 150)
modeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
modeButton.Font = Enum.Font.Gotham
modeButton.TextSize = 13
modeButton.Text = "Mode: LOOK LOCK"
modeButton.AutoButtonColor = true
modeButton.Parent = frame

local modeCorner = Instance.new("UICorner")
modeCorner.CornerRadius = UDim.new(0, 6)
modeCorner.Parent = modeButton

local selectedPlayer = nil
local aimEnabled = false
local renderConnection = nil
local teleportToCrosshair = false
local teleportDistance = 10
local minSafeDistanceFromPlayer = 6
local lastTargetPart = nil
local lastTargetCFrame = nil

local function getTargetPart(player)
    if not player or not player.Character then
        return nil
    end

    return player.Character:FindFirstChild("HumanoidRootPart")
        or player.Character:FindFirstChild("UpperTorso")
        or player.Character:FindFirstChild("Head")
end

local function getLocalRootPart()
    if not localPlayer.Character then
        return nil
    end

    return localPlayer.Character:FindFirstChild("HumanoidRootPart")
        or localPlayer.Character:FindFirstChild("UpperTorso")
        or localPlayer.Character:FindFirstChild("Head")
end

local function updateStatus()
    local targetName = selectedPlayer and selectedPlayer.Name or "none"
    local state = aimEnabled and "ON" or "OFF"
    local mode = teleportToCrosshair and "TP CROSSHAIR" or "LOOK LOCK"
    statusLabel.Text = string.format("Target: %s | Aim: %s | %s", targetName, state, mode)
    toggleButton.Text = "Aim: " .. state
    toggleButton.BackgroundColor3 = aimEnabled and Color3.fromRGB(44, 140, 72) or Color3.fromRGB(70, 70, 70)
    modeButton.Text = "Mode: " .. mode
    modeButton.BackgroundColor3 = teleportToCrosshair and Color3.fromRGB(143, 64, 45) or Color3.fromRGB(52, 86, 150)
end

local function restoreLastTeleportedPart()
    if lastTargetPart and lastTargetPart.Parent and lastTargetCFrame then
        lastTargetPart.CFrame = lastTargetCFrame
    end
    lastTargetPart = nil
    lastTargetCFrame = nil
end

local function clearButtons()
    for _, child in ipairs(scrolling:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
end

local function createPlayerButton(player)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -8, 0, 28)
    button.BackgroundColor3 = Color3.fromRGB(52, 52, 52)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.Gotham
    button.TextSize = 13
    button.Text = player.DisplayName .. " (@" .. player.Name .. ")"
    button.Parent = scrolling

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 4)
    buttonCorner.Parent = button

    button.MouseButton1Click:Connect(function()
        selectedPlayer = player
        updateStatus()

        for _, child in ipairs(scrolling:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3 = Color3.fromRGB(52, 52, 52)
            end
        end
        button.BackgroundColor3 = Color3.fromRGB(77, 110, 180)
    end)
end

local function refreshPlayerList()
    clearButtons()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            createPlayerButton(player)
        end
    end

    task.wait()
    scrolling.CanvasSize = UDim2.fromOffset(0, listLayout.AbsoluteContentSize.Y + 8)
end

local function startAimLoop()
    if renderConnection then
        return
    end

    renderConnection = RunService.RenderStepped:Connect(function()
        if not aimEnabled then
            return
        end

        local part = getTargetPart(selectedPlayer)
        if not part then
            return
        end

        local camPos = camera.CFrame.Position
        camera.CFrame = CFrame.new(camPos, part.Position)

        if teleportToCrosshair then
            local localRoot = getLocalRootPart()
            local safeDistance = teleportDistance

            if localRoot then
                local cameraToPlayer = (camPos - localRoot.Position).Magnitude
                safeDistance = math.max(safeDistance, cameraToPlayer + minSafeDistanceFromPlayer)
            end

            local targetPos = camPos + (camera.CFrame.LookVector * safeDistance)
            if part ~= lastTargetPart then
                restoreLastTeleportedPart()
                lastTargetPart = part
                lastTargetCFrame = part.CFrame
            end

            part.CFrame = CFrame.new(targetPos, camPos)
            if part:IsA("BasePart") then
                part.AssemblyLinearVelocity = Vector3.zero
                part.AssemblyAngularVelocity = Vector3.zero
            end
        else
            restoreLastTeleportedPart()
        end
    end)
end

local function stopAimLoop()
    if renderConnection then
        renderConnection:Disconnect()
        renderConnection = nil
    end
    restoreLastTeleportedPart()
end

modeButton.MouseButton1Click:Connect(function()
    teleportToCrosshair = not teleportToCrosshair
    if not teleportToCrosshair then
        restoreLastTeleportedPart()
    end
    updateStatus()
end)

toggleButton.MouseButton1Click:Connect(function()
    if not selectedPlayer then
        warn("Select a target player first")
        return
    end

    aimEnabled = not aimEnabled
    if aimEnabled then
        startAimLoop()
    else
        stopAimLoop()
    end
    updateStatus()
end)

Players.PlayerAdded:Connect(refreshPlayerList)
Players.PlayerRemoving:Connect(function(player)
    if selectedPlayer == player then
        selectedPlayer = nil
        aimEnabled = false
        stopAimLoop()
    end
    refreshPlayerList()
    updateStatus()
end)

refreshPlayerList()
updateStatus()
