local ReplicatedStorage : ReplicatedStorage = game:GetService("ReplicatedStorage");

local function updateStat(player : Player, stat : string, value : any) : nil
    player:FindFirstChild(stat, true).Value = value;
end

ReplicatedStorage:WaitForChild("RemoteEvents").StatChange.OnServerEvent:Connect(updateStat);
