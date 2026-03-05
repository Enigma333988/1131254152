-- Locks the camera aim to the nearest visible player's head while LMB is held.
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

local function getHead(character)
    if not character then
        return nil
    end

    return character:FindFirstChild("Head")
end

local function hasLineOfSight(head)
    local myCharacter = LocalPlayer.Character
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

local function getClosestEnemyHead()
    local myCharacter = LocalPlayer.Character

    if not myCharacter or not isAlive(myCharacter) then
        return nil
    end

    local myHead = getHead(myCharacter)
    if not myHead then
        return nil
    end

    local nearestHead = nil
    local nearestDistance = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            local head = getHead(character)

            if head and isAlive(character) and hasLineOfSight(head) then
                local distance = (head.Position - myHead.Position).Magnitude

                if distance < nearestDistance then
                    nearestDistance = distance
                    nearestHead = head
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

    local targetHead = getClosestEnemyHead()
    if not targetHead then
        return
    end

    local cameraPosition = Camera.CFrame.Position
    Camera.CFrame = CFrame.new(cameraPosition, targetHead.Position)
end)
