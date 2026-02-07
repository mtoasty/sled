local leaderboardpart = script.Parent.Parent.Parent;
local raceid = leaderboardpart.Parent.Name;

local timeTrialInfos = require(game.ReplicatedStorage.Modules.TimeTrialInfos);
local speedDemonTime = timeTrialInfos[raceid].Times.Gold - 50;

local DataStoreService = game:GetService("DataStoreService");
local dataStore = DataStoreService:GetOrderedDataStore("sled"..raceid.."TimeTrialLB");
local UserService = game:GetService("UserService");
--game:GetService("DataStoreService"):GetOrderedDataStore("sled_TimeTrialLB"):SetAsync(userid, time)
function refresh(player, lb)
	if lb == raceid then
		if player then
			repeat task.wait() until DataStoreService:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.SetIncrementAsync) > 0;
			pcall(function()
				dataStore:SetAsync(player.UserId, player.racestats[raceid].Value);
			end);
		end
		
		repeat task.wait() until DataStoreService:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.GetSortedAsync) > 0;
		
		for i, frame in pairs(leaderboardpart.SurfaceGui.PlayerHolder:GetChildren()) do
			if frame.Name ~= "Sample" and frame:IsA("Frame") then
				frame:Destroy();
			end
		end
		
		local page = dataStore:GetSortedAsync(true, 10);
		local data = page:GetCurrentPage();
		
		local userids = {};
		
		for i, v in ipairs(data) do
			table.insert(userids, tonumber(v.key));
		end

		local users = UserService:GetUserInfosByUserIdsAsync(userids);

		for rank, stat in pairs(data) do
			
			local username = users[rank].Username;
			local displayName = users[rank].DisplayName;
			
			local nameToDisplay;
			
			if username == displayName then
				nameToDisplay = username;
			else
				nameToDisplay = displayName.." @"..username;
			end
			
			local score = stat.value;

			if score and score ~= 99999 then

				local tenths;
				local seconds;
				local minutes;
				local decodedTime; 

				tenths = score % 10 ;
				seconds = (score - tenths) / 10;
				minutes = math.floor(seconds / 60);
				seconds = seconds - minutes * 60;

				if seconds <= 9 then
					decodedTime = minutes..":0"..seconds.."."..tenths;
				else
					decodedTime = minutes..":"..seconds.."."..tenths;
				end
				
				local newsample = script.Parent.Parent.SampleHolder.Sample:Clone();

				newsample.Parent = leaderboardpart.SurfaceGui.PlayerHolder;
				newsample.Name = username;

				newsample.RankLabel.Text = "#"..rank;
				newsample.NameLabel.Text = nameToDisplay;
				newsample.TimeLabel.Text = decodedTime;
				if score < speedDemonTime then
					newsample.TimeLabel.TextColor3 = Color3.fromRGB(255, 50, 0);
					newsample.RankLabel.TextColor3 = Color3.fromRGB(255, 50, 0);
					newsample.NameLabel.TextColor3 = Color3.fromRGB(255, 50, 0);
				end	
			end
		end
	end
end

task.wait(10);
refresh(nil, raceid);

game.ReplicatedStorage.raceTriggers.updateLB.OnServerEvent:Connect(refresh);
