-- Подсветка только "правильных" стёкол.
-- Условие: у Part должны быть РОВНО 2 прямых дочерних объекта:
--   1) GlassGreenEffectScript (Script)
--   2) TouchInterest (TouchTransmitter)
-- И НЕ должно быть вариантов вроде GlassDamageScript.

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

local function isValidGlass(part)
    if not part:IsA("BasePart") then
        return false
    end

    -- Имя обычно "Glass1", "Glass2" и т.д.
    if not part.Name:match("^Glass%d+$") then
        return false
    end

    local children = part:GetChildren()
    if #children ~= 2 then
        return false
    end

    local hasGreenEffectScript = false
    local hasTouchInterest = false

    for _, child in ipairs(children) do
        if child.Name == "GlassGreenEffectScript" and child.ClassName == "Script" then
            hasGreenEffectScript = true
        elseif child.Name == "TouchInterest" and child.ClassName == "TouchTransmitter" then
            hasTouchInterest = true
        else
            -- Любой лишний/другой ребёнок (например GlassDamageScript) не подходит.
            return false
        end
    end

    return hasGreenEffectScript and hasTouchInterest
end

local function clearHighlights()
    for _, item in ipairs(highlightFolder:GetChildren()) do
        item:Destroy()
    end
end

local function highlightPart(part)
    local h = Instance.new("Highlight")
    h.Name = "HL_" .. part:GetDebugId(0)
    h.Adornee = part
    h.FillColor = HIGHLIGHT_COLOR
    h.FillTransparency = HIGHLIGHT_FILL_TRANSPARENCY
    h.OutlineColor = HIGHLIGHT_COLOR
    h.OutlineTransparency = HIGHLIGHT_OUTLINE_TRANSPARENCY
    h.Parent = highlightFolder
end

local function refreshGlassHighlights()
    clearHighlights()

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if isValidGlass(obj) then
            highlightPart(obj)
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
