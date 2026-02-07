game.Players.PlayerAdded:Connect(function(player: Player)
	if player:GetRankInGroup(13628961) < 249 then
		player:Kick("No authorized access, quo says hi :3");
	end
end);