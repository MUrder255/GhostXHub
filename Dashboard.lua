local Players = game:GetService("Players")

local UI = require(script.Parent.UI)
local Settings = require(script.Parent.Settings)
local Aimbot = require(script.Parent.Aimbot)
local Esp = require(script.Parent.Esp)

local Dashboard = {}

local function addSectionLabel(parent, text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 24)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.Text = text
    label.TextColor3 = Color3.fromRGB(235, 242, 250)
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    return label
end

function Dashboard.mount()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    local root = UI.createRoot(playerGui, Settings.starfieldEnabled)
    local panel, content = UI.createPanel(root, Settings.title, Settings.subtitle)

    local contentPadding = Instance.new("UIPadding")
    contentPadding.PaddingTop = UDim.new(0, 4)
    contentPadding.Parent = content

    local cards = Instance.new("Frame")
    cards.Name = "Overview"
    cards.Size = UDim2.new(1, 0, 0, 92)
    cards.BackgroundTransparency = 1
    cards.Parent = content

    local cardLayout = Instance.new("UIListLayout")
    cardLayout.FillDirection = Enum.FillDirection.Horizontal
    cardLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    cardLayout.Padding = UDim.new(0, 12)
    cardLayout.Parent = cards

    UI.createCard(cards, "SESSION", "ACTIVE", Color3.fromRGB(93, 211, 158))
    UI.createCard(cards, "PLAYERS", tostring(#Players:GetPlayers()), Settings.accentColor)
    UI.createCard(cards, "ACCESS", "PRIVATE", Color3.fromRGB(248, 190, 86))

    local controls = Instance.new("Frame")
    controls.Name = "Controls"
    controls.Size = UDim2.new(1, 0, 1, -108)
    controls.Position = UDim2.fromOffset(0, 108)
    controls.BackgroundTransparency = 1
    controls.Parent = content

    local controlsLayout = Instance.new("UIListLayout")
    controlsLayout.Padding = UDim.new(0, 8)
    controlsLayout.Parent = controls

    addSectionLabel(controls, "Developer controls")
    UI.createToggle(controls, "Diagnostics overlay", Settings.showDiagnostics, function(value)
        Settings.set("showDiagnostics", value)
    end)
    UI.createToggle(controls, "Shooting stars", Settings.starfieldEnabled, function(value)
        Settings.set("starfieldEnabled", value)
    end)
    UI.createToggle(controls, "Reduced motion", Settings.reducedMotion, function(value)
        Settings.set("reducedMotion", value)
    end)

    local statusButton
    statusButton = UI.createButton(controls, "Run module health check", function()
        local aimStatus = Aimbot.getStatus()
        local espStatus = Esp.getStatus()
        statusButton.Text = string.format("Health check: %s / %s", aimStatus.mode, espStatus.mode)
    end)

    return {
        root = root,
        panel = panel,
        content = content,
        settings = Settings,
        modules = {
            Aimbot = Aimbot,
            Esp = Esp,
        },
    }
end

return Dashboard
