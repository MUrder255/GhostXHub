-- Example LocalScript (StarterPlayerScripts). Place SettingsMenu as a
-- ModuleScript in ReplicatedStorage and DevToolsPermission.server.lua in
-- ServerScriptService.
--
--   Player ESP  - admin-only spectator outlines (Highlight + BillboardGui).
--   NPC Lock-On - hold right mouse to lock the camera onto the nearest NPC
--                 tagged "LockOnTarget" (CollectionService). Players are
--                 never valid targets.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local SettingsMenu = require(ReplicatedStorage:WaitForChild("SettingsMenu"))

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local ESP_COLOR = Color3.fromRGB(255, 70, 70)
local LOCK_TAG = "LockOnTarget"
local LOCK_RANGE = 120          -- studs
local LOCK_SMOOTHNESS = 0.25    -- 0-1, higher = snappier
local LOCK_KEY = Enum.UserInputType.MouseButton2

--------------------------------------------------------------------------
-- Player ESP (admin only)
--------------------------------------------------------------------------

local Esp = { enabled = false, entries = {}, connections = {}, accumulator = 0 }

local function clearEntry(player)
    local entry = Esp.entries[player]
    if entry then
        entry.highlight:Destroy()
        entry.billboard:Destroy()
        Esp.entries[player] = nil
    end
end

local function attach(player, character)
    clearEntry(player)
    local head = character:WaitForChild("Head", 5)
    if not head or not Esp.enabled then
        return
    end

    local highlight = Instance.new("Highlight")
    highlight.FillColor = ESP_COLOR
    highlight.FillTransparency = 0.75
    highlight.OutlineColor = ESP_COLOR
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = character
    highlight.Parent = character

    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.fromOffset(200, 36)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Adornee = head
    billboard.Parent = head

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0.4
    label.Text = player.DisplayName
    label.Parent = billboard

    Esp.entries[player] = { highlight = highlight, billboard = billboard, label = label, character = character }
end

local function watchPlayer(player)
    if player == LocalPlayer then
        return
    end
    table.insert(Esp.connections, player.CharacterAdded:Connect(function(character)
        attach(player, character)
    end))
    if player.Character then
        task.spawn(attach, player, player.Character)
    end
end

function Esp.setEnabled(enabled)
    Esp.enabled = enabled
    for _, connection in ipairs(Esp.connections) do
        connection:Disconnect()
    end
    table.clear(Esp.connections)
    for player in pairs(Esp.entries) do
        clearEntry(player)
    end
    if not enabled then
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        watchPlayer(player)
    end
    table.insert(Esp.connections, Players.PlayerAdded:Connect(watchPlayer))
    table.insert(Esp.connections, Players.PlayerRemoving:Connect(clearEntry))
    table.insert(Esp.connections, RunService.Heartbeat:Connect(function(dt)
        Esp.accumulator += dt
        if Esp.accumulator < 0.2 then
            return
        end
        Esp.accumulator = 0
        for player, entry in pairs(Esp.entries) do
            local humanoid = entry.character:FindFirstChildOfClass("Humanoid")
            local root = entry.character:FindFirstChild("HumanoidRootPart")
            if humanoid and root then
                local distance = (Camera.CFrame.Position - root.Position).Magnitude
                entry.label.Text = string.format("%s  [%dm]  %d HP",
                    player.DisplayName, math.floor(distance), math.floor(humanoid.Health))
            end
        end
    end))
end

--------------------------------------------------------------------------
-- NPC lock-on
--------------------------------------------------------------------------

local LockOn = { enabled = false, holding = false, target = nil }
local BIND_NAME = "SettingsMenuLockOn"

local function aimPart(model)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return nil
    end
    return model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
end

local function isValidTarget(model)
    return model:IsA("Model")
        and model:IsDescendantOf(workspace)
        and Players:GetPlayerFromCharacter(model) == nil
        and aimPart(model) ~= nil
end

local function findTarget()
    local best, bestScore = nil, math.huge
    local center = Camera.ViewportSize / 2
    for _, model in ipairs(CollectionService:GetTagged(LOCK_TAG)) do
        if isValidTarget(model) then
            local part = aimPart(model)
            local distance = (part.Position - Camera.CFrame.Position).Magnitude
            local screen, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen and distance <= LOCK_RANGE then
                local score = (Vector2.new(screen.X, screen.Y) - center).Magnitude
                if score < bestScore then
                    best, bestScore = model, score
                end
            end
        end
    end
    return best
end

local function stepLockOn()
    if not (LockOn.enabled and LockOn.holding) then
        LockOn.target = nil
        return
    end
    if not (LockOn.target and isValidTarget(LockOn.target)) then
        LockOn.target = findTarget()
    end
    local part = LockOn.target and aimPart(LockOn.target)
    if part then
        local goal = CFrame.lookAt(Camera.CFrame.Position, part.Position)
        Camera.CFrame = Camera.CFrame:Lerp(goal, LOCK_SMOOTHNESS)
    end
end

function LockOn.setEnabled(enabled)
    LockOn.enabled = enabled
    LockOn.target = nil
    RunService:UnbindFromRenderStep(BIND_NAME)
    if enabled then
        -- Run after the default camera so it doesn't overwrite our CFrame.
        RunService:BindToRenderStep(BIND_NAME, Enum.RenderPriority.Camera.Value + 1, stepLockOn)
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.UserInputType == LOCK_KEY then
        LockOn.holding = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == LOCK_KEY then
        LockOn.holding = false
    end
end)

--------------------------------------------------------------------------
-- Menu
--------------------------------------------------------------------------

local menu = SettingsMenu.new({
    title = "Game Settings",
    toggleKey = Enum.KeyCode.RightShift,
})

menu:AddSection("Combat")
menu:AddToggle({
    name = "NPC Lock-On (hold RMB)",
    default = false,
    callback = LockOn.setEnabled,
})

local permission = ReplicatedStorage:WaitForChild("DevToolsPermission", 10)
local ok, isAdmin = false, false
if permission then
    ok, isAdmin = pcall(permission.InvokeServer, permission)
end

if ok and isAdmin then
    menu:AddSection("Admin")
    menu:AddToggle({
        name = "Player ESP",
        default = false,
        callback = Esp.setEnabled,
    })
end

menu:AddSection("General")
menu:AddButton({
    name = "Turn Everything Off",
    callback = function()
        menu:GetToggle("NPC Lock-On (hold RMB)"):Set(false)
        local esp = menu:GetToggle("Player ESP")
        if esp then
            esp:Set(false)
        end
    end,
})
