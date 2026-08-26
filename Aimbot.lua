local Aimbot = {}

function Aimbot.start()
	Aimbot.active = false
	return false, "Player targeting is not available in the developer dashboard"
end

function Aimbot.stop()
	Aimbot.active = false
	return true
end

function Aimbot.getStatus()
	return {
		active = Aimbot.active,
		mode = "Disabled",
		message = "Use server-authorized training tools for NPC testing",
	}
end

return Aimbot

function Aimbot.start()
	return false, "Player targeting is not implemented"
end

function Aimbot.stop()
	return true
end

return Aimbot
