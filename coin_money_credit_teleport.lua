-- Locks the camera aim to the visible enemy head closest to the crosshair while LMB is held.
-- Works on the local client.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local isHoldingLMB = false

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

local function colorToKey(color3)
    if not color3 then
        return nil
    end

    local r = math.floor(color3.R * 255 + 0.5)
    local g = math.floor(color3.G * 255 + 0.5)
    local b = math.floor(color3.B * 255 + 0.5)
    return string.format("rgb:%d,%d,%d", r, g, b)
end

local function addMarker(markers, marker)
    if marker and marker ~= "" then
        markers[marker] = true
    end
end

local function getTeamMarkers(player, character)
    local markers = {}

    if player.Team then
        addMarker(markers, "team:" .. player.Team.Name)
    end

    if player.TeamColor then
        addMarker(markers, "teamColor:" .. tostring(player.TeamColor.Number))
    end

    if character then
        local attributeKeys = {
            "Team",
            "TeamName",
            "TeamColor",
            "Faction",
            "Side",
            "Clan",
        }

        for _, key in ipairs(attributeKeys) do
            local value = character:GetAttribute(key)
            if value ~= nil then
                addMarker(markers, key .. ":" .. tostring(value))
            end
        end

        local valueObjectKeys = {
            "Team",
            "TeamName",
            "Faction",
            "Side",
            "Clan",
        }

        for _, key in ipairs(valueObjectKeys) do
            local valueObject = character:FindFirstChild(key)
            if valueObject and valueObject:IsA("StringValue") then
                addMarker(markers, key .. ":" .. valueObject.Value)
            end
        end

        local nameTag = character:FindFirstChild("NameTag", true)
        if nameTag and nameTag:IsA("BillboardGui") then
            for _, descendant in ipairs(nameTag:GetDescendants()) do
                if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
                    addMarker(markers, "nameTagColor:" .. colorToKey(descendant.TextColor3))
                    break
                end
            end
        end
    end

    return markers
end

local function hasSharedMarker(markersA, markersB)
    for marker in pairs(markersA) do
        if markersB[marker] then
            return true
        end
    end

    return false
end

local function hasAnyMarker(markers)
    for _ in pairs(markers) do
        return true
    end

    return false
end

local function hasLineOfSight(head)
    local myCharacter = getCharacter(LocalPlayer)
    local myHead = myCharacter and getHead(myCharacter)

    if not myHead or not head then
        return false
    end

    local direction = head.Position - myHead.Position

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = { myCharacter }

    local hit = Workspace:Raycast(myHead.Position, direction, params)

    if not hit then
        return true
    end

    return hit.Instance and hit.Instance:IsDescendantOf(head.Parent)
end

local function isEnemy(player)
    if not player or player == LocalPlayer then
        return false
    end

    local myCharacter = getCharacter(LocalPlayer)
    local targetCharacter = getCharacter(player)

    local myMarkers = getTeamMarkers(LocalPlayer, myCharacter)
    local targetMarkers = getTeamMarkers(player, targetCharacter)

    if hasAnyMarker(myMarkers) and hasAnyMarker(targetMarkers) then
        return not hasSharedMarker(myMarkers, targetMarkers)
    end

    -- Safe fallback: if team cannot be determined, do not target.
    return false
end

local function getClosestToCrosshairHead()
    local myCharacter = getCharacter(LocalPlayer)
    if not myCharacter or not isAlive(myCharacter) then
        return nil
    end

    local viewportSize = Camera.ViewportSize
    local crosshair = Vector2.new(viewportSize.X * 0.5, viewportSize.Y * 0.5)

    local nearestHead = nil
    local nearestScreenDistance = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if isEnemy(player) then
            local character = getCharacter(player)
            local head = getHead(character)

            if head and isAlive(character) and hasLineOfSight(head) then
                local headScreenPoint, isOnScreen = Camera:WorldToViewportPoint(head.Position)

                if isOnScreen and headScreenPoint.Z > 0 then
                    local headPoint2D = Vector2.new(headScreenPoint.X, headScreenPoint.Y)
                    local screenDistance = (headPoint2D - crosshair).Magnitude

                    if screenDistance < nearestScreenDistance then
                        nearestScreenDistance = screenDistance
                        nearestHead = head
                    end
                end
            end
        end
    end

    return nearestHead
end

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isHoldingLMB = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isHoldingLMB = false
    end
end)

RunService.RenderStepped:Connect(function()
    if not isHoldingLMB then
        return
    end

    local targetHead = getClosestToCrosshairHead()
    if not targetHead then
        return
    end

    local cameraPosition = Camera.CFrame.Position
    Camera.CFrame = CFrame.new(cameraPosition, targetHead.Position)
end)
