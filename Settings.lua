local Settings = {
    title = "GhostX Developer Dashboard",
    subtitle = "Authorized client diagnostics",
    accentColor = Color3.fromRGB(87, 176, 255),
    showDiagnostics = true,
    starfieldEnabled = true,
    reducedMotion = false,
    toggleKey = Enum.KeyCode.RightShift,
}

function Settings.set(name, value)
    assert(Settings[name] ~= nil, string.format("Unknown setting: %s", name))
    Settings[name] = value
    return value
end

function Settings.toggle(name)
    assert(type(Settings[name]) == "boolean", string.format("Setting is not boolean: %s", name))
    Settings[name] = not Settings[name]
    return Settings[name]
end

return Settings
