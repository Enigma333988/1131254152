-- Teleport to nearest skill (on button click) + ESP for all skills in Workspace.Debris.Skills.

local Players = game:GetService("Players")

local LOCAL_PLAYER = Players.LocalPlayer
local PLAYER_GUI = LOCAL_PLAYER:WaitForChild("PlayerGui")

local ROOT_PATH = { "Debris", "Skills" }

local TELEPORT_OFFSET = Vector3.new(0, 3, 0)
local BUTTON_TEXT = "Телепорт к ближайшему скиллу"

local ESP_HIGHLIGHT_FILL_COLOR = Color3.fromRGB(255, 200, 0)
local ESP_HIGHLIGHT_OUTLINE_COLOR = Color3.fromRGB(255, 255, 255)
local ESP_TEXT_COLOR = Color3.fromRGB(255, 220, 100)

local espRegistry = {}

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
    if not skill then
        return
    end

    local rootPart = getCharacterRootPart()
    local skillPart = getSkillPart(skill)

    if not rootPart or not skillPart then
        return
    end

    rootPart.CFrame = CFrame.new(skillPart.Position + TELEPORT_OFFSET)
end

local function createEspForSkill(skill)
    if espRegistry[skill] then
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

    espRegistry[skill] = true

    skill.Destroying:Connect(function()
        espRegistry[skill] = nil
    end)
end

local function refreshSkillsEsp()
    local skillsContainer = findSkillsContainer()
    if not skillsContainer then
        return
    end

    for _, skill in ipairs(skillsContainer:GetChildren()) do
        createEspForSkill(skill)
    end
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

    local button = Instance.new("TextButton")
    button.Name = "TeleportNearestSkillButton"
    button.Size = UDim2.new(0, 260, 0, 44)
    button.Position = UDim2.new(0.5, -130, 1, -70)
    button.BackgroundColor3 = Color3.fromRGB(36, 36, 36)
    button.BorderSizePixel = 0
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Text = BUTTON_TEXT
    button.TextScaled = true
    button.Font = Enum.Font.GothamBold
    button.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button

    button.MouseButton1Click:Connect(function()
        local nearestSkill = getNearestSkill()
        teleportToSkill(nearestSkill)
    end)
end

createUi()
refreshSkillsEsp()

local skillsContainer = findSkillsContainer()
if skillsContainer then
    skillsContainer.ChildAdded:Connect(function(skill)
        task.defer(function()
            createEspForSkill(skill)
        end)
    end)
end

task.spawn(function()
    while true do
        refreshSkillsEsp()
        task.wait(1)
    end
end)
