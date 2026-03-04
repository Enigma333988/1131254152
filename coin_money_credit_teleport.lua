-- Skill helper UI:
-- 1) Teleport to nearest skill (button)
-- 2) ESP for skills in Workspace.Debris.Skills
-- 3) Draggable window with character speed slider
-- 4) Close button fully disables script features

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LOCAL_PLAYER = Players.LocalPlayer
local PLAYER_GUI = LOCAL_PLAYER:WaitForChild("PlayerGui")

local ROOT_PATH = { "Debris", "Skills" }

local TELEPORT_HEIGHT = 25
local BUTTON_TEXT = "Телепорт к ближайшему скиллу"

local SPEED_MIN = 16
local SPEED_MAX = 100
local DEFAULT_SPEED = 16

local ESP_HIGHLIGHT_FILL_COLOR = Color3.fromRGB(255, 200, 0)
local ESP_HIGHLIGHT_OUTLINE_COLOR = Color3.fromRGB(255, 255, 255)
local ESP_TEXT_COLOR = Color3.fromRGB(255, 220, 100)

local scriptEnabled = true
local espRegistry = {}
local connections = {}

local function trackConnection(connection)
    table.insert(connections, connection)
    return connection
end

local function getCharacter()
    return LOCAL_PLAYER.Character or LOCAL_PLAYER.CharacterAdded:Wait()
end

local function getCharacterRootPart()
    local character = getCharacter()
    return character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart")
end

local function getHumanoid()
    local character = getCharacter()
    return character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid")
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

local function getSkillPart(skill)
    if skill:IsA("BasePart") then
        return skill
    end

    if skill:IsA("Model") then
        if skill.PrimaryPart then
            return skill.PrimaryPart
        end

        return skill:FindFirstChildWhichIsA("BasePart")
    end

    return nil
end

local function getNearestSkill()
    local rootPart = getCharacterRootPart()
    local skillsContainer = findSkillsContainer()

    if not rootPart or not skillsContainer then
        return nil
    end

    local nearestSkill = nil
    local nearestDistance = math.huge

    for _, skill in ipairs(skillsContainer:GetChildren()) do
        local skillPart = getSkillPart(skill)
        if skillPart then
            local distance = (skillPart.Position - rootPart.Position).Magnitude
            if distance < nearestDistance then
                nearestDistance = distance
                nearestSkill = skill
            end
        end
    end

    return nearestSkill
end

local function teleportToSkill(skill)
    if not scriptEnabled or not skill then
        return
    end

    local rootPart = getCharacterRootPart()
    local skillPart = getSkillPart(skill)

    if not rootPart or not skillPart then
        return
    end

    rootPart.CFrame = CFrame.new(skillPart.Position + Vector3.new(0, TELEPORT_HEIGHT, 0))
end

local function clearEspForSkill(skill)
    local espData = espRegistry[skill]
    if not espData then
        return
    end

    if espData.highlight and espData.highlight.Parent then
        espData.highlight:Destroy()
    end

    if espData.billboard and espData.billboard.Parent then
        espData.billboard:Destroy()
    end

    espRegistry[skill] = nil
end

local function clearAllEsp()
    for skill, _ in pairs(espRegistry) do
        clearEspForSkill(skill)
    end
end

local function createEspForSkill(skill)
    if not scriptEnabled or espRegistry[skill] then
        return
    end

    local adornee = getSkillPart(skill)
    if not adornee then
        return
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "SkillESPHighlight"
    highlight.FillColor = ESP_HIGHLIGHT_FILL_COLOR
    highlight.FillTransparency = 0.4
    highlight.OutlineColor = ESP_HIGHLIGHT_OUTLINE_COLOR
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = skill
    highlight.Parent = skill

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "SkillESPLabel"
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.Size = UDim2.new(0, 140, 0, 32)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.Adornee = adornee
    billboard.Parent = skill

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 1, 0)
    label.Font = Enum.Font.GothamBold
    label.Text = "SKILL"
    label.TextColor3 = ESP_TEXT_COLOR
    label.TextStrokeTransparency = 0.2
    label.TextScaled = true
    label.Parent = billboard

    espRegistry[skill] = {
        highlight = highlight,
        billboard = billboard,
    }

    trackConnection(skill.Destroying:Connect(function()
        espRegistry[skill] = nil
    end))
end

local function refreshSkillsEsp()
    if not scriptEnabled then
        return
    end

    local skillsContainer = findSkillsContainer()
    if not skillsContainer then
        return
    end

    for _, skill in ipairs(skillsContainer:GetChildren()) do
        createEspForSkill(skill)
    end
end

local function makeFrameDraggable(dragHandle, frame)
    local dragging = false
    local dragInput
    local dragStart
    local startPos

    trackConnection(dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            trackConnection(input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end))
        end
    end))

    trackConnection(dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end))

    trackConnection(UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end))
end

local function createUi()
    local existingGui = PLAYER_GUI:FindFirstChild("SkillTeleportUI")
    if existingGui then
        existingGui:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SkillTeleportUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = PLAYER_GUI

    local window = Instance.new("Frame")
    window.Name = "Window"
    window.Size = UDim2.new(0, 360, 0, 210)
    window.Position = UDim2.new(0.5, -180, 0.5, -105)
    window.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    window.BorderSizePixel = 0
    window.Parent = screenGui

    local windowCorner = Instance.new("UICorner")
    windowCorner.CornerRadius = UDim.new(0, 10)
    windowCorner.Parent = window

    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 34)
    titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = window

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, -50, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.Font = Enum.Font.GothamBold
    title.Text = "Skill Helper"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar

    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 34, 0, 24)
    closeButton.Position = UDim2.new(1, -40, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 14
    closeButton.Parent = titleBar

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeButton

    local teleportButton = Instance.new("TextButton")
    teleportButton.Name = "TeleportNearestSkillButton"
    teleportButton.Size = UDim2.new(1, -20, 0, 42)
    teleportButton.Position = UDim2.new(0, 10, 0, 50)
    teleportButton.BackgroundColor3 = Color3.fromRGB(36, 84, 42)
    teleportButton.BorderSizePixel = 0
    teleportButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    teleportButton.Text = BUTTON_TEXT
    teleportButton.TextScaled = true
    teleportButton.Font = Enum.Font.GothamBold
    teleportButton.Parent = window

    local teleportCorner = Instance.new("UICorner")
    teleportCorner.CornerRadius = UDim.new(0, 8)
    teleportCorner.Parent = teleportButton

    local speedLabel = Instance.new("TextLabel")
    speedLabel.Name = "SpeedLabel"
    speedLabel.BackgroundTransparency = 1
    speedLabel.Size = UDim2.new(1, -20, 0, 24)
    speedLabel.Position = UDim2.new(0, 10, 0, 104)
    speedLabel.Font = Enum.Font.Gotham
    speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    speedLabel.TextXAlignment = Enum.TextXAlignment.Left
    speedLabel.TextSize = 14
    speedLabel.Parent = window

    local sliderBar = Instance.new("Frame")
    sliderBar.Name = "SpeedSliderBar"
    sliderBar.Size = UDim2.new(1, -20, 0, 8)
    sliderBar.Position = UDim2.new(0, 10, 0, 138)
    sliderBar.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    sliderBar.BorderSizePixel = 0
    sliderBar.Parent = window

    local sliderBarCorner = Instance.new("UICorner")
    sliderBarCorner.CornerRadius = UDim.new(0, 4)
    sliderBarCorner.Parent = sliderBar

    local sliderFill = Instance.new("Frame")
    sliderFill.Name = "Fill"
    sliderFill.Size = UDim2.new(0, 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(90, 170, 255)
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBar

    local sliderFillCorner = Instance.new("UICorner")
    sliderFillCorner.CornerRadius = UDim.new(0, 4)
    sliderFillCorner.Parent = sliderFill

    local sliderKnob = Instance.new("TextButton")
    sliderKnob.Name = "Knob"
    sliderKnob.Size = UDim2.new(0, 16, 0, 16)
    sliderKnob.Position = UDim2.new(0, -8, 0.5, -8)
    sliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sliderKnob.Text = ""
    sliderKnob.AutoButtonColor = false
    sliderKnob.BorderSizePixel = 0
    sliderKnob.Parent = sliderBar

    local sliderKnobCorner = Instance.new("UICorner")
    sliderKnobCorner.CornerRadius = UDim.new(1, 0)
    sliderKnobCorner.Parent = sliderKnob

    local draggingSlider = false

    local function applySpeedFromRatio(ratio)
        ratio = math.clamp(ratio, 0, 1)
        local speed = math.floor(SPEED_MIN + (SPEED_MAX - SPEED_MIN) * ratio + 0.5)

        local humanoid = getHumanoid()
        if humanoid then
            humanoid.WalkSpeed = speed
        end

        speedLabel.Text = string.format("Скорость: %d", speed)
        sliderFill.Size = UDim2.new(ratio, 0, 1, 0)
        sliderKnob.Position = UDim2.new(ratio, -8, 0.5, -8)
    end

    local function updateSliderFromInput(input)
        local relativeX = input.Position.X - sliderBar.AbsolutePosition.X
        local ratio = relativeX / sliderBar.AbsoluteSize.X
        applySpeedFromRatio(ratio)
    end

    applySpeedFromRatio((DEFAULT_SPEED - SPEED_MIN) / (SPEED_MAX - SPEED_MIN))

    trackConnection(sliderBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSlider = true
            updateSliderFromInput(input)
        end
    end))

    trackConnection(sliderKnob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSlider = true
        end
    end))

    trackConnection(UserInputService.InputChanged:Connect(function(input)
        if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSliderFromInput(input)
        end
    end))

    trackConnection(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSlider = false
        end
    end))

    trackConnection(teleportButton.MouseButton1Click:Connect(function()
        if not scriptEnabled then
            return
        end

        local nearestSkill = getNearestSkill()
        teleportToSkill(nearestSkill)
    end))

    trackConnection(closeButton.MouseButton1Click:Connect(function()
        if not scriptEnabled then
            return
        end

        scriptEnabled = false
        clearAllEsp()

        for _, connection in ipairs(connections) do
            if connection.Connected then
                connection:Disconnect()
            end
        end

        local humanoid = getHumanoid()
        if humanoid then
            humanoid.WalkSpeed = DEFAULT_SPEED
        end

        screenGui:Destroy()
    end))

    makeFrameDraggable(titleBar, window)
end

createUi()
refreshSkillsEsp()

local skillsContainer = findSkillsContainer()
if skillsContainer then
    trackConnection(skillsContainer.ChildAdded:Connect(function(skill)
        task.defer(function()
            createEspForSkill(skill)
        end)
    end))
end

task.spawn(function()
    while scriptEnabled do
        refreshSkillsEsp()
        task.wait(1)
    end
end)
