game.ReplicatedStorage.RemoteEvents.TimeSpeedGet.OnServerInvoke = function(player: Player, option: string)
	return script.Parent[option].Value;
end;