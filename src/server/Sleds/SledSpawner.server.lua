local ReplicatedStorage : ReplicatedStorage = game:GetService("ReplicatedStorage");
local ServerStorage : ServerStorage = game:GetService("ServerStorage");

local clientSledSpawnEvent : RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvents").SpawnSled;
local serverSledSpawnEvent : BindableEvent = ServerStorage:WaitForChild("ServerEvents").SpawnSled;

local function spawnSled(player : Player, nameOfSled : string) : nil
	local character = player.Character or player.CharacterAdded:Wait();
	local curSled = workspace:FindFirstChild(player.Name.."'s sled");

	if curSled then
		local seatWeld : WeldConstraint = curSled.Components:FindFirstChildOfClass("VehicleSeat"):FindFirstChild("SeatWeld");
		if seatWeld then
			seatWeld:Destroy();
		end
		curSled:Destroy();
		task.wait(0.1);
	end

	local newSled = ServerStorage.Sleds:FindFirstChild(nameOfSled):Clone();

	newSled.Parent = workspace;
	newSled.Name = player.Name .. "'s sled";
	newSled:PivotTo(character.HumanoidRootPart.CFrame);
	newSled.Components.VehicleSeat:Sit(character:FindFirstChildOfClass("Humanoid"));
end

clientSledSpawnEvent.OnServerEvent:Connect(spawnSled);
serverSledSpawnEvent.Event:Connect(spawnSled);