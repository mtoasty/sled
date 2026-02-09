local PhysicsService = game:GetService("PhysicsService");
local Players = game:GetService("Players");

PhysicsService:RegisterCollisionGroup("Characters");
PhysicsService:RegisterCollisionGroup("Sleds");
PhysicsService:CollisionGroupSetCollidable("Characters", "Characters", false);
PhysicsService:CollisionGroupSetCollidable("Characters", "Sleds", false);
PhysicsService:CollisionGroupSetCollidable("Sleds", "Sleds", false);

local function onDescendantAdded(descendant: Instance)
	if descendant:IsA("BasePart") then
		descendant.CollisionGroup = "Characters";
	end
end

local function onCharacterAdded(character: Model)
	for _, descendant in pairs(character:GetDescendants()) do
		onDescendantAdded(descendant);
	end
	character.DescendantAdded:Connect(onDescendantAdded)
end

Players.PlayerAdded:Connect(function(player: Player)
	player.CharacterAdded:Connect(onCharacterAdded);
end);