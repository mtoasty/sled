local ReplicatedStorage : ReplicatedStorage = game:GetService("ReplicatedStorage");
local ServerStorage : ServerStorage = game:GetService("ServerStorage");

local clientSledSpawnEvent : RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvents").SpawnSled;
local serverSledSpawnEvent : BindableEvent = ServerStorage:WaitForChild("ServerEvents").SpawnSled;

local function spawnSled(player : Player, nameOfSled : string) : nil
	local character = player.Character or player.CharacterAdded:Wait();
	local curSled = workspace:FindFirstChild(player.Name.."'s sled");

	if curSled then
		curSled:Destroy();
	end

	local newSled = ServerStorage.Sleds:FindFirstChild(nameOfSled):Clone();

	newSled.Parent = workspace;
	newSled.Name = player.Name .. "'s sled";
	newSled:PivotTo(character.HumanoidRootPart.CFrame);
	newSled.Components.VehicleSeat:Sit(character:FindFirstChildOfClass("Humanoid"));
end

clientSledSpawnEvent.OnServerEvent:Connect(spawnSled);
serverSledSpawnEvent.Event:Connect(spawnSled);