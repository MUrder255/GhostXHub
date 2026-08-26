local UI = {}
local TweenService = game:GetService("TweenService")

local COLORS = {
    text = Color3.fromRGB(235, 242, 250),
    muted = Color3.fromRGB(145, 164, 185),
    surface = Color3.fromRGB(16, 24, 38),
    surfaceRaised = Color3.fromRGB(25, 37, 56),
    accent = Color3.fromRGB(87, 176, 255),
    success = Color3.fromRGB(93, 211, 158),
}

local function applyCorner(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = instance
end

local function createShootingStar(parent)
    local star = Instance.new("Frame")
    star.Name = "ShootingStar"
    star.AnchorPoint = Vector2.new(0.5, 0.5)
    star.Size = UDim2.fromOffset(math.random(22, 52), math.random(1, 2))
    star.Position = UDim2.fromScale(math.random(-10, 75) / 100, math.random(-10, 55) / 100)
    star.Rotation = math.random(25, 42)
    star.BackgroundColor3 = COLORS.accent
    star.BackgroundTransparency = 0.2
    star.BorderSizePixel = 0
    star.Parent = parent
    applyCorner(star, 2)

    local travel = TweenService:Create(star, TweenInfo.new(math.random(12, 20) / 10, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Position = UDim2.fromScale(math.random(90, 125) / 100, math.random(80, 125) / 100),
        BackgroundTransparency = 1,
    })
    travel.Completed:Connect(function()
        star:Destroy()
    end)
    travel:Play()
end

local function startStarfield(parent)
    task.spawn(function()
        while parent.Parent do
            createShootingStar(parent)
            task.wait(math.random(28, 70) / 10)
        end
    end)
end

function UI.createRoot(playerGui, starsEnabled)
    assert(playerGui, "playerGui is required")

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GhostXDashboard"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.DisplayOrder = 10
    screenGui.Parent = playerGui

    local backdrop = Instance.new("Frame")
    backdrop.Name = "Starfield"
    backdrop.Size = UDim2.fromScale(1, 1)
    backdrop.BackgroundColor3 = Color3.fromRGB(5, 10, 20)
    backdrop.BackgroundTransparency = 0.04
    backdrop.BorderSizePixel = 0
    backdrop.ClipsDescendants = true
    backdrop.Parent = screenGui

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(8, 19, 37)),
        ColorSequenceKeypoint.new(0.52, Color3.fromRGB(10, 25, 42)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(3, 8, 17)),
    })
    gradient.Rotation = 28
    gradient.Parent = backdrop

    if starsEnabled ~= false then
        startStarfield(backdrop)
    end

    return screenGui
end

function UI.createPanel(parent, title, subtitle)
    assert(parent, "parent is required")

    local panel = Instance.new("Frame")
    panel.Name = "DashboardPanel"
    panel.Size = UDim2.fromScale(0.86, 0.78)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.BackgroundColor3 = COLORS.surface
    panel.BackgroundTransparency = 0.14
    panel.BorderSizePixel = 0
    panel.ClipsDescendants = true
    panel.Parent = parent
    applyCorner(panel, 14)

    local sizeConstraint = Instance.new("UISizeConstraint")
    sizeConstraint.MinSize = Vector2.new(520, 360)
    sizeConstraint.MaxSize = Vector2.new(980, 650)
    sizeConstraint.Parent = panel

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(137, 190, 232)
    stroke.Transparency = 0.62
    stroke.Thickness = 1
    stroke.Parent = panel

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, -40, 0, 68)
    header.Position = UDim2.fromOffset(20, 16)
    header.BackgroundTransparency = 1
    header.Parent = panel

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0, 32)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = title or "Dashboard"
    titleLabel.TextColor3 = COLORS.text
    titleLabel.TextSize = 22
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = header

    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Name = "Subtitle"
    subtitleLabel.Size = UDim2.new(1, 0, 0, 22)
    subtitleLabel.Position = UDim2.fromOffset(0, 34)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Font = Enum.Font.Gotham
    subtitleLabel.Text = subtitle or ""
    subtitleLabel.TextColor3 = COLORS.muted
    subtitleLabel.TextSize = 13
    subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    subtitleLabel.Parent = header

    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -40, 1, -104)
    content.Position = UDim2.fromOffset(20, 92)
    content.BackgroundTransparency = 1
    content.Parent = panel

    return panel, content
end

function UI.createCard(parent, title, value, accentColor)
    local card = Instance.new("Frame")
    card.Name = title:gsub("%s", "")
    card.Size = UDim2.new(0.32, -8, 0, 92)
    card.BackgroundColor3 = COLORS.surfaceRaised
    card.BackgroundTransparency = 0.2
    card.BorderSizePixel = 0
    card.Parent = parent
    applyCorner(card, 9)

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = accentColor or COLORS.accent
    cardStroke.Transparency = 0.78
    cardStroke.Parent = card

    local heading = Instance.new("TextLabel")
    heading.Size = UDim2.new(1, -20, 0, 24)
    heading.Position = UDim2.fromOffset(10, 10)
    heading.BackgroundTransparency = 1
    heading.Font = Enum.Font.Gotham
    heading.Text = title
    heading.TextColor3 = COLORS.muted
    heading.TextSize = 12
    heading.TextXAlignment = Enum.TextXAlignment.Left
    heading.Parent = card

    local reading = Instance.new("TextLabel")
    reading.Name = "Value"
    reading.Size = UDim2.new(1, -20, 0, 36)
    reading.Position = UDim2.fromOffset(10, 36)
    reading.BackgroundTransparency = 1
    reading.Font = Enum.Font.GothamBold
    reading.Text = value
    reading.TextColor3 = COLORS.text
    reading.TextSize = 22
    reading.TextXAlignment = Enum.TextXAlignment.Left
    reading.Parent = card

    return card, reading
end

function UI.createButton(parent, text, callback)
    local button = Instance.new("TextButton")
    button.Name = text:gsub("%s", "")
    button.Size = UDim2.new(1, 0, 0, 40)
    button.BackgroundColor3 = COLORS.surfaceRaised
    button.BackgroundTransparency = 0.18
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Font = Enum.Font.GothamMedium
    button.Text = text
    button.TextColor3 = COLORS.text
    button.TextSize = 13
    button.Parent = parent
    applyCorner(button, 7)

    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.accent}):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.surfaceRaised}):Play()
    end)
    button.Activated:Connect(callback)
    return button
end

function UI.createToggle(parent, label, initialValue, callback)
    local button = UI.createButton(parent, label, function()
        initialValue = not initialValue
        callback(initialValue)
    end)
    button.TextXAlignment = Enum.TextXAlignment.Left
    button.Text = string.format("%s    %s", label, initialValue and "ON" or "OFF")
    button.Activated:Connect(function()
        button.Text = string.format("%s    %s", label, initialValue and "ON" or "OFF")
    end)
    return button
end

return UI

local function createShootingStar(parent)
    local star = Instance.new("Frame")
    star.Name = "ShootingStar"
    star.AnchorPoint = Vector2.new(0.5, 0.5)
    star.Size = UDim2.fromOffset(math.random(18, 42), 2)
    star.Position = UDim2.fromScale(math.random(-10, 75) / 100, math.random(-15, 45) / 100)
    star.Rotation = math.random(25, 42)
    star.BackgroundColor3 = Color3.fromRGB(170, 218, 255)
    star.BackgroundTransparency = 0.12
    star.BorderSizePixel = 0
    star.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = star

    local travel = TweenService:Create(
        star,
        TweenInfo.new(math.random(12, 20) / 10, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {
            Position = UDim2.fromScale(math.random(90, 125) / 100, math.random(80, 125) / 100),
            BackgroundTransparency = 1,
        }
    )

    travel.Completed:Connect(function()
        star:Destroy()
    end)
    travel:Play()
end

local function startStarfield(parent)
    task.spawn(function()
        while parent.Parent do
            createShootingStar(parent)
            task.wait(math.random(35, 85) / 10)
        end
    end)
end

function UI.createRoot(playerGui)
    assert(playerGui, "playerGui is required")

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GhostXDashboard"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    local backdrop = Instance.new("Frame")
    backdrop.Name = "Starfield"
    backdrop.Size = UDim2.fromScale(1, 1)
    backdrop.BackgroundColor3 = Color3.fromRGB(7, 12, 22)
    backdrop.BackgroundTransparency = 0.08
    backdrop.BorderSizePixel = 0
    backdrop.ClipsDescendants = true
    backdrop.ZIndex = 0
    backdrop.Parent = screenGui

    local backdropGradient = Instance.new("UIGradient")
    backdropGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(8, 17, 33)),
        ColorSequenceKeypoint.new(0.55, Color3.fromRGB(11, 22, 36)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(4, 9, 18)),
    })
    backdropGradient.Rotation = 25
    backdropGradient.Parent = backdrop

    startStarfield(backdrop)

    return screenGui
end

function UI.createPanel(parent, title)
    assert(parent, "parent is required")

    local panel = Instance.new("Frame")
    panel.Name = title or "Panel"
    panel.Size = UDim2.fromOffset(420, 280)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.BackgroundColor3 = Color3.fromRGB(17, 25, 38)
    panel.BackgroundTransparency = 0.18
    panel.BorderSizePixel = 0
    panel.ZIndex = 2
    panel.Parent = parent

    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 12)
    panelCorner.Parent = panel

    local panelStroke = Instance.new("UIStroke")
    panelStroke.Color = Color3.fromRGB(137, 190, 232)
    panelStroke.Transparency = 0.62
    panelStroke.Thickness = 1
    panelStroke.Parent = panel

    local panelGradient = Instance.new("UIGradient")
    panelGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 57, 82)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 18, 29)),
    })
    panelGradient.Rotation = 110
    panelGradient.Parent = panel

    local header = Instance.new("TextLabel")
    header.Name = "Title"
    header.Size = UDim2.new(1, -24, 0, 42)
    header.Position = UDim2.fromOffset(12, 8)
    header.BackgroundTransparency = 1
    header.Font = Enum.Font.GothamBold
    header.Text = title or "Dashboard"
    header.TextColor3 = Color3.fromRGB(240, 243, 248)
    header.TextSize = 19
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.ZIndex = 3
    header.Parent = panel

    return panel
end

return UI
