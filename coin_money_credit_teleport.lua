-- Подсветка "правильных" стёкол в Workspace.
-- Ключевое условие: НЕ подсвечивать детали с GlassDamageScript.

local Workspace = game:GetService("Workspace")

local HIGHLIGHT_COLOR = Color3.fromRGB(0, 255, 130)
local HIGHLIGHT_FILL_TRANSPARENCY = 0.45
local HIGHLIGHT_OUTLINE_TRANSPARENCY = 0

local highlightFolder = Workspace:FindFirstChild("GlassHighlights")
if not highlightFolder then
    highlightFolder = Instance.new("Folder")
    highlightFolder.Name = "GlassHighlights"
    highlightFolder.Parent = Workspace
end

local function hasChildOfType(parent, childName, className)
    local child = parent:FindFirstChild(childName)
    return child ~= nil and child.ClassName == className
end

local function isValidGlass(part)
    if not part:IsA("BasePart") then
        return false
    end

    -- Если есть DamageScript — это НЕ то стекло, сразу исключаем.
    if part:FindFirstChild("GlassDamageScript") then
        return false
    end

    -- Нужные признаки "правильного" стекла.
    local hasGreenEffectScript = hasChildOfType(part, "GlassGreenEffectScript", "Script")
    local hasTouchInterest = hasChildOfType(part, "TouchInterest", "TouchTransmitter")

    return hasGreenEffectScript and hasTouchInterest
end

local function clearHighlights()
    for _, item in ipairs(highlightFolder:GetChildren()) do
        item:Destroy()
    end
end

local function highlightPart(part, index)
    local h = Instance.new("Highlight")
    -- Не используем GetDebugId (может быть недоступен в обычном скрипте).
    h.Name = "HL_" .. tostring(index)
    h.Adornee = part
    h.FillColor = HIGHLIGHT_COLOR
    h.FillTransparency = HIGHLIGHT_FILL_TRANSPARENCY
    h.OutlineColor = HIGHLIGHT_COLOR
    h.OutlineTransparency = HIGHLIGHT_OUTLINE_TRANSPARENCY
    h.Parent = highlightFolder
end

local function refreshGlassHighlights()
    clearHighlights()

    local index = 0
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if isValidGlass(obj) then
            index = index + 1
            highlightPart(obj, index)
        end
    end
end

refreshGlassHighlights()

-- Авто-обновление при изменениях структуры в Workspace.
Workspace.DescendantAdded:Connect(function()
    refreshGlassHighlights()
end)

Workspace.DescendantRemoving:Connect(function()
    refreshGlassHighlights()
end)
