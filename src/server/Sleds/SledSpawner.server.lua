game.ReplicatedStorage.RemoteEvents:WaitForChild("SpawnSled").OnServerEvent:Connect(function(player: Player, nameOfSled: string)
	local plr = game.Workspace:FindFirstChild(player.Name);
	local cursled;

	local success, err = pcall(function()
		cursled = game.Workspace:FindFirstChild(player.Name.."'s sled");
	end);

	if success and cursled then
		cursled:Destroy();
	end

	local sled = game.ServerStorage.Sleds:FindFirstChild(nameOfSled):Clone();
	sled:PivotTo((CFrame.new(plr.HumanoidRootPart.CFrame.Position+(plr.HumanoidRootPart.CFrame.LookVector),plr.HumanoidRootPart.Position)) * CFrame.Angles(0, math.rad(180), 0));
	sled.Parent = workspace;
	sled:MakeJoints();
	sled.Name = player.Name.."'s sled";
	local seat = sled:WaitForChild("VehicleSeat", 5) or sled:WaitForChild("Components", 2.5):WaitForChild("Seat", 2.5);
	if seat then
		seat.Anchored = true;
		task.wait(0.5);
		seat.Anchored = false;

		task.wait(5);
		if seat.Occupant == nil then
			sled:Destroy();
		end
	end
end);
