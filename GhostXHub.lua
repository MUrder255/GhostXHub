--[[
    GhostX Hub v3
    Advanced developer dashboard for Roblox experiences you own or are
    authorized to test.

    This file is intentionally self-contained so it can be used as a LocalScript
    or loaded from a trusted raw GitHub URL.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

if not RunService:IsClient() then
    error("GhostX Hub must run on the Roblox client", 0)
end

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

for _, guiName in ipairs({ "GhostXDeveloperDashboard", "GhostXHub" }) do
    local oldGui = PlayerGui:FindFirstChild(guiName)
    if oldGui then
        oldGui:Destroy()
    end
end

local Settings = {
    title = "GHOSTX HUB",
    subtitle = "Developer Menu",
    version = "3.2.0",
    toggleKey = Enum.KeyCode.RightShift,
    showDiagnostics = false,
    galaxyMotion = true,
    particlesEnabled = true,
    reducedMotion = false,
    compactMetrics = false,
    developerVisionEnabled = false,
    visionShowNames = true,
    visionShowHealth = true,
    visionShowDistance = true,
    visionTeamCheck = false,
    visionThroughWalls = false,
    visionMaxDistance = 1000,
}

local Theme = {
    void = Color3.fromRGB(3, 5, 14),
    space = Color3.fromRGB(7, 10, 27),
    panel = Color3.fromRGB(12, 16, 35),
    panelRaised = Color3.fromRGB(18, 24, 49),
    surface = Color3.fromRGB(23, 30, 57),
    surfaceHover = Color3.fromRGB(32, 43, 76),
    stroke = Color3.fromRGB(87, 105, 165),
    text = Color3.fromRGB(241, 245, 255),
    muted = Color3.fromRGB(145, 157, 194),
    faint = Color3.fromRGB(91, 103, 139),
    accent = Color3.fromRGB(111, 124, 255),
    accentBright = Color3.fromRGB(74, 210, 255),
    purple = Color3.fromRGB(178, 92, 255),
    pink = Color3.fromRGB(255, 93, 190),
    success = Color3.fromRGB(82, 224, 164),
    warning = Color3.fromRGB(255, 191, 87),
    danger = Color3.fromRGB(255, 104, 125),
}

local Icons = {
    overview = "⌂",
    diagnostics = "⌁",
    modules = "◈",
    settings = "⚙",
    about = "✦",
    players = "♙",
    fps = "↯",
    ping = "⌁",
    memory = "▣",
    shield = "◇",
    galaxy = "✧",
    activity = "≋",
    check = "✓",
    arrow = "›",
    terminal = ">_",
}

local Dashboard = {
    mounted = false,
    booted = false,
    minimized = false,
    connections = {},
    logs = {},
    pages = {},
    tabButtons = {},
    toggleRenderers = {},
    metrics = {},
}

local root
local galaxyRoot
local farStars
local nearStars
local nebulaLayer
local shell
local shellScale
local shellBody
local loader
local diagnosticsOverlay
local toastContainer
local logLabel
local healthValue
local currentPageName
local starGeneration = 0
local startedAt = os.clock()
local frameCount = 0
local frameElapsed = 0
local currentFps = 0

local function track(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(Dashboard.connections, connection)
    return connection
end

local function create(className, properties, parent)
    local instance = Instance.new(className)
    for property, value in pairs(properties or {}) do
        instance[property] = value
    end
    instance.Parent = parent
    return instance
end

local function corner(parent, radius)
    return create("UICorner", {
        CornerRadius = UDim.new(0, radius),
    }, parent)
end

local function stroke(parent, color, transparency, thickness)
    return create("UIStroke", {
        Color = color or Theme.stroke,
        Transparency = transparency or 0,
        Thickness = thickness or 1,
    }, parent)
end

local function padding(parent, top, right, bottom, left)
    return create("UIPadding", {
        PaddingTop = UDim.new(0, top or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        PaddingLeft = UDim.new(0, left or 0),
    }, parent)
end

local function gradient(parent, colors, rotation, transparency)
    local points = {}
    for index, item in ipairs(colors) do
        local position = (#colors == 1) and 0 or (index - 1) / (#colors - 1)
        table.insert(points, ColorSequenceKeypoint.new(position, item))
    end
    return create("UIGradient", {
        Color = ColorSequence.new(points),
        Rotation = rotation or 0,
        Transparency = transparency or NumberSequence.new(0),
    }, parent)
end

local function animate(instance, duration, properties, style, direction)
    if Settings.reducedMotion then
        for property, value in pairs(properties) do
            instance[property] = value
        end
        return nil
    end

    local animation = TweenService:Create(
        instance,
        TweenInfo.new(
            duration,
            style or Enum.EasingStyle.Quart,
            direction or Enum.EasingDirection.Out
        ),
        properties
    )
    animation:Play()
    return animation
end

local function safeCall(label, callback)
    local ok, value = pcall(callback)
    if not ok then
        warn(string.format("[GhostX] %s failed: %s", label, tostring(value)))
        return false, value
    end
    return true, value
end

local function formatDuration(seconds)
    seconds = math.max(0, math.floor(seconds))
    local minutes = math.floor(seconds / 60)
    local hours = math.floor(minutes / 60)
    return string.format("%02d:%02d:%02d", hours, minutes % 60, seconds % 60)
end

local function getPing()
    local ok, value = pcall(function()
        return Stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
    end)
    return ok and value or "N/A"
end

local function pingNumber(value)
    return tonumber(tostring(value):match("[%d%.]+")) or 0
end

local function getMemory()
    local ok, value = pcall(function()
        return Stats:GetTotalMemoryUsageMb()
    end)
    if ok then
        return value, string.format("%.0f MB", value)
    end
    return 0, "N/A"
end

local function getPlatform()
    local ok, value = pcall(function()
        return UserInputService:GetPlatform().Name
    end)
    return ok and value or "Unknown"
end

local function setSetting(name, value)
    assert(Settings[name] ~= nil, string.format("Unknown setting: %s", tostring(name)))
    Settings[name] = value
    for _, renderer in ipairs(Dashboard.toggleRenderers[name] or {}) do
        renderer(value, false)
    end
    return value
end

local function toggleSetting(name)
    assert(type(Settings[name]) == "boolean", string.format("Setting is not boolean: %s", tostring(name)))
    return setSetting(name, not Settings[name])
end

local function refreshLog()
    if not logLabel then
        return
    end
    logLabel.Text = #Dashboard.logs > 0 and table.concat(Dashboard.logs, "\n") or "No events yet."
end

local function addLog(message, level)
    local labels = {
        info = "INFO ",
        success = "READY",
        warning = "WARN ",
        error = "ERROR",
    }
    local entry = string.format(
        "[%s] %s  %s",
        os.date("%H:%M:%S"),
        labels[level or "info"] or labels.info,
        tostring(message)
    )
    table.insert(Dashboard.logs, 1, entry)
    while #Dashboard.logs > 9 do
        table.remove(Dashboard.logs)
    end
    refreshLog()
end

local function notify(title, message, color)
    if not toastContainer or not toastContainer.Parent then
        return
    end

    local toast = create("CanvasGroup", {
        Name = "Toast",
        Size = UDim2.fromOffset(320, 76),
        BackgroundColor3 = Theme.panelRaised,
        BackgroundTransparency = 0.02,
        BorderSizePixel = 0,
        GroupTransparency = 1,
    }, toastContainer)
    corner(toast, 11)
    stroke(toast, color or Theme.accentBright, 0.48, 1)

    local accent = create("Frame", {
        Size = UDim2.fromOffset(4, 48),
        Position = UDim2.fromOffset(9, 14),
        BackgroundColor3 = color or Theme.accentBright,
        BorderSizePixel = 0,
    }, toast)
    corner(accent, 2)

    create("TextLabel", {
        Size = UDim2.new(1, -42, 0, 22),
        Position = UDim2.fromOffset(26, 12),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = title,
        TextColor3 = Theme.text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, toast)

    create("TextLabel", {
        Size = UDim2.new(1, -42, 0, 34),
        Position = UDim2.fromOffset(26, 34),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = message,
        TextColor3 = Theme.muted,
        TextSize = 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
    }, toast)

    toast.Position = UDim2.fromOffset(32, 0)
    animate(toast, 0.28, {
        GroupTransparency = 0,
        Position = UDim2.fromOffset(0, 0),
    })

    task.delay(3.2, function()
        if toast.Parent then
            local fade = animate(toast, 0.24, {
                GroupTransparency = 1,
                Position = UDim2.fromOffset(28, 0),
            })
            if fade then
                fade.Completed:Wait()
            end
            if toast.Parent then
                toast:Destroy()
            end
        end
    end)
end

Dashboard.notify = notify

-- Authorization guard modules keep the dashboard useful for development
-- without targeting players or revealing them through world geometry.
local Aimbot = {
    active = false,
    mode = "Protected",
}

function Aimbot.start()
    Aimbot.active = false
    return false, "Targeting guard blocked player aim assistance"
end

function Aimbot.stop()
    Aimbot.active = false
    return true
end

function Aimbot.getStatus()
    return {
        active = Aimbot.active,
        mode = Aimbot.mode,
        message = "Use an authorized NPC training system",
    }
end

local Esp = {
    enabled = false,
    authorized = false,
    mode = "Developer Vision",
    reason = "Authorization has not been checked",
    entries = {},
    updateAccumulator = 0,
}

local function authorizeDeveloperVision()
    if RunService:IsStudio() then
        return true, "Authorized Roblox Studio session"
    end

    if game.CreatorType == Enum.CreatorType.User and LocalPlayer.UserId == game.CreatorId then
        return true, "Authorized experience creator"
    end

    local authorizer = ReplicatedStorage:FindFirstChild("GhostXAuthorize")
    if authorizer and authorizer:IsA("RemoteFunction") then
        local ok, result = pcall(function()
            return authorizer:InvokeServer("DeveloperVision")
        end)
        if ok and result == true then
            return true, "Authorized by the experience server"
        end
    end

    return false, "Developer Vision requires Studio, the personal experience creator, or GhostXAuthorize approval"
end

local function destroyVisionEntry(player)
    local entry = Esp.entries[player]
    if not entry then
        return
    end

    if entry.highlight then
        entry.highlight:Destroy()
    end
    if entry.billboard then
        entry.billboard:Destroy()
    end
    Esp.entries[player] = nil
end

local function clearVisionEntries()
    local players = {}
    for player in pairs(Esp.entries) do
        table.insert(players, player)
    end
    for _, player in ipairs(players) do
        destroyVisionEntry(player)
    end
end

local function ensureVisionEntry(player)
    if player == LocalPlayer or Esp.entries[player] then
        return Esp.entries[player]
    end

    local highlight = create("Highlight", {
        Name = "GhostXDeveloperHighlight",
        FillColor = Theme.danger,
        FillTransparency = 0.76,
        OutlineColor = Theme.text,
        OutlineTransparency = 0.08,
        DepthMode = Enum.HighlightDepthMode.Occluded,
        Enabled = false,
    }, PlayerGui)

    local billboard = create("BillboardGui", {
        Name = "GhostXDeveloperInfo",
        Size = UDim2.fromOffset(170, 48),
        StudsOffset = Vector3.new(0, 3.25, 0),
        AlwaysOnTop = false,
        LightInfluence = 0,
        MaxDistance = Settings.visionMaxDistance,
        Enabled = false,
    }, PlayerGui)

    local panel = create("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Theme.panel,
        BackgroundTransparency = 0.16,
        BorderSizePixel = 0,
    }, billboard)
    corner(panel, 8)
    stroke(panel, Theme.stroke, 0.48, 1)

    local accent = create("Frame", {
        Size = UDim2.fromOffset(3, 30),
        Position = UDim2.fromOffset(7, 9),
        BackgroundColor3 = Theme.danger,
        BorderSizePixel = 0,
    }, panel)
    corner(accent, 2)

    local nameLabel = create("TextLabel", {
        Size = UDim2.new(1, -25, 0, 20),
        Position = UDim2.fromOffset(18, 5),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = player.DisplayName,
        TextColor3 = Theme.text,
        TextSize = 11,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, panel)

    local detailLabel = create("TextLabel", {
        Size = UDim2.new(1, -25, 0, 17),
        Position = UDim2.fromOffset(18, 25),
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        Text = "Waiting for character",
        TextColor3 = Theme.muted,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, panel)

    local entry = {
        highlight = highlight,
        billboard = billboard,
        accent = accent,
        name = nameLabel,
        detail = detailLabel,
    }
    Esp.entries[player] = entry
    return entry
end

local function visionColor(player)
    local sameTeam = LocalPlayer.Team ~= nil and player.Team == LocalPlayer.Team
    return sameTeam and Theme.success or Theme.danger, sameTeam
end

local function updateVisionEntry(player, entry)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    local head = character and character:FindFirstChild("Head")
    local camera = workspace.CurrentCamera

    if not character or not humanoid or not rootPart or not head or not camera or humanoid.Health <= 0 then
        entry.highlight.Enabled = false
        entry.billboard.Enabled = false
        return
    end

    local distance = (camera.CFrame.Position - rootPart.Position).Magnitude
    local color, sameTeam = visionColor(player)
    local visible = distance <= Settings.visionMaxDistance
        and not (Settings.visionTeamCheck and sameTeam)

    entry.highlight.Adornee = character
    entry.highlight.FillColor = color
    entry.highlight.OutlineColor = color:Lerp(Theme.text, 0.58)
    entry.highlight.DepthMode = Settings.visionThroughWalls
        and Enum.HighlightDepthMode.AlwaysOnTop
        or Enum.HighlightDepthMode.Occluded
    entry.highlight.Enabled = visible

    entry.billboard.Adornee = head
    entry.billboard.AlwaysOnTop = Settings.visionThroughWalls
    entry.billboard.MaxDistance = Settings.visionMaxDistance
    entry.billboard.Enabled = visible
        and (Settings.visionShowNames or Settings.visionShowHealth or Settings.visionShowDistance)

    entry.accent.BackgroundColor3 = color
    entry.name.Text = Settings.visionShowNames
        and string.format("%s  @%s", player.DisplayName, player.Name)
        or "DEVELOPER TARGET"

    local details = {}
    if Settings.visionShowHealth then
        table.insert(details, string.format("%d HP", math.max(0, math.floor(humanoid.Health + 0.5))))
    end
    if Settings.visionShowDistance then
        table.insert(details, string.format("%d studs", math.floor(distance + 0.5)))
    end
    entry.detail.Text = #details > 0 and table.concat(details, "  •  ") or "Authorized diagnostics"
end

function Esp.enable()
    local authorized, reason = authorizeDeveloperVision()
    Esp.authorized = authorized
    Esp.reason = reason

    if not authorized then
        Esp.enabled = false
        setSetting("developerVisionEnabled", false)
        return false, reason
    end

    Esp.enabled = true
    setSetting("developerVisionEnabled", true)
    for _, player in ipairs(Players:GetPlayers()) do
        ensureVisionEntry(player)
    end
    return true, reason
end

function Esp.disable()
    Esp.enabled = false
    setSetting("developerVisionEnabled", false)
    clearVisionEntries()
    return true, "Developer Vision disabled"
end

function Esp.update(deltaTime)
    if not Esp.enabled then
        return
    end

    Esp.updateAccumulator = Esp.updateAccumulator + deltaTime
    if Esp.updateAccumulator < 0.1 then
        return
    end
    Esp.updateAccumulator = 0

    for _, player in ipairs(Players:GetPlayers()) do
        local entry = ensureVisionEntry(player)
        if entry then
            updateVisionEntry(player, entry)
        end
    end
end

function Esp.playerAdded(player)
    if Esp.enabled then
        ensureVisionEntry(player)
    end
end

function Esp.playerRemoving(player)
    destroyVisionEntry(player)
end

function Esp.getStatus()
    return {
        enabled = Esp.enabled,
        authorized = Esp.authorized,
        mode = Esp.mode,
        message = Esp.reason,
    }
end

Dashboard.modules = {
    Aimbot = Aimbot,
    Esp = Esp,
}
Dashboard.settings = Settings

local function createGalaxy(parent)
    galaxyRoot = create("Frame", {
        Name = "Galaxy",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Theme.void,
        BackgroundTransparency = 0.48,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, parent)

    gradient(galaxyRoot, {
        Color3.fromRGB(5, 7, 19),
        Color3.fromRGB(11, 13, 32),
        Color3.fromRGB(5, 15, 27),
    }, 28)

    nebulaLayer = create("Frame", {
        Name = "Nebulae",
        Size = UDim2.new(1, 80, 1, 80),
        Position = UDim2.fromOffset(-40, -40),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, galaxyRoot)

    local nebulae = {
        {
            position = UDim2.fromScale(0.57, 0.06),
            size = UDim2.fromOffset(430, 290),
            colors = { Color3.fromRGB(43, 74, 165), Color3.fromRGB(28, 132, 162) },
            rotation = 128,
        },
    }

    for index, data in ipairs(nebulae) do
        local cloud = create("Frame", {
            Name = "Nebula" .. index,
            Size = data.size,
            Position = data.position,
            BackgroundColor3 = data.colors[1],
            BackgroundTransparency = 0.93,
            BorderSizePixel = 0,
            Rotation = data.rotation,
        }, nebulaLayer)
        corner(cloud, 999)
        gradient(
            cloud,
            data.colors,
            data.rotation,
            NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.84),
                NumberSequenceKeypoint.new(0.48, 0.94),
                NumberSequenceKeypoint.new(1, 1),
            })
        )
    end

    farStars = create("Frame", {
        Name = "FarStars",
        Size = UDim2.new(1, 40, 1, 40),
        Position = UDim2.fromOffset(-20, -20),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, galaxyRoot)

    nearStars = create("Frame", {
        Name = "NearStars",
        Size = UDim2.new(1, 60, 1, 60),
        Position = UDim2.fromOffset(-30, -30),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, galaxyRoot)

    local random = Random.new(255)
    for index = 1, 45 do
        local near = index % 5 == 0
        local size = near and random:NextInteger(2, 3) or 1
        local star = create("Frame", {
            Name = "Star" .. index,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.fromOffset(size, size),
            Position = UDim2.fromScale(random:NextNumber(), random:NextNumber()),
            BackgroundColor3 = (index % 11 == 0) and Theme.accentBright or Theme.text,
            BackgroundTransparency = random:NextNumber(0.56, 0.88),
            BorderSizePixel = 0,
        }, near and nearStars or farStars)
        corner(star, size)

        if index % 15 == 0 then
            TweenService:Create(
                star,
                TweenInfo.new(
                    random:NextNumber(2.2, 3.8),
                    Enum.EasingStyle.Sine,
                    Enum.EasingDirection.InOut,
                    -1,
                    true
                ),
                {
                    BackgroundTransparency = 0.42,
                    Size = UDim2.fromOffset(size + 1, size + 1),
                }
            ):Play()
        end
    end

    create("Frame", {
        Name = "Vignette",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.96,
        BorderSizePixel = 0,
    }, galaxyRoot)
end

local function createMeteor()
    if not nearStars or not nearStars.Parent or not Settings.particlesEnabled then
        return
    end

    local meteor = create("Frame", {
        Name = "Meteor",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(math.random(28, 48), 1),
        Position = UDim2.fromScale(math.random(-8, 58) / 100, math.random(-8, 38) / 100),
        Rotation = math.random(28, 38),
        BackgroundColor3 = Theme.accentBright,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
    }, nearStars)
    corner(meteor, 2)
    gradient(
        meteor,
        { Theme.accentBright, Theme.text },
        0,
        NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.52, 0.16),
            NumberSequenceKeypoint.new(1, 0.72),
        })
    )

    local flight = TweenService:Create(
        meteor,
        TweenInfo.new(math.random(14, 22) / 10, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {
            Position = UDim2.fromScale(math.random(88, 118) / 100, math.random(72, 108) / 100),
            BackgroundTransparency = 1,
        }
    )
    flight.Completed:Connect(function()
        if meteor.Parent then
            meteor:Destroy()
        end
    end)
    flight:Play()
end

local function restartGalaxyMotion()
    starGeneration = starGeneration + 1
    local generation = starGeneration

    if not Settings.particlesEnabled or Settings.reducedMotion then
        if nearStars then
            for _, item in ipairs(nearStars:GetChildren()) do
                if item.Name == "Meteor" then
                    item:Destroy()
                end
            end
        end
        return
    end

    task.spawn(function()
        while Dashboard.mounted and generation == starGeneration do
            createMeteor()
            task.wait(math.random(90, 160) / 10)
        end
    end)
end

local function makeIcon(parent, symbol, color, size)
    local holder = create("Frame", {
        Size = UDim2.fromOffset(size or 38, size or 38),
        BackgroundColor3 = color or Theme.accent,
        BackgroundTransparency = 0.78,
        BorderSizePixel = 0,
    }, parent)
    corner(holder, math.floor((size or 38) * 0.28))
    stroke(holder, color or Theme.accent, 0.58, 1)

    create("TextLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = symbol,
        TextColor3 = color or Theme.accentBright,
        TextSize = math.floor((size or 38) * 0.42),
    }, holder)
    return holder
end

local function makeButton(parent, text, callback, options)
    options = options or {}
    local button = create("TextButton", {
        Name = text:gsub("[^%w]", ""),
        Size = options.size or UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = options.color or Theme.surface,
        BackgroundTransparency = options.transparency or 0.08,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.GothamMedium,
        Text = options.icon and ("   " .. options.icon .. "    " .. text) or text,
        TextColor3 = options.textColor or Theme.text,
        TextSize = options.textSize or 12,
        TextXAlignment = options.align or Enum.TextXAlignment.Center,
    }, parent)
    corner(button, options.radius or 9)
    stroke(button, options.strokeColor or Theme.stroke, options.strokeTransparency or 0.68, 1)

    local scaler = create("UIScale", { Scale = 1 }, button)
    track(button.MouseEnter, function()
        animate(button, 0.16, { BackgroundColor3 = options.hoverColor or Theme.surfaceHover })
        animate(scaler, 0.16, { Scale = 1.015 })
    end)
    track(button.MouseLeave, function()
        animate(button, 0.16, { BackgroundColor3 = options.color or Theme.surface })
        animate(scaler, 0.16, { Scale = 1 })
    end)
    track(button.MouseButton1Down, function()
        animate(scaler, 0.08, { Scale = 0.975 })
    end)
    track(button.MouseButton1Up, function()
        animate(scaler, 0.1, { Scale = 1.015 })
    end)
    track(button.Activated, function()
        local ok, result = safeCall(text, callback)
        if not ok then
            addLog(string.format("%s: %s", text, tostring(result)), "error")
            notify("Action failed", tostring(result), Theme.danger)
        end
    end)
    return button
end

local function makeToggle(parent, title, description, settingName, changed)
    local row = create("Frame", {
        Name = title:gsub("[^%w]", ""),
        Size = UDim2.new(1, 0, 0, 64),
        BackgroundColor3 = Theme.surface,
        BackgroundTransparency = 0.18,
        BorderSizePixel = 0,
    }, parent)
    corner(row, 10)
    stroke(row, Theme.stroke, 0.82, 1)

    create("TextLabel", {
        Size = UDim2.new(1, -90, 0, 22),
        Position = UDim2.fromOffset(16, 10),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = title,
        TextColor3 = Theme.text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)

    create("TextLabel", {
        Size = UDim2.new(1, -90, 0, 20),
        Position = UDim2.fromOffset(16, 33),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = description,
        TextColor3 = Theme.muted,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)

    local switch = create("TextButton", {
        Size = UDim2.fromOffset(52, 28),
        Position = UDim2.new(1, -68, 0.5, -14),
        BackgroundColor3 = Theme.surfaceHover,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
    }, row)
    corner(switch, 14)

    local knob = create("Frame", {
        Size = UDim2.fromOffset(22, 22),
        Position = UDim2.fromOffset(3, 3),
        BackgroundColor3 = Theme.muted,
        BorderSizePixel = 0,
    }, switch)
    corner(knob, 11)

    local function render(value, instant)
        local switchColor = value and Theme.accent or Theme.surfaceHover
        local knobColor = value and Theme.text or Theme.muted
        local knobPosition = value and UDim2.fromOffset(27, 3) or UDim2.fromOffset(3, 3)
        if instant or Settings.reducedMotion then
            switch.BackgroundColor3 = switchColor
            knob.BackgroundColor3 = knobColor
            knob.Position = knobPosition
        else
            animate(switch, 0.16, { BackgroundColor3 = switchColor })
            animate(knob, 0.16, {
                BackgroundColor3 = knobColor,
                Position = knobPosition,
            })
        end
    end

    Dashboard.toggleRenderers[settingName] = Dashboard.toggleRenderers[settingName] or {}
    table.insert(Dashboard.toggleRenderers[settingName], render)
    render(Settings[settingName], true)

    track(switch.Activated, function()
        local value = toggleSetting(settingName)
        if changed then
            changed(value)
        end
        addLog(string.format("%s set to %s", title, value and "ON" or "OFF"))
    end)

    return row
end

local function makeSection(parent, title, description, icon)
    local height = description and 48 or 28
    local section = create("Frame", {
        Size = UDim2.new(1, 0, 0, height),
        BackgroundTransparency = 1,
    }, parent)

    if icon then
        local iconLabel = create("TextLabel", {
            Size = UDim2.fromOffset(24, 24),
            BackgroundColor3 = Theme.accent,
            BackgroundTransparency = 0.84,
            BorderSizePixel = 0,
            Font = Enum.Font.GothamBold,
            Text = icon,
            TextColor3 = Theme.accentBright,
            TextSize = 12,
        }, section)
        corner(iconLabel, 7)
    end

    create("TextLabel", {
        Size = UDim2.new(1, icon and -34 or 0, 0, 24),
        Position = UDim2.fromOffset(icon and 34 or 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = title,
        TextColor3 = Theme.text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, section)

    if description then
        create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 18),
            Position = UDim2.fromOffset(0, 27),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            Text = description,
            TextColor3 = Theme.muted,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, section)
    end
    return section
end

local function makeMetricCard(parent, key, label, icon, color)
    local card = create("Frame", {
        Name = key,
        BackgroundColor3 = Theme.panelRaised,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
    }, parent)
    corner(card, 13)
    stroke(card, color, 0.7, 1)

    local iconHolder = makeIcon(card, icon, color, 34)
    iconHolder.Position = UDim2.fromOffset(14, 14)

    create("TextLabel", {
        Size = UDim2.new(1, -64, 0, 18),
        Position = UDim2.fromOffset(58, 14),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = label,
        TextColor3 = Theme.muted,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, card)

    local value = create("TextLabel", {
        Size = UDim2.new(1, -64, 0, 28),
        Position = UDim2.fromOffset(58, 32),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "--",
        TextColor3 = Theme.text,
        TextSize = 19,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, card)

    local state = create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 18),
        Position = UDim2.new(0, 14, 1, -25),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = "Live telemetry",
        TextColor3 = color,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, card)

    Dashboard.metrics[key] = {
        value = value,
        state = state,
        color = color,
    }
    return card
end

local function makeInfoRow(parent, label, value, icon)
    local row = create("Frame", {
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = Theme.surface,
        BackgroundTransparency = 0.24,
        BorderSizePixel = 0,
    }, parent)
    corner(row, 8)

    create("TextLabel", {
        Size = UDim2.fromOffset(30, 44),
        Position = UDim2.fromOffset(8, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = icon or "•",
        TextColor3 = Theme.accentBright,
        TextSize = 12,
    }, row)

    create("TextLabel", {
        Size = UDim2.new(0.48, -36, 1, 0),
        Position = UDim2.fromOffset(40, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = label,
        TextColor3 = Theme.muted,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)

    local valueLabel = create("TextLabel", {
        Size = UDim2.new(0.52, -14, 1, 0),
        Position = UDim2.new(0.48, 0, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = tostring(value),
        TextColor3 = Theme.text,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, row)
    return valueLabel
end

local function makePerformanceRow(parent, label, color)
    local row = create("Frame", {
        Size = UDim2.new(1, 0, 0, 58),
        BackgroundColor3 = Theme.surface,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
    }, parent)
    corner(row, 9)

    create("TextLabel", {
        Size = UDim2.new(0.5, -16, 0, 22),
        Position = UDim2.fromOffset(16, 8),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = label,
        TextColor3 = Theme.text,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)

    local value = create("TextLabel", {
        Size = UDim2.new(0.5, -16, 0, 22),
        Position = UDim2.new(0.5, 0, 0, 8),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "--",
        TextColor3 = color,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, row)

    local trackBar = create("Frame", {
        Size = UDim2.new(1, -32, 0, 5),
        Position = UDim2.fromOffset(16, 40),
        BackgroundColor3 = Theme.void,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
    }, row)
    corner(trackBar, 3)

    local fill = create("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = color,
        BorderSizePixel = 0,
    }, trackBar)
    corner(fill, 3)
    gradient(fill, { color, Theme.accentBright }, 0)

    return {
        value = value,
        fill = fill,
    }
end

local function makeModuleCard(parent, title, subtitle, icon, color, stateText, callback)
    local card = create("Frame", {
        Size = UDim2.new(1, 0, 0, 112),
        BackgroundColor3 = Theme.panelRaised,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
    }, parent)
    corner(card, 12)
    stroke(card, color, 0.74, 1)

    local iconHolder = makeIcon(card, icon, color, 42)
    iconHolder.Position = UDim2.fromOffset(14, 15)

    create("TextLabel", {
        Size = UDim2.new(1, -190, 0, 22),
        Position = UDim2.fromOffset(70, 13),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = title,
        TextColor3 = Theme.text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, card)

    create("TextLabel", {
        Size = UDim2.new(1, -190, 0, 34),
        Position = UDim2.fromOffset(70, 36),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = subtitle,
        TextColor3 = Theme.muted,
        TextSize = 10,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
    }, card)

    local state = create("TextLabel", {
        Size = UDim2.fromOffset(100, 22),
        Position = UDim2.new(1, -116, 0, 15),
        BackgroundColor3 = color,
        BackgroundTransparency = 0.82,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        Text = stateText,
        TextColor3 = color,
        TextSize = 9,
    }, card)
    corner(state, 11)
    stroke(state, color, 0.64, 1)

    local action = makeButton(card, "RUN CHECK", callback, {
        size = UDim2.fromOffset(112, 32),
        color = Theme.surface,
        hoverColor = Theme.surfaceHover,
        textSize = 9,
        radius = 8,
    })
    action.Position = UDim2.new(1, -126, 1, -45)
    return card
end

local function createPage(parent, name)
    local group = create("CanvasGroup", {
        Name = name .. "Page",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        GroupTransparency = 1,
        Visible = false,
    }, parent)

    local scroll = create("ScrollingFrame", {
        Name = "Scroll",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.accent,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, group)
    padding(scroll, 4, 10, 18, 4)
    create("UIListLayout", {
        Padding = UDim.new(0, 11),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, scroll)

    Dashboard.pages[name] = {
        group = group,
        scroll = scroll,
    }
    return scroll
end

local function selectPage(name, instant)
    local nextPage = Dashboard.pages[name]
    if not nextPage or name == currentPageName then
        return
    end

    local previousName = currentPageName
    local previousPage = previousName and Dashboard.pages[previousName]
    currentPageName = name

    for tabName, tab in pairs(Dashboard.tabButtons) do
        local active = tabName == name
        animate(tab.button, 0.18, {
            BackgroundColor3 = active and Theme.surfaceHover or Theme.panel,
            BackgroundTransparency = active and 0.12 or 1,
        })
        animate(tab.icon, 0.18, {
            BackgroundColor3 = active and Theme.accent or Theme.surface,
            TextColor3 = active and Theme.text or Theme.muted,
        })
        animate(tab.indicator, 0.18, {
            BackgroundTransparency = active and 0 or 1,
            Size = active and UDim2.fromOffset(3, 25) or UDim2.fromOffset(3, 8),
        })
        tab.label.TextColor3 = active and Theme.text or Theme.muted
    end

    if instant or Settings.reducedMotion then
        if previousPage then
            previousPage.group.Visible = false
            previousPage.group.GroupTransparency = 1
        end
        nextPage.group.Visible = true
        nextPage.group.Position = UDim2.fromOffset(0, 0)
        nextPage.group.GroupTransparency = 0
        return
    end

    if previousPage then
        animate(previousPage.group, 0.2, {
            Position = UDim2.fromOffset(-26, 0),
            GroupTransparency = 1,
        })
        task.delay(0.21, function()
            if previousPage.group.Parent and currentPageName ~= previousName then
                previousPage.group.Visible = false
            end
        end)
    end

    nextPage.group.Visible = true
    nextPage.group.Position = UDim2.fromOffset(28, 0)
    nextPage.group.GroupTransparency = 1
    animate(nextPage.group, 0.26, {
        Position = UDim2.fromOffset(0, 0),
        GroupTransparency = 0,
    })
end

local function buildLoader(parent)
    loader = create("CanvasGroup", {
        Name = "GhostXBoot",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        GroupTransparency = 0,
        ZIndex = 100,
    }, parent)

    local shade = create("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Theme.void,
        BackgroundTransparency = 0.58,
        BorderSizePixel = 0,
        ZIndex = 100,
    }, loader)
    gradient(shade, {
        Color3.fromRGB(5, 7, 18),
        Color3.fromRGB(10, 12, 29),
        Color3.fromRGB(5, 15, 27),
    }, 35)

    local bootCard = create("Frame", {
        Size = UDim2.fromOffset(420, 278),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.panel,
        BackgroundTransparency = 0.03,
        BorderSizePixel = 0,
        ZIndex = 102,
    }, loader)
    corner(bootCard, 15)
    stroke(bootCard, Theme.accent, 0.56, 1)
    gradient(bootCard, {
        Color3.fromRGB(22, 27, 59),
        Theme.panel,
        Color3.fromRGB(10, 22, 43),
    }, 125)

    local orbit = create("Frame", {
        Size = UDim2.fromOffset(94, 94),
        Position = UDim2.new(0.5, -47, 0, 18),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 104,
    }, bootCard)

    local ring = create("Frame", {
        Size = UDim2.fromOffset(80, 80),
        Position = UDim2.fromOffset(7, 7),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 104,
    }, orbit)
    corner(ring, 40)
    stroke(ring, Theme.accentBright, 0.48, 2)

    for index, data in ipairs({
        { 47, 0, 7, Theme.accentBright },
        { 88, 47, 5, Theme.purple },
        { 47, 88, 4, Theme.accent },
    }) do
        local dot = create("Frame", {
            Name = "OrbitDot" .. index,
            Size = UDim2.fromOffset(data[3], data[3]),
            Position = UDim2.fromOffset(data[1], data[2]),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = data[4],
            BorderSizePixel = 0,
            ZIndex = 105,
        }, orbit)
        corner(dot, data[3])
    end

    local core = create("Frame", {
        Size = UDim2.fromOffset(60, 60),
        Position = UDim2.new(0.5, -30, 0.5, -30),
        BackgroundColor3 = Theme.accent,
        BorderSizePixel = 0,
        ZIndex = 105,
    }, orbit)
    corner(core, 18)
    stroke(core, Theme.accentBright, 0.24, 2)
    gradient(core, { Theme.purple, Theme.accent, Theme.accentBright }, 135)

    create("TextLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBlack,
        Text = "GX",
        TextColor3 = Theme.text,
        TextSize = 22,
        ZIndex = 106,
    }, core)

    TweenService:Create(
        orbit,
        TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
        { Rotation = 360 }
    ):Play()
    TweenService:Create(
        core,
        TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        { BackgroundTransparency = 0.2 }
    ):Play()

    create("TextLabel", {
        Size = UDim2.new(1, -40, 0, 26),
        Position = UDim2.fromOffset(20, 116),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBlack,
        Text = "GHOSTX",
        TextColor3 = Theme.text,
        TextSize = 20,
        ZIndex = 104,
    }, bootCard)

    create("TextLabel", {
        Size = UDim2.new(1, -40, 0, 20),
        Position = UDim2.fromOffset(20, 143),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = "INITIALIZING GHOSTX MENU",
        TextColor3 = Theme.muted,
        TextSize = 9,
        ZIndex = 104,
    }, bootCard)

    local progressTrack = create("Frame", {
        Size = UDim2.new(1, -64, 0, 5),
        Position = UDim2.fromOffset(32, 190),
        BackgroundColor3 = Theme.void,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        ZIndex = 104,
    }, bootCard)
    corner(progressTrack, 3)

    local progressFill = create("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Theme.accent,
        BorderSizePixel = 0,
        ZIndex = 105,
    }, progressTrack)
    corner(progressFill, 3)
    gradient(progressFill, { Theme.purple, Theme.accent, Theme.accentBright }, 0)

    local statusText = create("TextLabel", {
        Size = UDim2.new(1, -110, 0, 20),
        Position = UDim2.fromOffset(32, 207),
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        Text = "Preparing interface...",
        TextColor3 = Theme.muted,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 104,
    }, bootCard)

    local percentText = create("TextLabel", {
        Size = UDim2.fromOffset(60, 20),
        Position = UDim2.new(1, -92, 0, 207),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "0%",
        TextColor3 = Theme.accentBright,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 104,
    }, bootCard)

    create("TextLabel", {
        Size = UDim2.new(1, -60, 0, 34),
        Position = UDim2.fromOffset(30, 238),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = "RightShift toggles the dashboard after startup",
        TextColor3 = Theme.faint,
        TextSize = 9,
        ZIndex = 104,
    }, bootCard)

    return {
        card = bootCard,
        fill = progressFill,
        status = statusText,
        percent = percentText,
    }
end

local function buildHeader(parent)
    local header = create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 64),
        BackgroundColor3 = Theme.panelRaised,
        BackgroundTransparency = 0.16,
        BorderSizePixel = 0,
        Active = true,
    }, parent)

    local headerLine = create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = Theme.accent,
        BackgroundTransparency = 0.48,
        BorderSizePixel = 0,
    }, header)
    gradient(headerLine, { Theme.accent, Theme.accentBright, Theme.purple }, 0)

    local brandIcon = makeIcon(header, "GX", Theme.accent, 36)
    brandIcon.Position = UDim2.fromOffset(14, 14)

    create("TextLabel", {
        Size = UDim2.fromOffset(180, 23),
        Position = UDim2.fromOffset(60, 9),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBlack,
        Text = Settings.title,
        TextColor3 = Theme.text,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, header)

    create("TextLabel", {
        Size = UDim2.fromOffset(240, 18),
        Position = UDim2.fromOffset(60, 32),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = Settings.subtitle .. "  •  v" .. Settings.version,
        TextColor3 = Theme.muted,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, header)

    local online = create("Frame", {
        Size = UDim2.fromOffset(112, 28),
        Position = UDim2.new(1, -214, 0, 18),
        BackgroundColor3 = Theme.success,
        BackgroundTransparency = 0.88,
        BorderSizePixel = 0,
    }, header)
    corner(online, 14)
    stroke(online, Theme.success, 0.62, 1)

    local pulse = create("Frame", {
        Size = UDim2.fromOffset(7, 7),
        Position = UDim2.fromOffset(12, 10),
        BackgroundColor3 = Theme.success,
        BorderSizePixel = 0,
    }, online)
    corner(pulse, 4)
    TweenService:Create(
        pulse,
        TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        { BackgroundTransparency = 0.65 }
    ):Play()

    create("TextLabel", {
        Size = UDim2.new(1, -30, 1, 0),
        Position = UDim2.fromOffset(27, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "SYSTEM ONLINE",
        TextColor3 = Theme.success,
        TextSize = 8,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, online)

    local minimize = makeButton(header, "—", function() end, {
        size = UDim2.fromOffset(34, 30),
        color = Theme.surface,
        textSize = 15,
        radius = 8,
    })
    minimize.Position = UDim2.new(1, -88, 0, 17)

    local close = makeButton(header, "×", function() end, {
        size = UDim2.fromOffset(34, 30),
        color = Theme.danger,
        hoverColor = Color3.fromRGB(255, 128, 146),
        textSize = 16,
        radius = 8,
    })
    close.Position = UDim2.new(1, -48, 0, 17)

    local dragging = false
    local dragInput
    local dragStart
    local startPosition

    track(header.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = shell.Position
            track(input.Changed, function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    track(header.InputChanged, function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    track(UserInputService.InputChanged, function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            shell.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end)

    -- Replace the placeholder callbacks created above with the final actions.
    track(minimize.Activated, function()
        Dashboard.minimized = not Dashboard.minimized
        shellBody.Visible = not Dashboard.minimized
        minimize.Text = Dashboard.minimized and "+" or "—"
        animate(shell, 0.24, {
            Size = Dashboard.minimized and UDim2.fromOffset(840, 64) or UDim2.fromOffset(840, 540),
        })
    end)

    track(close.Activated, function()
        Dashboard.unmount()
    end)

    return header
end

local function buildSidebar(parent)
    local sidebar = create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 175, 1, 0),
        BackgroundColor3 = Theme.panel,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
    }, parent)

    create("Frame", {
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(1, -1, 0, 0),
        BackgroundColor3 = Theme.stroke,
        BackgroundTransparency = 0.72,
        BorderSizePixel = 0,
    }, sidebar)

    create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 22),
        Position = UDim2.fromOffset(14, 10),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "NAVIGATION",
        TextColor3 = Theme.faint,
        TextSize = 8,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, sidebar)

    local nav = create("Frame", {
        Size = UDim2.new(1, -20, 0, 224),
        Position = UDim2.fromOffset(10, 34),
        BackgroundTransparency = 1,
    }, sidebar)
    create("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, nav)

    local tabData = {
        { "Overview", Icons.overview },
        { "Diagnostics", Icons.diagnostics },
        { "Modules", Icons.modules },
        { "Settings", Icons.settings },
        { "About", Icons.about },
    }

    for _, data in ipairs(tabData) do
        local name, symbol = data[1], data[2]
        local button = create("TextButton", {
            Name = name,
            Size = UDim2.new(1, 0, 0, 40),
            BackgroundColor3 = Theme.panel,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
        }, nav)
        corner(button, 9)

        local indicator = create("Frame", {
            Size = UDim2.fromOffset(3, 8),
            Position = UDim2.new(0, 0, 0.5, -4),
            BackgroundColor3 = Theme.accentBright,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, button)
        corner(indicator, 2)

        local icon = create("TextLabel", {
            Size = UDim2.fromOffset(28, 28),
            Position = UDim2.fromOffset(10, 6),
            BackgroundColor3 = Theme.surface,
            BackgroundTransparency = 0.3,
            BorderSizePixel = 0,
            Font = Enum.Font.GothamBold,
            Text = symbol,
            TextColor3 = Theme.muted,
            TextSize = 13,
        }, button)
        corner(icon, 8)

        local label = create("TextLabel", {
            Size = UDim2.new(1, -58, 1, 0),
            Position = UDim2.fromOffset(47, 0),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamMedium,
            Text = name,
            TextColor3 = Theme.muted,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, button)

        Dashboard.tabButtons[name] = {
            button = button,
            icon = icon,
            label = label,
            indicator = indicator,
        }
        track(button.MouseEnter, function()
            if currentPageName ~= name then
                animate(button, 0.14, {
                    BackgroundColor3 = Theme.surface,
                    BackgroundTransparency = 0.38,
                })
            end
        end)
        track(button.MouseLeave, function()
            if currentPageName ~= name then
                animate(button, 0.14, {
                    BackgroundColor3 = Theme.panel,
                    BackgroundTransparency = 1,
                })
            end
        end)
        track(button.Activated, function()
            selectPage(name)
        end)
    end

    local profile = create("Frame", {
        Size = UDim2.new(1, -20, 0, 68),
        Position = UDim2.new(0, 10, 1, -78),
        BackgroundColor3 = Theme.surface,
        BackgroundTransparency = 0.18,
        BorderSizePixel = 0,
    }, sidebar)
    corner(profile, 11)
    stroke(profile, Theme.stroke, 0.75, 1)

    local avatar = create("ImageLabel", {
        Size = UDim2.fromOffset(38, 38),
        Position = UDim2.fromOffset(10, 10),
        BackgroundColor3 = Theme.accent,
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        Image = "",
    }, profile)
    corner(avatar, 13)

    task.spawn(function()
        local ok, image = pcall(function()
            return Players:GetUserThumbnailAsync(
                LocalPlayer.UserId,
                Enum.ThumbnailType.HeadShot,
                Enum.ThumbnailSize.Size100x100
            )
        end)
        if ok and avatar.Parent then
            avatar.Image = image
        end
    end)

    create("TextLabel", {
        Size = UDim2.new(1, -70, 0, 20),
        Position = UDim2.fromOffset(56, 8),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = LocalPlayer.DisplayName,
        TextColor3 = Theme.text,
        TextSize = 10,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, profile)

    create("TextLabel", {
        Size = UDim2.new(1, -70, 0, 18),
        Position = UDim2.fromOffset(56, 27),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = "@" .. LocalPlayer.Name,
        TextColor3 = Theme.muted,
        TextSize = 9,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, profile)

    local role = create("TextLabel", {
        Size = UDim2.fromOffset(78, 14),
        Position = UDim2.fromOffset(56, 47),
        BackgroundColor3 = Theme.accent,
        BackgroundTransparency = 0.84,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        Text = "DEVELOPER",
        TextColor3 = Theme.accentBright,
        TextSize = 7,
    }, profile)
    corner(role, 8)
end

local function runHealthCheck()
    local aim = Aimbot.getStatus()
    local esp = Esp.getStatus()
    local checks = {
        { "Interface root", root and root.Parent ~= nil },
        { "Local player", LocalPlayer and LocalPlayer.Parent ~= nil },
        { "Render telemetry", RunService:IsClient() },
        { "Targeting guard", aim.active == false },
        { "Developer Vision authorization", not esp.enabled or esp.authorized },
        { "Galaxy engine", galaxyRoot and galaxyRoot.Parent ~= nil },
    }

    local passed = 0
    for _, check in ipairs(checks) do
        if check[2] then
            passed = passed + 1
        else
            addLog(check[1] .. " failed", "error")
        end
    end

    local percent = math.floor((passed / #checks) * 100)
    if healthValue then
        healthValue.Text = percent .. "%"
        healthValue.TextColor3 = passed == #checks and Theme.success or Theme.warning
    end

    local healthy = passed == #checks
    addLog(string.format("System scan finished: %d/%d checks passed", passed, #checks), healthy and "success" or "warning")
    notify(
        healthy and "System healthy" or "Attention required",
        string.format("%d of %d systems passed verification", passed, #checks),
        healthy and Theme.success or Theme.warning
    )
    return healthy, passed, #checks
end

local function buildOverview(parent)
    local page = createPage(parent, "Overview")

    local hero = create("Frame", {
        Size = UDim2.new(1, 0, 0, 142),
        BackgroundColor3 = Theme.panelRaised,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, page)
    corner(hero, 15)
    stroke(hero, Theme.accent, 0.58, 1)
    gradient(hero, {
        Color3.fromRGB(45, 29, 104),
        Color3.fromRGB(20, 37, 81),
        Theme.panelRaised,
    }, 18)

    create("TextLabel", {
        Size = UDim2.new(1, -210, 0, 24),
        Position = UDim2.fromOffset(22, 22),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = "WELCOME BACK, " .. string.upper(LocalPlayer.DisplayName),
        TextColor3 = Theme.accentBright,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, hero)

    create("TextLabel", {
        Size = UDim2.new(1, -210, 0, 40),
        Position = UDim2.fromOffset(22, 44),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBlack,
        Text = "Everything is ready.",
        TextColor3 = Theme.text,
        TextSize = 25,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, hero)

    create("TextLabel", {
        Size = UDim2.new(1, -220, 0, 34),
        Position = UDim2.fromOffset(22, 86),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = "Monitor the client, verify modules, and manage GhostX from one compact menu.",
        TextColor3 = Theme.muted,
        TextSize = 10,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
    }, hero)

    local heroIcon = create("TextLabel", {
        Size = UDim2.fromOffset(118, 118),
        Position = UDim2.new(1, -142, 0, 12),
        BackgroundColor3 = Theme.accent,
        BackgroundTransparency = 0.86,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBlack,
        Text = "GX",
        TextColor3 = Theme.text,
        TextSize = 38,
    }, hero)
    corner(heroIcon, 34)
    stroke(heroIcon, Theme.accentBright, 0.42, 2)
    gradient(heroIcon, { Theme.purple, Theme.accent, Theme.accentBright }, 135)

    makeSection(page, "Live telemetry", "Real-time client performance and session data", Icons.activity)
    local metricsGrid = create("Frame", {
        Size = UDim2.new(1, 0, 0, 106),
        BackgroundTransparency = 1,
    }, page)
    create("UIGridLayout", {
        CellSize = UDim2.new(0.25, -9, 1, 0),
        CellPadding = UDim2.fromOffset(12, 0),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, metricsGrid)
    makeMetricCard(metricsGrid, "players", "PLAYERS", Icons.players, Theme.success)
    makeMetricCard(metricsGrid, "fps", "FRAME RATE", Icons.fps, Theme.accentBright)
    makeMetricCard(metricsGrid, "ping", "NETWORK", Icons.ping, Theme.warning)
    makeMetricCard(metricsGrid, "memory", "MEMORY", Icons.memory, Theme.purple)

    makeSection(page, "Quick actions", nil, Icons.terminal)
    local actions = create("Frame", {
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundTransparency = 1,
    }, page)
    create("UIGridLayout", {
        CellSize = UDim2.new(0.333, -8, 1, 0),
        CellPadding = UDim2.fromOffset(12, 0),
    }, actions)
    makeButton(actions, "SYSTEM SCAN", runHealthCheck, {
        icon = Icons.check,
        color = Theme.accent,
        hoverColor = Color3.fromRGB(127, 138, 255),
        textColor = Theme.text,
        strokeColor = Theme.accentBright,
    })
    makeButton(actions, "DIAGNOSTICS", function()
        selectPage("Diagnostics")
    end, {
        icon = Icons.diagnostics,
    })
    makeButton(actions, "MODULE STATUS", function()
        selectPage("Modules")
    end, {
        icon = Icons.modules,
    })

    makeSection(page, "System health", nil, Icons.shield)
    local healthPanel = create("Frame", {
        Size = UDim2.new(1, 0, 0, 88),
        BackgroundColor3 = Theme.surface,
        BackgroundTransparency = 0.18,
        BorderSizePixel = 0,
    }, page)
    corner(healthPanel, 11)
    stroke(healthPanel, Theme.success, 0.78, 1)

    local healthIcon = makeIcon(healthPanel, Icons.shield, Theme.success, 48)
    healthIcon.Position = UDim2.fromOffset(16, 20)
    healthValue = create("TextLabel", {
        Size = UDim2.fromOffset(76, 32),
        Position = UDim2.fromOffset(77, 17),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBlack,
        Text = "--",
        TextColor3 = Theme.success,
        TextSize = 22,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, healthPanel)
    create("TextLabel", {
        Size = UDim2.new(1, -185, 0, 22),
        Position = UDim2.fromOffset(77, 46),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = "Protected module state and runtime verification",
        TextColor3 = Theme.muted,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, healthPanel)

    local healthButton = makeButton(healthPanel, "VERIFY", runHealthCheck, {
        size = UDim2.fromOffset(112, 34),
        color = Theme.surfaceHover,
        textSize = 9,
    })
    healthButton.Position = UDim2.new(1, -130, 0.5, -17)
end

local function buildDiagnostics(parent)
    local page = createPage(parent, "Diagnostics")
    makeSection(page, "Runtime diagnostics", "Read-only telemetry from the current Roblox client", Icons.diagnostics)

    local performancePanel = create("Frame", {
        Size = UDim2.new(1, 0, 0, 205),
        BackgroundTransparency = 1,
    }, page)
    create("UIGridLayout", {
        CellSize = UDim2.new(0.5, -6, 0, 58),
        CellPadding = UDim2.fromOffset(12, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, performancePanel)
    Dashboard.performanceFps = makePerformanceRow(performancePanel, "Frame stability", Theme.accentBright)
    Dashboard.performancePing = makePerformanceRow(performancePanel, "Network latency", Theme.warning)
    Dashboard.performanceMemory = makePerformanceRow(performancePanel, "Client memory", Theme.purple)
    Dashboard.performancePlayers = makePerformanceRow(performancePanel, "Server occupancy", Theme.success)

    makeSection(page, "Environment", nil, Icons.terminal)
    Dashboard.sessionValue = makeInfoRow(page, "Session uptime", "00:00:00", "◷")
    makeInfoRow(page, "Experience ID", tostring(game.PlaceId), "◆")
    makeInfoRow(page, "Player ID", tostring(LocalPlayer.UserId), "♙")
    makeInfoRow(page, "Platform", getPlatform(), "▣")
    makeInfoRow(page, "Toggle key", Settings.toggleKey.Name, "⌨")

    makeSection(page, "Event stream", "Newest dashboard events appear first", Icons.activity)
    local logPanel = create("Frame", {
        Size = UDim2.new(1, 0, 0, 174),
        BackgroundColor3 = Color3.fromRGB(6, 9, 21),
        BackgroundTransparency = 0.06,
        BorderSizePixel = 0,
    }, page)
    corner(logPanel, 11)
    stroke(logPanel, Theme.accent, 0.78, 1)

    logLabel = create("TextLabel", {
        Size = UDim2.new(1, -28, 1, -24),
        Position = UDim2.fromOffset(14, 12),
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        Text = "No events yet.",
        TextColor3 = Theme.muted,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
    }, logPanel)

    makeButton(page, "CLEAR EVENT STREAM", function()
        table.clear(Dashboard.logs)
        refreshLog()
        notify("Event stream cleared", "Dashboard history was cleared for this session", Theme.accentBright)
    end, {
        icon = "×",
        size = UDim2.new(1, 0, 0, 38),
        textSize = 9,
    })
end

local function buildModules(parent)
    local page = createPage(parent, "Modules")
    makeSection(page, "Module control", "Status checks for GhostX client components", Icons.modules)

    makeModuleCard(
        page,
        "Targeting Authorization Guard",
        "Prevents the dashboard from targeting players. Authorized NPC training can be connected separately.",
        Icons.shield,
        Theme.success,
        "PROTECTED",
        function()
            local allowed, message = Aimbot.start()
            addLog(message, allowed and "success" or "warning")
            notify("Targeting guard", message, allowed and Theme.success or Theme.warning)
        end
    )

    makeModuleCard(
        page,
        "Developer Vision",
        "Native owner-authorized highlights, names, health, distance, team filtering, and optional occlusion diagnostics.",
        Icons.diagnostics,
        Theme.accentBright,
        "OWNER ONLY",
        function()
            local allowed, message
            if Esp.enabled then
                allowed, message = Esp.disable()
            else
                allowed, message = Esp.enable()
            end
            addLog(message, allowed and "success" or "warning")
            notify("Developer Vision", message, allowed and Theme.success or Theme.warning)
        end
    )

    makeModuleCard(
        page,
        "Galaxy Rendering Engine",
        "Procedural star layers, parallax depth, nebula fields, meteors, and motion accessibility.",
        Icons.galaxy,
        Theme.purple,
        "ONLINE",
        function()
            restartGalaxyMotion()
            addLog("Galaxy rendering engine restarted", "success")
            notify("Galaxy restarted", "Particle generation is synchronized", Theme.purple)
        end
    )

    makeModuleCard(
        page,
        "Interface Animation Engine",
        "Handles tab transitions, hover states, loading sequences, switches, and notifications.",
        Icons.activity,
        Theme.accentBright,
        "ONLINE",
        function()
            notify("Animation engine", Settings.reducedMotion and "Reduced-motion mode is active" or "All animations are operational", Theme.accentBright)
            addLog("Animation engine verified", "success")
        end
    )
end

local function buildSettings(parent)
    local page = createPage(parent, "Settings")

    makeSection(page, "Developer Vision", "Available only in Studio, to the personal experience creator, or through server approval", Icons.diagnostics)

    makeToggle(page, "Enable Developer Vision", "Show authorized native player diagnostics", "developerVisionEnabled", function(value)
        local allowed, message
        if value then
            allowed, message = Esp.enable()
        else
            allowed, message = Esp.disable()
        end
        addLog(message, allowed and "success" or "warning")
        notify("Developer Vision", message, allowed and Theme.success or Theme.warning)
    end)

    makeToggle(page, "Occlusion diagnostics", "Allow authorized highlights and labels through geometry", "visionThroughWalls")
    makeToggle(page, "Team filter", "Hide players on the local developer's team", "visionTeamCheck")
    makeToggle(page, "Show names", "Display player and account names", "visionShowNames")
    makeToggle(page, "Show health", "Display current humanoid health", "visionShowHealth")
    makeToggle(page, "Show distance", "Display camera distance in studs", "visionShowDistance")

    makeSection(page, "Visual experience", "Personalize motion, particles, and interface telemetry", Icons.settings)

    makeToggle(page, "Galaxy motion", "Enable cursor parallax and subtle nebula movement", "galaxyMotion", function(value)
        notify("Galaxy motion", value and "Parallax motion enabled" or "Parallax motion paused", Theme.purple)
    end)

    makeToggle(page, "Galaxy particles", "Show procedural meteors and animated star effects", "particlesEnabled", function()
        restartGalaxyMotion()
    end)

    makeToggle(page, "Diagnostics overlay", "Display live FPS, network, and memory above the deck", "showDiagnostics", function(value)
        if diagnosticsOverlay then
            diagnosticsOverlay.Visible = value
        end
    end)

    makeToggle(page, "Reduced motion", "Replace most transitions with immediate state changes", "reducedMotion", function(value)
        if value then
            setSetting("galaxyMotion", false)
        end
        restartGalaxyMotion()
    end)

    makeToggle(page, "Compact telemetry", "Use shorter live metric descriptions", "compactMetrics")

    makeSection(page, "Dashboard controls", nil, Icons.terminal)
    makeButton(page, "RESTART GALAXY ENGINE", function()
        restartGalaxyMotion()
        notify("Galaxy engine", "Visual particle loop restarted", Theme.purple)
    end, {
        icon = Icons.galaxy,
        size = UDim2.new(1, 0, 0, 42),
    })
    makeButton(page, "RUN COMPLETE SYSTEM SCAN", runHealthCheck, {
        icon = Icons.check,
        size = UDim2.new(1, 0, 0, 42),
        color = Theme.accent,
        hoverColor = Color3.fromRGB(127, 138, 255),
    })
end

local function buildAbout(parent)
    local page = createPage(parent, "About")

    local aboutCard = create("Frame", {
        Size = UDim2.new(1, 0, 0, 242),
        BackgroundColor3 = Theme.panelRaised,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, page)
    corner(aboutCard, 16)
    stroke(aboutCard, Theme.purple, 0.55, 1)
    gradient(aboutCard, {
        Color3.fromRGB(48, 26, 91),
        Color3.fromRGB(18, 26, 61),
        Theme.panelRaised,
    }, 26)

    local logo = create("TextLabel", {
        Size = UDim2.fromOffset(100, 100),
        Position = UDim2.new(0.5, -50, 0, 24),
        BackgroundColor3 = Theme.accent,
        BackgroundTransparency = 0.28,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBlack,
        Text = "GX",
        TextColor3 = Theme.text,
        TextSize = 34,
    }, aboutCard)
    corner(logo, 30)
    stroke(logo, Theme.accentBright, 0.28, 2)
    gradient(logo, { Theme.purple, Theme.accent, Theme.accentBright }, 135)

    create("TextLabel", {
        Size = UDim2.new(1, -40, 0, 30),
        Position = UDim2.fromOffset(20, 136),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBlack,
        Text = "GHOSTX HUB",
        TextColor3 = Theme.text,
        TextSize = 22,
    }, aboutCard)

    create("TextLabel", {
        Size = UDim2.new(1, -40, 0, 22),
        Position = UDim2.fromOffset(20, 168),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = "Compact Developer Menu  •  Version " .. Settings.version,
        TextColor3 = Theme.accentBright,
        TextSize = 10,
    }, aboutCard)

    create("TextLabel", {
        Size = UDim2.new(1, -50, 0, 34),
        Position = UDim2.fromOffset(25, 198),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = "Designed for authorized diagnostics, clean modular expansion, and a premium in-game experience.",
        TextColor3 = Theme.muted,
        TextSize = 10,
        TextWrapped = true,
    }, aboutCard)

    makeSection(page, "Build information", nil, Icons.about)
    makeInfoRow(page, "Project", "MUrder255/GhostXHub", "◆")
    makeInfoRow(page, "Release channel", "Stable", "✓")
    makeInfoRow(page, "Interface build", "Compact Developer Menu", Icons.galaxy)
    makeInfoRow(page, "Runtime", "Roblox Luau Client", Icons.terminal)
    makeInfoRow(page, "Visibility key", Settings.toggleKey.Name, "⌨")
end

local function buildMainInterface()
    shell = create("CanvasGroup", {
        Name = "ControlDeck",
        Size = UDim2.fromOffset(840, 540),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.panel,
        BackgroundTransparency = 0.015,
        BorderSizePixel = 0,
        GroupTransparency = 1,
        Visible = false,
        ClipsDescendants = true,
    }, galaxyRoot)
    corner(shell, 14)
    stroke(shell, Theme.stroke, 0.5, 1)

    shellScale = create("UIScale", {
        Scale = 0.94,
    }, shell)

    buildHeader(shell)

    shellBody = create("Frame", {
        Name = "Body",
        Size = UDim2.new(1, 0, 1, -64),
        Position = UDim2.fromOffset(0, 64),
        BackgroundTransparency = 1,
    }, shell)

    buildSidebar(shellBody)

    local content = create("Frame", {
        Name = "Content",
        Size = UDim2.new(1, -199, 1, -24),
        Position = UDim2.fromOffset(187, 12),
        BackgroundTransparency = 1,
    }, shellBody)

    buildOverview(content)
    buildDiagnostics(content)
    buildModules(content)
    buildSettings(content)
    buildAbout(content)
    selectPage("Overview", true)

    diagnosticsOverlay = create("Frame", {
        Name = "DiagnosticsOverlay",
        Size = UDim2.fromOffset(228, 58),
        Position = UDim2.new(1, -244, 0, 14),
        BackgroundColor3 = Theme.panel,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Visible = Settings.showDiagnostics,
        ZIndex = 60,
    }, galaxyRoot)
    corner(diagnosticsOverlay, 11)
    stroke(diagnosticsOverlay, Theme.accentBright, 0.56, 1)

    create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.fromOffset(10, 8),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = Icons.activity .. "  GHOSTX LIVE TELEMETRY",
        TextColor3 = Theme.accentBright,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 61,
    }, diagnosticsOverlay)

    Dashboard.overlayValue = create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 26),
        Position = UDim2.fromOffset(10, 27),
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        Text = "FPS --  |  PING --  |  MEM --",
        TextColor3 = Theme.text,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 61,
    }, diagnosticsOverlay)

    toastContainer = create("Frame", {
        Name = "Notifications",
        Size = UDim2.fromOffset(304, 300),
        Position = UDim2.new(1, -320, 1, -316),
        BackgroundTransparency = 1,
        ZIndex = 80,
    }, root)
    padding(toastContainer, 0, 0, 0, 10)
    create("UIListLayout", {
        Padding = UDim.new(0, 8),
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, toastContainer)

    local function updateScale()
        local camera = workspace.CurrentCamera
        if not camera then
            return
        end
        local viewport = camera.ViewportSize
        local fit = math.min((viewport.X - 24) / 840, (viewport.Y - 24) / 540, 1)
        shellScale.Scale = math.max(0.68, fit)
    end

    updateScale()
    if workspace.CurrentCamera then
        track(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), updateScale)
    end
end

local function runBootSequence(boot)
    local stages = {
        { 0.12, "Verifying interface assets..." },
        { 0.29, "Synchronizing module guards..." },
        { 0.48, "Generating galaxy field..." },
        { 0.67, "Connecting live telemetry..." },
        { 0.84, "Finalizing GhostX menu..." },
        { 1.00, "GhostX systems ready." },
    }

    for _, stage in ipairs(stages) do
        if not Dashboard.mounted or not boot.card.Parent then
            return
        end
        boot.status.TextTransparency = 1
        boot.status.Text = stage[2]
        animate(boot.status, 0.14, { TextTransparency = 0 })
        animate(boot.fill, 0.34, { Size = UDim2.new(stage[1], 0, 1, 0) })

        local from = tonumber(boot.percent.Text:match("%d+")) or 0
        local target = math.floor(stage[1] * 100)
        for value = from, target, math.max(1, math.floor((target - from) / 6)) do
            if not Dashboard.mounted then
                return
            end
            boot.percent.Text = math.min(value, target) .. "%"
            task.wait(0.025)
        end
        boot.percent.Text = target .. "%"
        task.wait(Settings.reducedMotion and 0.04 or 0.24)
    end

    task.wait(Settings.reducedMotion and 0.04 or 0.18)
    if not Dashboard.mounted then
        return
    end

    shell.Visible = true
    shell.GroupTransparency = 1
    shellScale.Scale = shellScale.Scale * 0.94
    animate(shell, 0.42, { GroupTransparency = 0 }, Enum.EasingStyle.Quart)
    animate(shellScale, 0.5, {
        Scale = math.min(shellScale.Scale / 0.94, 1),
    }, Enum.EasingStyle.Back)

    local fade = animate(loader, 0.38, { GroupTransparency = 1 })
    if fade then
        fade.Completed:Wait()
    end
    if loader and loader.Parent then
        loader:Destroy()
        loader = nil
    end

    Dashboard.booted = true
    addLog("GhostX menu initialized", "success")
    task.defer(function()
        runHealthCheck()
        notify("Welcome to GhostX", "Developer menu is online", Theme.accentBright)
    end)
end

local function updateTelemetry(deltaTime)
    frameCount = frameCount + 1
    frameElapsed = frameElapsed + deltaTime
    if frameElapsed < 0.5 then
        return
    end

    currentFps = math.floor((frameCount / frameElapsed) + 0.5)
    frameCount = 0
    frameElapsed = 0

    local ping = getPing()
    local pingMs = pingNumber(ping)
    local memoryMb, memoryText = getMemory()
    local playerCount = #Players:GetPlayers()
    local maxPlayers = math.max(tonumber(Players.MaxPlayers) or 1, 1)

    if Dashboard.metrics.players then
        Dashboard.metrics.players.value.Text = string.format("%d / %d", playerCount, maxPlayers)
        Dashboard.metrics.players.state.Text = Settings.compactMetrics and "SERVER" or "Server occupancy"
    end
    if Dashboard.metrics.fps then
        Dashboard.metrics.fps.value.Text = tostring(currentFps)
        Dashboard.metrics.fps.state.Text = currentFps >= 55 and "Smooth" or currentFps >= 30 and "Stable" or "Limited"
    end
    if Dashboard.metrics.ping then
        Dashboard.metrics.ping.value.Text = ping
        Dashboard.metrics.ping.state.Text = pingMs <= 80 and "Low latency" or pingMs <= 150 and "Moderate" or "High latency"
    end
    if Dashboard.metrics.memory then
        Dashboard.metrics.memory.value.Text = memoryText
        Dashboard.metrics.memory.state.Text = Settings.compactMetrics and "CLIENT" or "Client allocation"
    end

    if Dashboard.performanceFps then
        Dashboard.performanceFps.value.Text = currentFps .. " FPS"
        animate(Dashboard.performanceFps.fill, 0.2, {
            Size = UDim2.new(math.clamp(currentFps / 120, 0.04, 1), 0, 1, 0),
        })
    end
    if Dashboard.performancePing then
        Dashboard.performancePing.value.Text = ping
        animate(Dashboard.performancePing.fill, 0.2, {
            Size = UDim2.new(math.clamp(1 - (pingMs / 300), 0.04, 1), 0, 1, 0),
        })
    end
    if Dashboard.performanceMemory then
        Dashboard.performanceMemory.value.Text = memoryText
        animate(Dashboard.performanceMemory.fill, 0.2, {
            Size = UDim2.new(math.clamp(memoryMb / 3000, 0.04, 1), 0, 1, 0),
        })
    end
    if Dashboard.performancePlayers then
        Dashboard.performancePlayers.value.Text = string.format("%d / %d", playerCount, maxPlayers)
        animate(Dashboard.performancePlayers.fill, 0.2, {
            Size = UDim2.new(math.clamp(playerCount / maxPlayers, 0.04, 1), 0, 1, 0),
        })
    end
    if Dashboard.sessionValue then
        Dashboard.sessionValue.Text = formatDuration(os.clock() - startedAt)
    end
    if Dashboard.overlayValue then
        Dashboard.overlayValue.Text = string.format("FPS %d  |  %s  |  %s", currentFps, ping, memoryText)
    end
end

local function updateGalaxyParallax()
    if not galaxyRoot or not galaxyRoot.Parent or not Settings.galaxyMotion or Settings.reducedMotion then
        return
    end

    local camera = workspace.CurrentCamera
    if not camera then
        return
    end
    local viewport = camera.ViewportSize
    if viewport.X <= 0 or viewport.Y <= 0 then
        return
    end

    local mouse = UserInputService:GetMouseLocation()
    local x = (mouse.X / viewport.X) - 0.5
    local y = (mouse.Y / viewport.Y) - 0.5
    if farStars then
        farStars.Position = UDim2.fromOffset(-20 - x * 3, -20 - y * 3)
    end
    if nearStars then
        nearStars.Position = UDim2.fromOffset(-30 - x * 6, -30 - y * 6)
    end
    if nebulaLayer then
        nebulaLayer.Position = UDim2.fromOffset(-40 - x * 4, -40 - y * 4)
    end
end

function Dashboard.mount()
    if Dashboard.mounted then
        return Dashboard
    end

    Dashboard.mounted = true
    Dashboard.booted = false
    Dashboard.minimized = false
    currentPageName = nil
    startedAt = os.clock()

    root = create("ScreenGui", {
        Name = "GhostXHub",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 200,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, PlayerGui)

    createGalaxy(root)
    local boot = buildLoader(galaxyRoot)
    buildMainInterface()
    restartGalaxyMotion()

    track(RunService.RenderStepped, function(deltaTime)
        updateTelemetry(deltaTime)
        updateGalaxyParallax()
        Esp.update(deltaTime)
    end)

    track(UserInputService.InputBegan, function(input, processed)
        if not processed and input.KeyCode == Settings.toggleKey and root then
            root.Enabled = not root.Enabled
        end
    end)

    track(Players.PlayerAdded, function(player)
        addLog(player.Name .. " joined the server")
        Esp.playerAdded(player)
    end)
    track(Players.PlayerRemoving, function(player)
        addLog(player.Name .. " left the server")
        Esp.playerRemoving(player)
    end)

    task.spawn(function()
        runBootSequence(boot)
    end)

    return Dashboard
end

function Dashboard.unmount()
    if not Dashboard.mounted then
        return
    end

    Dashboard.mounted = false
    Dashboard.booted = false
    Dashboard.minimized = false
    currentPageName = nil
    starGeneration = starGeneration + 1
    Esp.disable()

    for _, connection in ipairs(Dashboard.connections) do
        if connection.Connected then
            connection:Disconnect()
        end
    end
    table.clear(Dashboard.connections)
    table.clear(Dashboard.toggleRenderers)
    table.clear(Dashboard.pages)
    table.clear(Dashboard.tabButtons)
    table.clear(Dashboard.metrics)

    if root then
        root:Destroy()
        root = nil
    end
end

Dashboard.mount()
return Dashboard
