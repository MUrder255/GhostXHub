local Esp = {}

function Esp.enable()
	Esp.enabled = false
	return false, "Player wall-visibility is not available in the developer dashboard"
end

function Esp.disable()
	Esp.enabled = false
	return true
end

function Esp.setMode(mode)
	assert(mode == "Diagnostics" or mode == "Team", "Unsupported ESP mode")
	Esp.mode = mode
	return Esp.mode
end

function Esp.getStatus()
	return {
		enabled = Esp.enabled,
		mode = Esp.mode,
		message = "Server-provided diagnostics only",
	}
end

return Esp

