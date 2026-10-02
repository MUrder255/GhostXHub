-- Example LocalScript (StarterPlayerScripts). Place SettingsMenu as a
-- ModuleScript in ReplicatedStorage.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local SettingsMenu = require(ReplicatedStorage:WaitForChild("SettingsMenu"))

local menu = SettingsMenu.new({
    title = "Game Settings",
    toggleKey = Enum.KeyCode.RightShift,
})

menu:AddSection("Audio")
menu:AddToggle({
    name = "Mute All Sounds",
    default = false,
    callback = function(enabled)
        SoundService.Volume = enabled and 0 or 1
    end,
})

menu:AddSection("Graphics")
local shadows = menu:AddToggle({
    name = "Shadows",
    default = Lighting.GlobalShadows,
    callback = function(enabled)
        Lighting.GlobalShadows = enabled
    end,
})

menu:AddToggle({
    name = "Bloom",
    default = true,
    fireOnCreate = true,
    callback = function(enabled)
        local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
        if bloom then
            bloom.Enabled = enabled
        end
    end,
})

menu:AddSection("General")
menu:AddButton({
    name = "Reset to Defaults",
    callback = function()
        menu:GetToggle("Mute All Sounds"):Set(false)
        shadows:Set(true)
        menu:GetToggle("Bloom"):Set(true)
    end,
})
