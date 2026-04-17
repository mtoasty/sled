local ReplicatedStorage : ReplicatedStorage = game:GetService("ReplicatedStorage");
local ServerStorage : ServerStorage = game:GetService("ServerStorage");

local clientSledSpawnEvent : RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvents").SpawnSled;
local serverSledSpawnEvent : BindableEvent = ServerStorage:WaitForChild("ServerEvents").SpawnSled;

local function assignNetworkOwner(sled : Model, targetPlayer : Player) : nil
	for _, inst : Instance in pairs(sled:GetDescendants()) do
		if (inst:IsA("BasePart")) then
			inst:SetNetworkOwner(targetPlayer);
		end
	end
end

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
	assignNetworkOwner(newSled, player);

	--| Sled colouring
	for _, inst : Instance in pairs(newSled.SledModel:GetChildren()) do
		if (inst:GetAttribute("Colourable") == true) then
			inst.Color = player.Data.sledConfig.sledColour.Value;
		end
	end
end

clientSledSpawnEvent.OnServerEvent:Connect(spawnSled);
serverSledSpawnEvent.Event:Connect(spawnSled);