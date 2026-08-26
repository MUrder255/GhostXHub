local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local UserInputService = game:GetService("UserInputService")

if not RunService:IsClient() then
    error("GhostXDeveloperDashboard must run on the client", 0)
end

local UI = require(script.Parent.UI)
local Settings = require(script.Parent.Settings)
local Aimbot = require(script.Parent.Aimbot)
local Esp = require(script.Parent.Esp)

local Dashboard = {
    mounted = false,
    connections = {},
    modules = { Aimbot = Aimbot, Esp = Esp },
    settings = Settings,
}

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(Dashboard.connections, connection)
    return connection
end

local function getPing()
    local ok, value = pcall(function()
        return Stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
    end)
    return ok and value or "N/A"
end

local function getMemory()
    local ok, value = pcall(function()
        return Stats:GetTotalMemoryUsageMb()
    end)
    return ok and string.format("%.0f MB", value) or "N/A"
end

local function createSection(parent, title, subtitle)
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, subtitle and 46 or 28)
    header.BackgroundTransparency = 1
    header.Parent = parent

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 24)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(235, 242, 250)
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = header

    if subtitle then
        local subtitleLabel = titleLabel:Clone()
        subtitleLabel.Position = UDim2.fromOffset(0, 25)
        subtitleLabel.Font = Enum.Font.Gotham
        subtitleLabel.Text = subtitle
        subtitleLabel.TextColor3 = Color3.fromRGB(145, 164, 185)
        subtitleLabel.TextSize = 12
        subtitleLabel.Parent = header
    end
    return header
end

local function createMetric(parent, name, value)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 36)
    row.BackgroundColor3 = Color3.fromRGB(25, 37, 56)
    row.BackgroundTransparency = 0.2
    row.BorderSizePixel = 0
    row.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = row

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, -12, 1, 0)
    label.Position = UDim2.fromOffset(12, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.Text = name
    label.TextColor3 = Color3.fromRGB(145, 164, 185)
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local reading = label:Clone()
    reading.Name = "Value"
    reading.Position = UDim2.new(0.5, 0, 0, 0)
    reading.Text = tostring(value)
    reading.TextColor3 = Color3.fromRGB(235, 242, 250)
    reading.TextXAlignment = Enum.TextXAlignment.Right
    reading.Parent = row
    return reading
end

function Dashboard.mount()
    if Dashboard.mounted then
        return Dashboard
    end
    Dashboard.mounted = true

    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    local oldRoot = playerGui:FindFirstChild("GhostXDeveloperDashboard")
    if oldRoot then
        oldRoot:Destroy()
    end

    local root = UI.createRoot(playerGui, Settings.starfieldEnabled)
    local panel, content = UI.createPanel(root, Settings.title, Settings.subtitle .. "  |  RightShift to show/hide")
    Dashboard.root = root
    Dashboard.panel = panel

    local tabs = Instance.new("Frame")
    tabs.Size = UDim2.new(0, 130, 1, -112)
    tabs.Position = UDim2.fromOffset(20, 92)
    tabs.BackgroundTransparency = 1
    tabs.Parent = panel
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Padding = UDim.new(0, 8)
    tabLayout.Parent = tabs

    local pages = {}
    local pageButtons = {}
    local pageHost = Instance.new("Frame")
    pageHost.Size = UDim2.new(1, -174, 1, -112)
    pageHost.Position = UDim2.fromOffset(154, 92)
    pageHost.BackgroundTransparency = 1
    pageHost.Parent = panel

    local function makePage(name)
        local page = Instance.new("ScrollingFrame")
        page.Name = name
        page.Size = UDim2.fromScale(1, 1)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 3
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.CanvasSize = UDim2.new()
        page.Visible = false
        page.Parent = pageHost
        local padding = Instance.new("UIPadding")
        padding.PaddingRight = UDim.new(0, 8)
        padding.PaddingBottom = UDim.new(0, 12)
        padding.Parent = page
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 9)
        layout.Parent = page
        pages[name] = page
        return page
    end

    local function selectPage(name)
        for pageName, page in pairs(pages) do
            page.Visible = pageName == name
            if pageButtons[pageName] then
                pageButtons[pageName].BackgroundColor3 = pageName == name and Settings.accentColor or Color3.fromRGB(25, 37, 56)
            end
        end
    end

    for _, name in ipairs({ "Overview", "Diagnostics", "Settings" }) do
        local button = UI.createButton(tabs, name, function()
            selectPage(name)
        end)
        button.TextXAlignment = Enum.TextXAlignment.Left
        pageButtons[name] = button
    end

    local overview = makePage("Overview")
    createSection(overview, "Session overview", "Live runtime information and general controls")
    local cards = Instance.new("Frame")
    cards.Size = UDim2.new(1, 0, 0, 92)
    cards.BackgroundTransparency = 1
    cards.Parent = overview
    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(0.31, -6, 1, 0)
    grid.CellPadding = UDim2.fromOffset(9, 0)
    grid.Parent = cards
    local _, playerValue = UI.createCard(cards, "PLAYERS", #Players:GetPlayers(), Color3.fromRGB(93, 211, 158))
    local _, fpsValue = UI.createCard(cards, "FPS", "--", Settings.accentColor)
    local _, pingValue = UI.createCard(cards, "PING", getPing(), Color3.fromRGB(248, 190, 86))

    createSection(overview, "Developer controls")
    UI.createToggle(overview, "Diagnostics overlay", Settings.showDiagnostics, function(value)
        Settings.set("showDiagnostics", value)
    end)
    UI.createToggle(overview, "Shooting stars", Settings.starfieldEnabled, function(value)
        Settings.set("starfieldEnabled", value)
    end)
    UI.createToggle(overview, "Reduced motion", Settings.reducedMotion, function(value)
        Settings.set("reducedMotion", value)
    end)

    local diagnostics = makePage("Diagnostics")
    createSection(diagnostics, "Runtime diagnostics", "Read-only values from this Roblox client")
    createMetric(diagnostics, "Player", Players.LocalPlayer.DisplayName)
    createMetric(diagnostics, "User ID", Players.LocalPlayer.UserId)
    createMetric(diagnostics, "Place ID", game.PlaceId)
    local sessionValue = createMetric(diagnostics, "Session time", "00:00:00")
    createMetric(diagnostics, "Targeting guard", Aimbot.getStatus().mode)
    createMetric(diagnostics, "Visibility guard", Esp.getStatus().mode)

    local settingsPage = makePage("Settings")
    createSection(settingsPage, "Control center settings", "Changes apply immediately for this session")
    UI.createToggle(settingsPage, "Diagnostics overlay", Settings.showDiagnostics, function(value)
        Settings.set("showDiagnostics", value)
    end)
    UI.createToggle(settingsPage, "Shooting stars", Settings.starfieldEnabled, function(value)
        Settings.set("starfieldEnabled", value)
    end)
    UI.createToggle(settingsPage, "Reduced motion", Settings.reducedMotion, function(value)
        Settings.set("reducedMotion", value)
    end)

    connect(UserInputService.InputBegan, function(input, processed)
        if not processed and input.KeyCode == Settings.toggleKey then
            root.Enabled = not root.Enabled
        end
    end)
    connect(Players.PlayerAdded, function()
        playerValue.Text = tostring(#Players:GetPlayers())
    end)
    connect(Players.PlayerRemoving, function()
        task.defer(function()
            playerValue.Text = tostring(#Players:GetPlayers())
        end)
    end)

    local startedAt = os.clock()
    local frames = 0
    local elapsed = 0
    connect(RunService.RenderStepped, function(deltaTime)
        frames = frames + 1
        elapsed = elapsed + deltaTime
        if elapsed < 0.5 then
            return
        end
        local fps = math.floor(frames / elapsed + 0.5)
        fpsValue.Text = tostring(fps)
        pingValue.Text = getPing()
        sessionValue.Text = string.format("%02d:%02d:%02d", math.floor((os.clock() - startedAt) / 3600), math.floor((os.clock() - startedAt) / 60) % 60, math.floor(os.clock() - startedAt) % 60)
        frames = 0
        elapsed = 0
    end)

    selectPage("Overview")
    return Dashboard
end

function Dashboard.unmount()
    if not Dashboard.mounted then
        return
    end
    Dashboard.mounted = false
    for _, connection in ipairs(Dashboard.connections) do
        connection:Disconnect()
    end
    table.clear(Dashboard.connections)
    if Dashboard.root then
        Dashboard.root:Destroy()
        Dashboard.root = nil
    end
end

return Dashboard
