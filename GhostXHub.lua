local RunService = game:GetService("RunService")

if not RunService:IsClient() then
    error("GhostXHub must run from a LocalScript or client ModuleScript", 0)
end

local dashboard = require(script.Parent.Dashboard)

return dashboard.mount()