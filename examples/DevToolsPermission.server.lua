-- Server Script (ServerScriptService). Decides who may use the developer
-- tools in the settings menu. Only exists in your own place, so the tools
-- stay off anywhere else.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Add tester/moderator UserIds here.
local ADMIN_USER_IDS = {
    -- [12345678] = true,
}

-- For group-owned games: minimum group rank allowed to use the tools.
local MIN_GROUP_RANK = 254

local function isAdmin(player)
    if ADMIN_USER_IDS[player.UserId] then
        return true
    end
    if game.CreatorType == Enum.CreatorType.User then
        return player.UserId == game.CreatorId
    end
    local ok, rank = pcall(player.GetRankInGroup, player, game.CreatorId)
    return ok and rank >= MIN_GROUP_RANK
end

local remote = Instance.new("RemoteFunction")
remote.Name = "DevToolsPermission"
remote.OnServerInvoke = isAdmin
remote.Parent = ReplicatedStorage
