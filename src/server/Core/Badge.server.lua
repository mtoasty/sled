game.ReplicatedStorage.RemoteEvents.Badge.OnServerEvent:Connect(function(player: Player, badge: number)
	game:GetService("BadgeService"):AwardBadge(player.UserId, badge);
end);