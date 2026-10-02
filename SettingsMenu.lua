--[[
    SettingsMenu
    A small, reusable settings menu built from ScreenGui, Frames and
    TextButtons. Works as a ModuleScript (require it from a LocalScript).

    local SettingsMenu = require(path.to.SettingsMenu)
    local menu = SettingsMenu.new({ title = "Settings", toggleKey = Enum.KeyCode.RightShift })

    menu:AddSection("Audio")
    local music = menu:AddToggle({
        name = "Music",
        default = true,
        callback = function(enabled) print("Music:", enabled) end,
    })
    music:Set(false)        -- fires the callback
    print(music:Get())      -- false

    menu:AddButton({ name = "Reset", callback = function() music:Set(true) end })
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Theme = {
    background = Color3.fromRGB(16, 18, 28),
    header = Color3.fromRGB(24, 27, 42),
    row = Color3.fromRGB(30, 34, 52),
    rowHover = Color3.fromRGB(40, 45, 68),
    stroke = Color3.fromRGB(70, 78, 120),
    text = Color3.fromRGB(240, 243, 255),
    muted = Color3.fromRGB(150, 158, 190),
    accent = Color3.fromRGB(111, 124, 255),
    off = Color3.fromRGB(60, 64, 86),
    knob = Color3.fromRGB(255, 255, 255),
}

local FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function create(className, props, children)
    local instance = Instance.new(className)
    for key, value in pairs(props or {}) do
        instance[key] = value
    end
    for _, child in ipairs(children or {}) do
        child.Parent = instance
    end
    return instance
end

local function corner(radius)
    return create("UICorner", { CornerRadius = UDim.new(0, radius) })
end

local function stroke(color, thickness)
    return create("UIStroke", { Color = color, Thickness = thickness or 1, Transparency = 0.4 })
end

local function safeCall(callback, ...)
    if not callback then
        return
    end
    local ok, err = pcall(callback, ...)
    if not ok then
        warn("[SettingsMenu] callback error: " .. tostring(err))
    end
end

local function addHover(button, normal, hover)
    button.MouseEnter:Connect(function()
        TweenService:Create(button, FAST, { BackgroundColor3 = hover }):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button, FAST, { BackgroundColor3 = normal }):Play()
    end)
end

local SettingsMenu = {}
SettingsMenu.__index = SettingsMenu

function SettingsMenu.new(options)
    options = options or {}
    local self = setmetatable({}, SettingsMenu)
    self.toggles = {}
    self.connections = {}
    self.order = 0
    self.toggleKey = options.toggleKey or Enum.KeyCode.RightShift

    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    local guiName = options.guiName or "SettingsMenu"
    local existing = playerGui:FindFirstChild(guiName)
    if existing then
        existing:Destroy()
    end

    self.gui = create("ScreenGui", {
        Name = guiName,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
    })

    self.window = create("Frame", {
        Name = "Window",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = options.size or UDim2.fromOffset(320, 380),
        BackgroundColor3 = Theme.background,
        BorderSizePixel = 0,
        Parent = self.gui,
    }, { corner(10), stroke(Theme.stroke, 1) })

    -- Keep the window usable on small screens.
    create("UISizeConstraint", { MaxSize = Vector2.new(420, 520), MinSize = Vector2.new(240, 200), Parent = self.window })

    local header = create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Theme.header,
        BorderSizePixel = 0,
        Parent = self.window,
    }, { corner(10) })

    create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, 0),
        Size = UDim2.new(1, -60, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = options.title or "Settings",
        TextColor3 = Theme.text,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header,
    })

    local closeButton = create("TextButton", {
        Name = "Close",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.fromOffset(26, 26),
        BackgroundColor3 = Theme.row,
        AutoButtonColor = false,
        Font = Enum.Font.GothamBold,
        Text = "×",
        TextColor3 = Theme.muted,
        TextSize = 18,
        Parent = header,
    }, { corner(6) })
    addHover(closeButton, Theme.row, Theme.rowHover)
    closeButton.Activated:Connect(function()
        self:SetVisible(false)
    end)

    self.content = create("ScrollingFrame", {
        Name = "Content",
        Position = UDim2.fromOffset(0, 44),
        Size = UDim2.new(1, 0, 1, -48),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Theme.stroke,
        Parent = self.window,
    }, {
        create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
        create("UIPadding", {
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
            PaddingTop = UDim.new(0, 6),
            PaddingBottom = UDim.new(0, 10),
        }),
    })

    self:_makeDraggable(header)

    table.insert(self.connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == self.toggleKey then
            self:SetVisible(not self.window.Visible)
        end
    end))

    self.gui.Parent = playerGui
    return self
end

function SettingsMenu:_nextOrder()
    self.order += 1
    return self.order
end

function SettingsMenu:_makeDraggable(handle)
    local dragging, dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = self.window.Position
        end
    end)

    table.insert(self.connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            self.window.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end))

    table.insert(self.connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
end

function SettingsMenu:AddSection(name)
    return create("TextLabel", {
        Name = "Section_" .. name,
        LayoutOrder = self:_nextOrder(),
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 22),
        Font = Enum.Font.GothamBold,
        Text = string.upper(name),
        TextColor3 = Theme.muted,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Bottom,
        Parent = self.content,
    })
end

function SettingsMenu:AddToggle(options)
    local name = assert(options.name, "AddToggle requires a name")
    local state = options.default == true

    local row = create("TextButton", {
        Name = "Toggle_" .. name,
        LayoutOrder = self:_nextOrder(),
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = Theme.row,
        AutoButtonColor = false,
        Text = "",
        Parent = self.content,
    }, { corner(8) })
    addHover(row, Theme.row, Theme.rowHover)

    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -70, 1, 0),
        Font = Enum.Font.Gotham,
        Text = name,
        TextColor3 = Theme.text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = row,
    })

    local track = create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(40, 20),
        BackgroundColor3 = Theme.off,
        BorderSizePixel = 0,
        Parent = row,
    }, { corner(10) })

    local knob = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 2, 0.5, 0),
        Size = UDim2.fromOffset(16, 16),
        BackgroundColor3 = Theme.knob,
        BorderSizePixel = 0,
        Parent = track,
    }, { corner(8) })

    local function render(animate)
        local trackGoal = { BackgroundColor3 = state and Theme.accent or Theme.off }
        local knobGoal = { Position = state and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0) }
        if animate then
            TweenService:Create(track, FAST, trackGoal):Play()
            TweenService:Create(knob, FAST, knobGoal):Play()
        else
            track.BackgroundColor3 = trackGoal.BackgroundColor3
            knob.Position = knobGoal.Position
        end
    end

    local toggle = {}

    function toggle:Get()
        return state
    end

    function toggle:Set(value, silent)
        value = value == true
        if value == state then
            return
        end
        state = value
        render(true)
        if not silent then
            safeCall(options.callback, state)
        end
    end

    row.Activated:Connect(function()
        toggle:Set(not state)
    end)

    render(false)
    if options.fireOnCreate then
        safeCall(options.callback, state)
    end

    self.toggles[name] = toggle
    return toggle
end

function SettingsMenu:AddButton(options)
    local name = assert(options.name, "AddButton requires a name")

    local button = create("TextButton", {
        Name = "Button_" .. name,
        LayoutOrder = self:_nextOrder(),
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = Theme.row,
        AutoButtonColor = false,
        Font = Enum.Font.GothamMedium,
        Text = name,
        TextColor3 = Theme.text,
        TextSize = 14,
        Parent = self.content,
    }, { corner(8), stroke(Theme.accent, 1) })
    addHover(button, Theme.row, Theme.rowHover)

    button.Activated:Connect(function()
        safeCall(options.callback)
    end)
    return button
end

function SettingsMenu:GetToggle(name)
    return self.toggles[name]
end

function SettingsMenu:SetVisible(visible)
    self.window.Visible = visible
end

function SettingsMenu:Destroy()
    for _, connection in ipairs(self.connections) do
        connection:Disconnect()
    end
    table.clear(self.connections)
    self.gui:Destroy()
end

return SettingsMenu
