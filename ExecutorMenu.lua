--[[
    GhostX Executor Menu
    Executor-ready rewrite of the simple "MenuUI" LocalScript.

    Usage (executor):
        loadstring(game:HttpGet("https://raw.githubusercontent.com/MUrder255/GhostXHub/main/ExecutorMenu.lua"))()

    - Parents to gethui() / CoreGui when available (falls back to PlayerGui)
    - Re-executing cleanly unloads the previous instance
    - RightShift (changeable in Settings) or the floating button toggles the menu
    - Everything the menu connects is tracked and torn down by "Unload"
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")

local player = Players.LocalPlayer

-- ===== EXECUTOR ENV =====
local genv = (getgenv and getgenv()) or _G
if genv.GhostXMenu and genv.GhostXMenu.Unload then
    pcall(genv.GhostXMenu.Unload)
end

local function guiParent()
    local ok, hui = pcall(function() return gethui and gethui() end)
    if ok and hui then return hui end
    local okCore = pcall(function() return CoreGui.Name end)
    if okCore then return CoreGui end
    return player:WaitForChild("PlayerGui")
end

local function protect(gui)
    pcall(function()
        if syn and syn.protect_gui then syn.protect_gui(gui)
        elseif protect_gui then protect_gui(gui) end
    end)
end

local function randomName()
    local s = {}
    for i = 1, 16 do s[i] = string.char(math.random(97, 122)) end
    return table.concat(s)
end

-- ===== SETTINGS =====
local Theme = {
    Accent = Color3.fromRGB(0, 200, 140),
    BG = Color3.fromRGB(18, 20, 26),
    Panel = Color3.fromRGB(28, 31, 40),
    Item = Color3.fromRGB(40, 44, 56),
    ItemHover = Color3.fromRGB(52, 57, 72),
    Off = Color3.fromRGB(70, 75, 90),
    Stroke = Color3.fromRGB(50, 55, 68),
    Text = Color3.fromRGB(235, 238, 245),
    SubText = Color3.fromRGB(150, 156, 170),
}
local TITLE = "GhostX"
local SUBTITLE = "Executor Menu"
local WINDOW_SIZE = Vector2.new(560, 380)

-- ===== LIBRARY CORE =====
local Library = {
    Flags = {},
    ToggleKey = Enum.KeyCode.RightShift,
    Connections = {},
    AccentObjects = {},
    Unloaded = false,
    Toggles = {},
}
genv.GhostXMenu = Library

local function track(conn) table.insert(Library.Connections, conn); return conn end
local function corner(p, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = p; return c end
local function stroke(p, col, th) local s = Instance.new("UIStroke"); s.Color = col or Theme.Stroke; s.Thickness = th or 1; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = p; return s end
local function tween(o, props, t) TweenService:Create(o, TweenInfo.new(t or 0.18, Enum.EasingStyle.Quad), props):Play() end
local function isPress(i) return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch end
local function isMove(i) return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch end

-- Objects registered here get re-colored when the accent changes.
local function accent(obj, prop)
    obj[prop] = Theme.Accent
    table.insert(Library.AccentObjects, { obj, prop })
    return obj
end

local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    if class:find("Text") and props and props.Font == nil then o.Font = Enum.Font.GothamMedium end
    if o:IsA("GuiObject") then o.BorderSizePixel = 0 end
    o.Parent = parent
    return o
end

local function makeDraggable(handle, target)
    local dragging, startInput, startPos
    track(handle.InputBegan:Connect(function(i)
        if isPress(i) then dragging = true; startInput = i.Position; startPos = target.Position end
    end))
    track(UIS.InputChanged:Connect(function(i)
        if dragging and isMove(i) then
            local d = i.Position - startInput
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end))
    track(UIS.InputEnded:Connect(function(i) if isPress(i) then dragging = false end end))
end

-- ===== ROOT GUI =====
local gui = Instance.new("ScreenGui")
gui.Name = randomName()
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 999
protect(gui)
gui.Parent = guiParent()
Library.Gui = gui

-- Floating open button (draggable, handy on mobile)
local openBtn = new("TextButton", {
    Size = UDim2.fromOffset(46, 46),
    Position = UDim2.new(0, 16, 0.5, -23),
    BackgroundColor3 = Theme.BG,
    Text = "GX",
    TextColor3 = Theme.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    AutoButtonColor = false,
}, gui)
corner(openBtn, 23)
accent(stroke(openBtn, nil, 2), "Color")
makeDraggable(openBtn, openBtn)

-- Main window
local main = new("Frame", {
    Size = UDim2.fromOffset(WINDOW_SIZE.X, WINDOW_SIZE.Y),
    Position = UDim2.new(0.5, -WINDOW_SIZE.X / 2, 0.5, -WINDOW_SIZE.Y / 2),
    BackgroundColor3 = Theme.BG,
    ClipsDescendants = true,
}, gui)
corner(main, 12); stroke(main)

local top = new("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = Theme.Panel }, main)
corner(top, 12)
new("Frame", { Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 1, -12), BackgroundColor3 = Theme.Panel }, top)
accent(new("Frame", { Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2), ZIndex = 2 }, top), "BackgroundColor3")

local titleRow = new("Frame", {
    Size = UDim2.new(1, -100, 1, 0), Position = UDim2.fromOffset(16, 0), BackgroundTransparency = 1,
}, top)
new("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8),
    VerticalAlignment = Enum.VerticalAlignment.Center,
}, titleRow)
accent(new("TextLabel", {
    Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X,
    BackgroundTransparency = 1, Text = TITLE, Font = Enum.Font.GothamBold, TextSize = 16,
}, titleRow), "TextColor3")
new("TextLabel", {
    Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X,
    BackgroundTransparency = 1, Text = SUBTITLE, TextColor3 = Theme.SubText, TextSize = 13,
}, titleRow)

local function topButton(text, xOffset)
    local b = new("TextButton", {
        Size = UDim2.fromOffset(30, 30), Position = UDim2.new(1, xOffset, 0, 7),
        BackgroundColor3 = Theme.Item, Text = text, TextColor3 = Theme.Text,
        Font = Enum.Font.GothamBold, TextSize = 14, AutoButtonColor = false,
    }, top)
    corner(b, 6)
    track(b.MouseEnter:Connect(function() tween(b, { BackgroundColor3 = Theme.ItemHover }) end))
    track(b.MouseLeave:Connect(function() tween(b, { BackgroundColor3 = Theme.Item }) end))
    return b
end
local closeBtn = topButton("X", -38)
local minBtn = topButton("-", -74)

local body = new("Frame", { Size = UDim2.new(1, 0, 1, -44), Position = UDim2.fromOffset(0, 44), BackgroundTransparency = 1 }, main)

local sidebar = new("ScrollingFrame", {
    Size = UDim2.new(0, 140, 1, -14), Position = UDim2.fromOffset(8, 6),
    BackgroundColor3 = Theme.Panel, ScrollBarThickness = 0,
    AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
}, body)
corner(sidebar)
new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, sidebar)
new("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, sidebar)

local content = new("Frame", {
    Size = UDim2.new(1, -164, 1, -14), Position = UDim2.fromOffset(156, 6),
    BackgroundColor3 = Theme.Panel,
}, body)
corner(content)

-- Notifications
local notifHolder = new("Frame", {
    Size = UDim2.new(0, 260, 1, -20), Position = UDim2.new(1, -270, 0, 10),
    BackgroundTransparency = 1,
}, gui)
new("UIListLayout", {
    Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Bottom,
    SortOrder = Enum.SortOrder.LayoutOrder,
}, notifHolder)

function Library:Notify(title, text, duration)
    local card = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Panel, BackgroundTransparency = 1,
    }, notifHolder)
    corner(card, 8); local s = stroke(card); s.Transparency = 1
    new("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, card)
    new("UIListLayout", { Padding = UDim.new(0, 2) }, card)
    local t = new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = title,
        Font = Enum.Font.GothamBold, TextSize = 14, TextTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Theme.Accent,
    }, card)
    local d = new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, Text = text or "", TextWrapped = true,
        TextColor3 = Theme.SubText, TextSize = 13, TextTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, card)

    tween(card, { BackgroundTransparency = 0 }); tween(s, { Transparency = 0 })
    tween(t, { TextTransparency = 0 }); tween(d, { TextTransparency = 0 })
    task.delay(duration or 3, function()
        tween(card, { BackgroundTransparency = 1 }); tween(s, { Transparency = 1 })
        tween(t, { TextTransparency = 1 }); tween(d, { TextTransparency = 1 })
        task.wait(0.2)
        card:Destroy()
    end)
end

-- ===== OPEN / CLOSE =====
local minimized = false
local function setOpen(open)
    main.Visible = open
    if open then
        local h = minimized and 44 or WINDOW_SIZE.Y
        main.Size = UDim2.fromOffset(WINDOW_SIZE.X - 30, h - (minimized and 0 or 24))
        tween(main, { Size = UDim2.fromOffset(WINDOW_SIZE.X, h) }, 0.15)
    end
end
function Library:Toggle() setOpen(not main.Visible) end

makeDraggable(top, main)
track(openBtn.MouseButton1Click:Connect(function() Library:Toggle() end))
track(closeBtn.MouseButton1Click:Connect(function() setOpen(false) end))
track(minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    minBtn.Text = minimized and "+" or "-"
    tween(main, { Size = UDim2.fromOffset(WINDOW_SIZE.X, minimized and 44 or WINDOW_SIZE.Y) }, 0.2)
end))

local bindingKey = false
track(UIS.InputBegan:Connect(function(i, typing)
    if typing or bindingKey then return end
    if i.KeyCode == Library.ToggleKey then Library:Toggle() end
end))

-- ===== TABS =====
local pages, tabs = {}, {}
local tabCount = 0

local function selectTab(name)
    for n, p in pairs(pages) do p.Visible = (n == name) end
    for n, b in pairs(tabs) do
        local on = n == name
        tween(b, { BackgroundColor3 = on and Theme.Accent or Theme.Item })
        b.TextColor3 = on and Theme.BG or Theme.Text
    end
    Library.CurrentTab = name
end
Library.SelectTab = function(_, name) selectTab(name) end

local Tab = {}
Tab.__index = Tab

function Library:AddTab(name)
    tabCount += 1
    local b = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Theme.Item,
        Text = name, TextColor3 = Theme.Text, TextSize = 14,
        AutoButtonColor = false, LayoutOrder = tabCount,
    }, sidebar)
    corner(b, 6)
    tabs[name] = b
    track(b.MouseButton1Click:Connect(function() selectTab(name) end))

    local page = new("ScrollingFrame", {
        Size = UDim2.new(1, -16, 1, -16), Position = UDim2.fromOffset(8, 8),
        BackgroundTransparency = 1, ScrollBarThickness = 4,
        AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
        Visible = false,
    }, content)
    accent(page, "ScrollBarImageColor3")
    new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, page)
    new("UIPadding", { PaddingRight = UDim.new(0, 8) }, page)
    pages[name] = page

    if not Library.CurrentTab then selectTab(name) end
    return setmetatable({ Page = page, Order = 0 }, Tab)
end

function Tab:_row(height)
    self.Order += 1
    local row = new("Frame", {
        Size = UDim2.new(1, 0, 0, height), BackgroundColor3 = Theme.Item,
        LayoutOrder = self.Order,
    }, self.Page)
    corner(row, 6)
    return row
end

local function rowLabel(row, text, width)
    return new("TextLabel", {
        Size = UDim2.new(1, width or -70, 0, 36), Position = UDim2.fromOffset(12, 0),
        BackgroundTransparency = 1, Text = text, TextColor3 = Theme.Text, TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)
end

function Tab:AddSection(text)
    self.Order += 1
    new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1,
        Text = string.upper(text), TextColor3 = Theme.SubText,
        Font = Enum.Font.GothamBold, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = self.Order,
    }, self.Page)
end

function Tab:AddLabel(text)
    self.Order += 1
    local l = new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, Text = text, TextWrapped = true,
        TextColor3 = Theme.SubText, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = self.Order,
    }, self.Page)
    return { Set = function(_, t) l.Text = t end }
end

function Tab:AddButton(text, callback)
    self.Order += 1
    local b = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Theme.Item,
        Text = text, TextColor3 = Theme.Text, TextSize = 14,
        AutoButtonColor = false, LayoutOrder = self.Order,
    }, self.Page)
    corner(b, 6)
    track(b.MouseEnter:Connect(function() tween(b, { BackgroundColor3 = Theme.ItemHover }) end))
    track(b.MouseLeave:Connect(function() tween(b, { BackgroundColor3 = Theme.Item }) end))
    track(b.MouseButton1Click:Connect(function()
        tween(b, { BackgroundColor3 = Theme.Accent }, 0.08)
        task.delay(0.12, function() tween(b, { BackgroundColor3 = Theme.Item }) end)
        if callback then task.spawn(callback) end
    end))
end

function Tab:AddToggle(text, flag, default, callback)
    local state = default and true or false
    local row = self:_row(36)
    rowLabel(row, text)
    local track_ = new("TextButton", {
        Size = UDim2.fromOffset(44, 22), Position = UDim2.new(1, -56, 0.5, -11),
        Text = "", AutoButtonColor = false, BackgroundColor3 = Theme.Off,
    }, row)
    corner(track_, 11)
    local knob = new("Frame", { Size = UDim2.fromOffset(18, 18), Position = UDim2.fromOffset(2, 2), BackgroundColor3 = Theme.Text }, track_)
    corner(knob, 9)
    -- Whole row is clickable
    local hit = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "" }, row)

    local obj = {}
    local function render()
        tween(track_, { BackgroundColor3 = state and Theme.Accent or Theme.Off })
        tween(knob, { Position = state and UDim2.fromOffset(24, 2) or UDim2.fromOffset(2, 2) })
    end
    function obj:Set(v)
        state = v and true or false
        if flag then Library.Flags[flag] = state end
        render()
        if callback then task.spawn(callback, state) end
    end
    function obj:Get() return state end
    track(hit.MouseButton1Click:Connect(function() obj:Set(not state) end))
    if flag then Library.Flags[flag] = state end
    render()
    if state and callback then task.spawn(callback, state) end
    obj.Render = render
    table.insert(Library.Toggles, obj)
    return obj
end

function Tab:AddSlider(text, flag, min, max, default, callback, step)
    step = step or 1
    local value = default or min
    local row = self:_row(52)
    local l = new("TextLabel", {
        Size = UDim2.new(1, -24, 0, 24), Position = UDim2.fromOffset(12, 4),
        BackgroundTransparency = 1, TextColor3 = Theme.Text, TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local valLbl = new("TextLabel", {
        Size = UDim2.new(0, 80, 0, 24), Position = UDim2.new(1, -92, 0, 4),
        BackgroundTransparency = 1, TextColor3 = Theme.SubText, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, row)
    local bar = new("TextButton", {
        Size = UDim2.new(1, -24, 0, 6), Position = UDim2.fromOffset(12, 34),
        BackgroundColor3 = Theme.Off, Text = "", AutoButtonColor = false,
    }, row)
    corner(bar, 3)
    local fill = accent(new("Frame", {}, bar), "BackgroundColor3")
    corner(fill, 3)

    local obj = {}
    local function fmt(v)
        if step < 1 then return string.format("%.2f", v) end
        return tostring(math.floor(v + 0.5))
    end
    local function render()
        fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
        l.Text = text
        valLbl.Text = fmt(value)
    end
    function obj:Set(v)
        value = math.clamp(math.floor(v / step + 0.5) * step, min, max)
        if flag then Library.Flags[flag] = value end
        render()
        if callback then task.spawn(callback, value) end
    end
    function obj:Get() return value end

    local dragging = false
    local function update(x)
        local pct = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        obj:Set(min + (max - min) * pct)
    end
    track(bar.InputBegan:Connect(function(i) if isPress(i) then dragging = true; update(i.Position.X) end end))
    track(UIS.InputChanged:Connect(function(i) if dragging and isMove(i) then update(i.Position.X) end end))
    track(UIS.InputEnded:Connect(function(i) if isPress(i) then dragging = false end end))
    if flag then Library.Flags[flag] = value end
    render()
    return obj
end

function Tab:AddDropdown(text, flag, options, default, callback)
    local selected = default or options[1]
    local open = false
    local row = self:_row(36)
    row.ClipsDescendants = true
    rowLabel(row, text, -150)
    local head = new("TextButton", {
        Size = UDim2.new(0, 130, 0, 26), Position = UDim2.new(1, -140, 0, 5),
        BackgroundColor3 = Theme.Panel, TextColor3 = Theme.Text, TextSize = 13,
        AutoButtonColor = false, TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)
    corner(head, 5)
    local list = new("Frame", {
        Size = UDim2.new(1, -24, 0, 0), Position = UDim2.fromOffset(12, 40),
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
    }, row)
    new("UIListLayout", { Padding = UDim.new(0, 4) }, list)

    local obj = {}
    local function resize()
        local h = open and (44 + #options * 30) or 36
        tween(row, { Size = UDim2.new(1, 0, 0, h) }, 0.15)
        head.Text = tostring(selected) .. (open and "  ▲" or "  ▼")
    end
    function obj:Set(v)
        selected = v
        if flag then Library.Flags[flag] = v end
        resize()
        if callback then task.spawn(callback, v) end
    end
    function obj:Get() return selected end
    function obj:Refresh(newOptions)
        options = newOptions
        for _, c in ipairs(list:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
        for _, opt in ipairs(options) do
            local ob = new("TextButton", {
                Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = Theme.Panel,
                Text = tostring(opt), TextColor3 = Theme.Text, TextSize = 13, AutoButtonColor = false,
            }, list)
            corner(ob, 5)
            track(ob.MouseEnter:Connect(function() tween(ob, { BackgroundColor3 = Theme.ItemHover }) end))
            track(ob.MouseLeave:Connect(function() tween(ob, { BackgroundColor3 = Theme.Panel }) end))
            track(ob.MouseButton1Click:Connect(function() open = false; obj:Set(opt) end))
        end
        resize()
    end
    track(head.MouseButton1Click:Connect(function() open = not open; resize() end))
    if flag then Library.Flags[flag] = selected end
    obj:Refresh(options)
    return obj
end

function Tab:AddInput(text, flag, placeholder, callback)
    local row = self:_row(36)
    rowLabel(row, text, -170)
    local box = new("TextBox", {
        Size = UDim2.new(0, 150, 0, 26), Position = UDim2.new(1, -160, 0, 5),
        BackgroundColor3 = Theme.Panel, Text = "", PlaceholderText = placeholder or "...",
        TextColor3 = Theme.Text, PlaceholderColor3 = Theme.SubText, TextSize = 13,
        ClearTextOnFocus = false,
    }, row)
    corner(box, 5)
    track(box.FocusLost:Connect(function(enter)
        if flag then Library.Flags[flag] = box.Text end
        if callback then task.spawn(callback, box.Text, enter) end
    end))
    return { Set = function(_, v) box.Text = v end, Get = function() return box.Text end }
end

function Tab:AddKeybind(text, flag, default, callback)
    local key = default
    local row = self:_row(36)
    rowLabel(row, text, -120)
    local b = new("TextButton", {
        Size = UDim2.new(0, 100, 0, 26), Position = UDim2.new(1, -110, 0, 5),
        BackgroundColor3 = Theme.Panel, TextColor3 = Theme.Text, TextSize = 13,
        Text = key and key.Name or "None", AutoButtonColor = false,
    }, row)
    corner(b, 5)
    track(b.MouseButton1Click:Connect(function()
        bindingKey = true
        b.Text = "..."
        local conn
        conn = UIS.InputBegan:Connect(function(i)
            if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
            conn:Disconnect()
            key = if i.KeyCode == Enum.KeyCode.Escape then nil else i.KeyCode
            b.Text = key and key.Name or "None"
            if flag then Library.Flags[flag] = key end
            if callback then task.spawn(callback, key) end
            task.defer(function() bindingKey = false end)
        end)
    end))
    if flag then Library.Flags[flag] = key end
    return { Get = function() return key end }
end

function Library:SetAccent(color)
    Theme.Accent = color
    for _, pair in ipairs(Library.AccentObjects) do
        if pair[1].Parent then pair[1][pair[2]] = color end
    end
    for _, t in ipairs(Library.Toggles) do t.Render() end
    if Library.CurrentTab then selectTab(Library.CurrentTab) end
end

-- ===== FEATURE STATE =====
local Cleanup = {}   -- functions run on unload to restore the game state
local function getChar() return player.Character end
local function getHum() local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function getRoot() local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart") end

function Library.Unload()
    if Library.Unloaded then return end
    Library.Unloaded = true
    for _, fn in ipairs(Cleanup) do pcall(fn) end
    for _, c in ipairs(Library.Connections) do pcall(function() c:Disconnect() end) end
    if gui then gui:Destroy() end
    if genv.GhostXMenu == Library then genv.GhostXMenu = nil end
end

-- ===== TABS (edit these) =====

-- Player ---------------------------------------------------------------
local playerTab = Library:AddTab("Player")
playerTab:AddSection("Movement")

local defaultSpeed, defaultJump = 16, 50
local speedSlider = playerTab:AddSlider("WalkSpeed", "WalkSpeed", 16, 250, 16)
playerTab:AddToggle("Enable WalkSpeed", "SpeedOn", false)
playerTab:AddSlider("JumpPower", "JumpPower", 50, 300, 50)
playerTab:AddToggle("Enable JumpPower", "JumpOn", false)

track(RunService.Heartbeat:Connect(function()
    local hum = getHum()
    if not hum then return end
    if Library.Flags.SpeedOn then hum.WalkSpeed = Library.Flags.WalkSpeed end
    if Library.Flags.JumpOn then
        hum.UseJumpPower = true
        hum.JumpPower = Library.Flags.JumpPower
    end
end))
table.insert(Cleanup, function()
    local hum = getHum()
    if hum then hum.WalkSpeed = defaultSpeed; hum.JumpPower = defaultJump end
end)

playerTab:AddToggle("Infinite Jump", "InfJump", false)
track(UIS.JumpRequest:Connect(function()
    if not Library.Flags.InfJump then return end
    local hum = getHum()
    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end))

playerTab:AddToggle("Noclip", "Noclip", false)
track(RunService.Stepped:Connect(function()
    if not Library.Flags.Noclip then return end
    local c = getChar()
    if not c then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
    end
end))

playerTab:AddSection("Fly")
playerTab:AddSlider("Fly Speed", "FlySpeed", 10, 300, 60)
playerTab:AddToggle("Fly  (Space = up, Ctrl = down)", "Fly", false, function(on)
    local hum = getHum()
    if hum and not on then hum.PlatformStand = false end
end)
track(RunService.RenderStepped:Connect(function()
    if not Library.Flags.Fly then return end
    local root, hum, cam = getRoot(), getHum(), workspace.CurrentCamera
    if not (root and hum and cam) then return end
    local dir = hum.MoveDirection
    if dir.Magnitude > 0 then
        -- Tilt horizontal input toward where the camera is looking
        local look = cam.CFrame.LookVector
        local flat = Vector3.new(look.X, 0, look.Z)
        if flat.Magnitude > 0 then
            local fwd = dir:Dot(flat.Unit)
            dir = dir + Vector3.new(0, look.Y * fwd, 0)
        end
    end
    if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0) end
    if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0, 1, 0) end
    if dir.Magnitude > 0 then dir = dir.Unit end
    root.AssemblyLinearVelocity = dir * Library.Flags.FlySpeed
end))
table.insert(Cleanup, function() local hum = getHum(); if hum then hum.PlatformStand = false end end)

playerTab:AddSection("Character")
playerTab:AddButton("Reset Character", function()
    local hum = getHum()
    if hum then hum.Health = 0 end
end)
playerTab:AddButton("Reset Movement Values", function()
    speedSlider:Set(defaultSpeed)
    local hum = getHum()
    if hum then hum.WalkSpeed = defaultSpeed; hum.JumpPower = defaultJump end
    Library:Notify("Player", "Movement values reset.")
end)

-- Visuals --------------------------------------------------------------
local visualTab = Library:AddTab("Visuals")
visualTab:AddSection("Lighting")

local savedLighting = {
    Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd, GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
}
local function restoreLighting()
    for k, v in pairs(savedLighting) do Lighting[k] = v end
end
table.insert(Cleanup, restoreLighting)

visualTab:AddToggle("Fullbright", "Fullbright", false, function(on)
    if not on then restoreLighting() end
end)
visualTab:AddToggle("No Fog", "NoFog", false, function(on)
    if not on then Lighting.FogEnd = savedLighting.FogEnd end
end)
track(RunService.RenderStepped:Connect(function()
    if Library.Flags.Fullbright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
    end
    if Library.Flags.NoFog then Lighting.FogEnd = 1e6 end
end))

visualTab:AddSection("Camera")
local cam = workspace.CurrentCamera
local defaultFov = cam and cam.FieldOfView or 70
visualTab:AddSlider("Field of View", "FOV", 30, 120, defaultFov, function(v)
    if workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView = v end
end)
table.insert(Cleanup, function() if workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView = defaultFov end end)

-- Misc -----------------------------------------------------------------
local miscTab = Library:AddTab("Misc")
miscTab:AddSection("Utility")

local VirtualUser = game:GetService("VirtualUser")
miscTab:AddToggle("Anti-AFK", "AntiAFK", true)
track(player.Idled:Connect(function()
    if not Library.Flags.AntiAFK then return end
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end))

miscTab:AddButton("Copy Position", function()
    local root = getRoot()
    if not root then return end
    local p = root.Position
    local str = string.format("Vector3.new(%.2f, %.2f, %.2f)", p.X, p.Y, p.Z)
    if setclipboard then
        setclipboard(str)
        Library:Notify("Copied", str)
    else
        Library:Notify("Position", str, 6)
    end
end)

miscTab:AddSection("Teleport to Player")
local function playerNames()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then table.insert(names, p.Name) end
    end
    if #names == 0 then names = { "(none)" } end
    return names
end
local tpDrop = miscTab:AddDropdown("Target", "TPTarget", playerNames(), nil)
miscTab:AddButton("Refresh Player List", function() tpDrop:Refresh(playerNames()) end)
miscTab:AddButton("Teleport", function()
    local target = Players:FindFirstChild(tostring(Library.Flags.TPTarget))
    local tRoot = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    local root = getRoot()
    if tRoot and root then
        root.CFrame = tRoot.CFrame * CFrame.new(0, 0, 3)
    else
        Library:Notify("Teleport", "Target not found.")
    end
end)

miscTab:AddSection("Server")
miscTab:AddButton("Rejoin Server", function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
end)

-- Settings -------------------------------------------------------------
local settingsTab = Library:AddTab("Settings")
settingsTab:AddSection("Interface")
settingsTab:AddKeybind("Menu Toggle Key", "MenuKey", Library.ToggleKey, function(k)
    Library.ToggleKey = k or Enum.KeyCode.RightShift
end)
local accents = {
    Mint = Color3.fromRGB(0, 200, 140),
    Blue = Color3.fromRGB(70, 140, 255),
    Purple = Color3.fromRGB(160, 100, 255),
    Red = Color3.fromRGB(255, 80, 95),
    Orange = Color3.fromRGB(255, 150, 60),
}
settingsTab:AddDropdown("Accent Color", "Accent", { "Mint", "Blue", "Purple", "Red", "Orange" }, "Mint", function(name)
    Library:SetAccent(accents[name])
end)
settingsTab:AddToggle("Show Floating Button", "ShowOpenBtn", true, function(on) openBtn.Visible = on end)

settingsTab:AddSection("Info")
settingsTab:AddLabel("Executor: " .. ((identifyexecutor and select(1, identifyexecutor())) or "Unknown"))
settingsTab:AddLabel("Place ID: " .. game.PlaceId)

settingsTab:AddSection("Danger Zone")
settingsTab:AddButton("Unload Menu", function() Library.Unload() end)

selectTab("Player")
setOpen(true)
Library:Notify(TITLE .. " loaded", "Press " .. Library.ToggleKey.Name .. " to toggle the menu.", 4)

return Library
