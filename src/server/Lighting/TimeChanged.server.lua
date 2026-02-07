game.ReplicatedStorage.RemoteEvents.ChangeTime.OnServerEvent:Connect(function(player: Player, newTime: number)
	script.Parent.TimeSpeed.Value = newTime;
end);