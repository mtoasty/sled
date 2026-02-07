game.Players.PlayerAdded:Connect(function(player: Player)
	local gyroAttachmentHolder = Instance.new("Part");
	gyroAttachmentHolder.Name = player.Name.."-GyroAttachmentHolder";
	gyroAttachmentHolder.Anchored = true;
	gyroAttachmentHolder.CanCollide = false;
	gyroAttachmentHolder.Transparency = 1;
	gyroAttachmentHolder.Position = Vector3.new(0, 0, 0);
	gyroAttachmentHolder.Parent = game.Workspace;

	local att = Instance.new("Attachment");
	att.Name = "GyroAttachment";
	att.Parent = gyroAttachmentHolder;
	att.Axis = Vector3.new(0, 1, 0);
	att.SecondaryAxis = Vector3.new(0, 0, -1);
end);

game.Players.PlayerRemoving:Connect(function(player)
	game.Workspace:FindFirstChild(player.Name.."-GyroAttachmentHolder"):Destroy();
end);

