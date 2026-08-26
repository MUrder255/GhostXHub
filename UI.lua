local UI = {}
local TweenService = game:GetService("TweenService")

local COLORS = {
    text = Color3.fromRGB(235, 242, 250),
    muted = Color3.fromRGB(145, 164, 185),
    surface = Color3.fromRGB(16, 24, 38),
    surfaceRaised = Color3.fromRGB(25, 37, 56),
    accent = Color3.fromRGB(87, 176, 255),
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
        if star.Parent then
            star:Destroy()
        end
    end)
    travel:Play()
end

function UI.createRoot(playerGui, starsEnabled)
    assert(playerGui, "playerGui is required")
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GhostXDeveloperDashboard"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.DisplayOrder = 100
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

    local stars = Instance.new("Frame")
    stars.Name = "Stars"
    stars.Size = UDim2.fromScale(1, 1)
    stars.BackgroundTransparency = 1
    stars.ClipsDescendants = true
    stars.Parent = backdrop

    if starsEnabled ~= false then
        task.spawn(function()
            while screenGui.Parent and stars.Parent do
                createShootingStar(stars)
                task.wait(math.random(28, 70) / 10)
            end
        end)
    end
    return screenGui
end

function UI.createPanel(parent, title, subtitle)
    assert(parent, "parent is required")
    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Size = UDim2.new(0.82, 0, 0.76, 0)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.BackgroundColor3 = COLORS.surface
    panel.BackgroundTransparency = 0.14
    panel.BorderSizePixel = 0
    panel.ClipsDescendants = true
    panel.Parent = parent
    applyCorner(panel, 14)

    local constraint = Instance.new("UISizeConstraint")
    constraint.MinSize = Vector2.new(520, 360)
    constraint.MaxSize = Vector2.new(980, 650)
    constraint.Parent = panel

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(137, 190, 232)
    stroke.Transparency = 0.62
    stroke.Parent = panel

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, -40, 0, 68)
    header.Position = UDim2.fromOffset(20, 16)
    header.BackgroundTransparency = 1
    header.Parent = panel

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 32)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = title or "Dashboard"
    titleLabel.TextColor3 = COLORS.text
    titleLabel.TextSize = 22
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = header

    local subtitleLabel = Instance.new("TextLabel")
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

    local stroke = Instance.new("UIStroke")
    stroke.Color = accentColor or COLORS.accent
    stroke.Transparency = 0.78
    stroke.Parent = card

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
    reading.Text = tostring(value)
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
        TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(87, 176, 255)}):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.surfaceRaised}):Play()
    end)
    button.Activated:Connect(callback)
    return button
end

function UI.createToggle(parent, label, initialValue, callback)
    local toggle = UI.createButton(parent, label, function()
        initialValue = not initialValue
        toggle.Text = string.format("%s    %s", label, initialValue and "ON" or "OFF")
        callback(initialValue)
    end)
    toggle.TextXAlignment = Enum.TextXAlignment.Left
    toggle.Text = string.format("%s    %s", label, initialValue and "ON" or "OFF")
    return toggle
end

return UI
