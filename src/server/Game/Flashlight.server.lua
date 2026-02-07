local ReplicatedStorage : ReplicatedStorage = game:GetService("ReplicatedStorage");
local Players : Players = game:GetService("Players");

Players.PlayerAdded:Connect(function(player : Player) : nil
	player.CharacterAdded:Connect(function(character : Model) : nil
		local newFlashlight : Light = ReplicatedStorage.Flashlights.Flashlight:Clone();
		newFlashlight.Parent = character:FindFirstChild("Head");
	end)
end);

ReplicatedStorage.RemoteEvents.FlashlightToggle.OnServerEvent:Connect(function(player : Player) : nil
	player.Character.Head.Flashlight.Enabled = not player.Character.Head.Flashlight.Enabled;
end);