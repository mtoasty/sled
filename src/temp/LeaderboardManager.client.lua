game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false);

game.ReplicatedStorage.LocalEvents.LoadingScreen.Event:Wait();

local Players = game.Players;
local UserService = game:GetService("UserService");
local camera = workspace.CurrentCamera;

local leaderboard = script.Parent.Container;
local listLayout = leaderboard.UIListLayout;
local sample = leaderboard.Parent.Sample;

local TweenService = game:GetService("TweenService");

local function leaderboardSizeChanged()
	local maxHeight = math.clamp(listLayout.AbsoluteContentSize.Y, 0, camera.ViewportSize.Y / 2);
	leaderboard.Size = UDim2.new(0.2, 0, 0, maxHeight);
	leaderboard.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize);
end

leaderboard.ChildRemoved:Connect(leaderboardSizeChanged);

camera:GetPropertyChangedSignal("ViewportSize"):Connect(leaderboardSizeChanged);

local function createSample(player: Player)
	local clonedSample = sample:Clone();
	clonedSample.Name = player.Name;
	clonedSample.Parent = leaderboard;
	clonedSample.Visible = true;

	leaderboardSizeChanged();

	local level = player.sledstats.Level or "-";
	if level ~= "-" then
		level:GetPropertyChangedSignal("Value"):Connect(function()
			clonedSample.Level.Text = level.Value;
		end);
	end
	clonedSample.Level.Text = level.Value;

	local dnHideTween = TweenService:Create(clonedSample.DisplayName, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {["TextTransparency"] = 1});
	local dnShowTween = TweenService:Create(clonedSample.DisplayName, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {["TextTransparency"] = 0});

	local unHideTween = TweenService:Create(clonedSample.Username, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {["TextTransparency"] = 1});
	local unShowTween = TweenService:Create(clonedSample.Username, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {["TextTransparency"] = 0});
	
	xpcall(function()
		local playerUsernameData = UserService:GetUserInfosByUserIdsAsync({player.UserId})[1];
		local displayName = playerUsernameData.DisplayName;
		clonedSample.Username.Text = "@"..player.Name;
		clonedSample.DisplayName.Text = displayName;

		clonedSample.Username.MouseEnter:Connect(function()
			dnHideTween:Play();
			unShowTween:Play();
		end);

		clonedSample.Username.MouseLeave:Connect(function()
			dnShowTween:Play();
			unHideTween:Play();
		end);
	end, function()
		clonedSample.Username.Text = player.Name;
		clonedSample.DisplayName.Text = player.Name;
	end);

	camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		clonedSample.Size = UDim2.new(1, 0, 0, camera.ViewportSize.Y / 20);
	end);
end

local function playerRemoving(player: Player)
	pcall(function()
		leaderboard[player.Name]:Destroy();
	end);
end

Players.PlayerAdded:Connect(createSample);
Players.PlayerRemoving:Connect(playerRemoving);

local allPlayers = Players:GetPlayers();

for _, vplayer: Player in pairs(allPlayers) do
	createSample(vplayer);
end