local adminFunctions = {
    ["Teleport"] = function(p1: Player, p2: Player)
        p1.HumanoidRootPart.Position = p2.HumanoidRootPart.Position;
    end,

    ["Kick"] = function(player: Player, reason: string)
        reason = reason or "No given reason"
		game.Players[player]:Kick(reason);
    end
};

game.ReplicatedStorage.RemoteEvents.AdminTool.OnServerEvent:Connect(function(tool: string, arg1, arg2)
    adminFunctions[tool](arg1, arg2);
end)
