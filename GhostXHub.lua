local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

if not RunService:IsClient() then
    error("GhostXHub must run from a LocalScript or client ModuleScript", 0)
end

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
for _, name in ipairs({ "GhostXHub", "GhostXDeveloperDashboard" }) do
    local existing = playerGui:FindFirstChild(name)
    if existing then
        existing:Destroy()
    end
end

local dashboard = require(script.Parent.Dashboard)
local settings = require(script.Parent.Settings)
local aimbot = require(script.Parent.Aimbot)
local esp = require(script.Parent.Esp)

dashboard.settings = settings
dashboard.modules = {
    Aimbot = aimbot,
    Esp = esp,
}

return dashboard.mount()