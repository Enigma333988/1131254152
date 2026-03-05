-- Locks camera aim to the visible enemy head closest to the crosshair while LMB is held.
-- LocalScript only.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local isHoldingLMB = false

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

local function colorToKey(color3)
    if not color3 then
        return nil
    end

    return string.format(
        "rgb:%d,%d,%d",
        math.floor(color3.R * 255 + 0.5),
        math.floor(color3.G * 255 + 0.5),
        math.floor(color3.B * 255 + 0.5)
    )
end

local function readStringValue(container, key)
    if not container then
        return nil
    end

    local valueObject = container:FindFirstChild(key)
    if valueObject and valueObject:IsA("StringValue") and valueObject.Value ~= "" then
        return valueObject.Value
    end

    return nil
end

local function readTeamSignature(player, character)
    if player and player.Team then
        return "team:" .. player.Team.Name
    end

    if player and player.TeamColor then
        return "teamColor:" .. tostring(player.TeamColor.Number)
    end

    local keys = { "Team", "TeamName", "Faction", "Side", "Clan" }

    for _, key in ipairs(keys) do
        if character then
            local attr = character:GetAttribute(key)
            if attr ~= nil and tostring(attr) ~= "" then
                return key .. ":" .. tostring(attr)
            end
        end

        local strValue = readStringValue(character, key)
        if strValue then
            return key .. ":" .. strValue
        end

        local playerAttr = player and player:GetAttribute(key)
        if playerAttr ~= nil and tostring(playerAttr) ~= "" then
            return "player" .. key .. ":" .. tostring(playerAttr)
        end

        local playerStrValue = readStringValue(player, key)
        if playerStrValue then
            return "player" .. key .. ":" .. playerStrValue
        end
    end

    if character then
        local nameTag = character:FindFirstChild("NameTag", true)
        if nameTag and nameTag:IsA("BillboardGui") then
            for _, descendant in ipairs(nameTag:GetDescendants()) do
                if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
                    return "nameTagColor:" .. tostring(colorToKey(descendant.TextColor3))
                end
            end
        end
    end

    return nil
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

    local mySignature = readTeamSignature(LocalPlayer, myCharacter)
    local targetSignature = readTeamSignature(player, targetCharacter)

    if mySignature and targetSignature then
        return mySignature ~= targetSignature
    end

    -- If team data is unknown, don't lock to avoid shooting teammates.
    return false
end

local function getClosestToCrosshairHead()
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
        if isEnemy(player) then
            local character = getCharacter(player)
            local head = getHead(character)

            if head and isAlive(character) and hasLineOfSight(head) then
                local headScreenPoint, isOnScreen = camera:WorldToViewportPoint(head.Position)

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

    local camera = getCurrentCamera()
    if not camera then
        return
    end

    local targetHead = getClosestToCrosshairHead()
    if not targetHead then
        return
    end

    local cameraPosition = camera.CFrame.Position
    camera.CFrame = CFrame.new(cameraPosition, targetHead.Position)
end)
