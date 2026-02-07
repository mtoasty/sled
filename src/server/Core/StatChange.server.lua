local ReplicatedStorage : ReplicatedStorage = game:GetService("ReplicatedStorage");

ReplicatedStorage.RemoteEvents.StatChange.OnServerEvent:Connect(function(player : Player, stat : string, value : any) : nil
    player:FindFirstChild(stat, true).Value = value;
end);