-- Locks camera aim to heads inside a configurable crosshair capture radius while RMB is held.
-- LocalScript only.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local isHoldingLMB = false
local aimAssistEnabled = true

local MIN_RADIUS = 30
local MAX_RADIUS = 350
local captureRadius = 130

local function getCurrentCamera()
    return Workspace.CurrentCamera
end

local function isAlive(character)
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function getCharacter(player)
    if not player then
        return nil
    end

    if player.Character then
        return player.Character
    end

    local playersFolder = Workspace:FindFirstChild("Players")
    if playersFolder then
        return playersFolder:FindFirstChild(player.Name)
    end

    return nil
end

local function getHead(character)
    if not character then
        return nil
    end

    return character:FindFirstChild("Head")
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AimAssistUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = PlayerGui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.new(0, 220, 0, 120)
panel.Position = UDim2.new(0, 20, 0.5, -60)
panel.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
panel.BorderSizePixel = 0
panel.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = panel

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -20, 0, 24)
title.Position = UDim2.new(0, 10, 0, 8)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextColor3 = Color3.fromRGB(235, 235, 235)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "Aim Assist"
title.Parent = panel

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(1, -20, 0, 28)
toggleButton.Position = UDim2.new(0, 10, 0, 36)
toggleButton.BackgroundColor3 = Color3.fromRGB(30, 150, 65)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 13
toggleButton.Text = "ВКЛ"
toggleButton.Parent = panel

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 6)
toggleCorner.Parent = toggleButton

local radiusLabel = Instance.new("TextLabel")
radiusLabel.BackgroundTransparency = 1
radiusLabel.Size = UDim2.new(1, -20, 0, 20)
radiusLabel.Position = UDim2.new(0, 10, 0, 70)
radiusLabel.Font = Enum.Font.Gotham
radiusLabel.TextSize = 13
radiusLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
radiusLabel.TextXAlignment = Enum.TextXAlignment.Left
radiusLabel.Parent = panel

local sliderBar = Instance.new("Frame")
sliderBar.Size = UDim2.new(1, -20, 0, 10)
sliderBar.Position = UDim2.new(0, 10, 0, 95)
sliderBar.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
sliderBar.BorderSizePixel = 0
sliderBar.Parent = panel

local sliderBarCorner = Instance.new("UICorner")
sliderBarCorner.CornerRadius = UDim.new(1, 0)
sliderBarCorner.Parent = sliderBar

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(0, 0, 1, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(85, 170, 255)
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderBar

local sliderFillCorner = Instance.new("UICorner")
sliderFillCorner.CornerRadius = UDim.new(1, 0)
sliderFillCorner.Parent = sliderFill

local sliderKnob = Instance.new("Frame")
sliderKnob.Size = UDim2.new(0, 14, 0, 14)
sliderKnob.AnchorPoint = Vector2.new(0.5, 0.5)
sliderKnob.Position = UDim2.new(0, 0, 0.5, 0)
sliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sliderKnob.BorderSizePixel = 0
sliderKnob.Parent = sliderBar

local sliderKnobCorner = Instance.new("UICorner")
sliderKnobCorner.CornerRadius = UDim.new(1, 0)
sliderKnobCorner.Parent = sliderKnob

local captureCircle = Instance.new("Frame")
captureCircle.Name = "CaptureCircle"
captureCircle.AnchorPoint = Vector2.new(0.5, 0.5)
captureCircle.BackgroundTransparency = 0.65
captureCircle.BackgroundColor3 = Color3.fromRGB(80, 170, 255)
captureCircle.BorderSizePixel = 0
captureCircle.Parent = screenGui

local captureCircleCorner = Instance.new("UICorner")
captureCircleCorner.CornerRadius = UDim.new(1, 0)
captureCircleCorner.Parent = captureCircle

local captureCircleStroke = Instance.new("UIStroke")
captureCircleStroke.Color = Color3.fromRGB(170, 220, 255)
captureCircleStroke.Thickness = 2
captureCircleStroke.Transparency = 0.15
captureCircleStroke.Parent = captureCircle

local function updateToggleUI()
    if aimAssistEnabled then
        toggleButton.Text = "ВКЛ"
        toggleButton.BackgroundColor3 = Color3.fromRGB(30, 150, 65)
        captureCircle.Visible = true
    else
        toggleButton.Text = "ВЫКЛ"
        toggleButton.BackgroundColor3 = Color3.fromRGB(160, 45, 45)
        captureCircle.Visible = false
    end
end

local function updateRadiusUI()
    local alpha = (captureRadius - MIN_RADIUS) / (MAX_RADIUS - MIN_RADIUS)
    sliderFill.Size = UDim2.new(alpha, 0, 1, 0)
    sliderKnob.Position = UDim2.new(alpha, 0, 0.5, 0)
    radiusLabel.Text = string.format("Радиус захвата: %d", captureRadius)

    local camera = getCurrentCamera()
    if camera then
        local center = Vector2.new(camera.ViewportSize.X * 0.5, camera.ViewportSize.Y * 0.5)
        local diameter = captureRadius * 2
        captureCircle.Size = UDim2.fromOffset(diameter, diameter)
        captureCircle.Position = UDim2.fromOffset(center.X, center.Y)
    end
end

local function setRadiusFromPixel(pixelX)
    local relative = math.clamp((pixelX - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
    captureRadius = math.floor(MIN_RADIUS + (MAX_RADIUS - MIN_RADIUS) * relative + 0.5)
    updateRadiusUI()
end

local draggingSlider = false

sliderBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingSlider = true
        setRadiusFromPixel(input.Position.X)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingSlider = false
    end

    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        isHoldingLMB = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
        setRadiusFromPixel(input.Position.X)
    end
end)

toggleButton.MouseButton1Click:Connect(function()
    aimAssistEnabled = not aimAssistEnabled
    updateToggleUI()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        isHoldingLMB = true
    end
end)

local function getClosestHeadInCircle()
    local camera = getCurrentCamera()
    local myCharacter = getCharacter(LocalPlayer)

    if not camera or not myCharacter or not isAlive(myCharacter) then
        return nil
    end

    local viewportSize = camera.ViewportSize
    local crosshair = Vector2.new(viewportSize.X * 0.5, viewportSize.Y * 0.5)

    local nearestHead = nil
    local nearestScreenDistance = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = getCharacter(player)
            local head = getHead(character)

            if head and isAlive(character) then
                local headScreenPoint, isOnScreen = camera:WorldToViewportPoint(head.Position)

                if isOnScreen and headScreenPoint.Z > 0 then
                    local headPoint2D = Vector2.new(headScreenPoint.X, headScreenPoint.Y)
                    local screenDistance = (headPoint2D - crosshair).Magnitude

                    if screenDistance <= captureRadius and screenDistance < nearestScreenDistance then
                        nearestScreenDistance = screenDistance
                        nearestHead = head
                    end
                end
            end
        end
    end

    return nearestHead
end

updateToggleUI()
updateRadiusUI()

RunService.RenderStepped:Connect(function()
    updateRadiusUI()

    if not aimAssistEnabled or not isHoldingLMB then
        return
    end

    local camera = getCurrentCamera()
    if not camera then
        return
    end

    local targetHead = getClosestHeadInCircle()
    if not targetHead then
        return
    end

    local cameraPosition = camera.CFrame.Position
    camera.CFrame = CFrame.new(cameraPosition, targetHead.Position)
end)
