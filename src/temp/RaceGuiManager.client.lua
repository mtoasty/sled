local ReplicatedStorage = game:GetService("ReplicatedStorage");
local TweenService = game:GetService("TweenService");

local Players = game.Players;
local player = Players.LocalPlayer;
local character = player.Character;
local controls = require(game:GetService("Players").LocalPlayer.PlayerScripts.PlayerModule):GetControls()

local raceGui = script.Parent;
local resultGui = script.Parent.Parent.Result;
local timer = raceGui.Parent.Timer;

local defaultSongIntro = script.slleddrace_intro;
local defaultSongLoop = script.slleddrace_loop;

local racing = false;
local currentId = "";

--| Opening gui:

function ConvertValueToTime(t: number)
	if t == "-:--" then
		return t;
	end

	if t < 0 then
		local abst = ConvertValueToTime(-t);
		return "-"..abst;
	end

	local tenths;
	local seconds;
	local minutes;
	local decodedTime;

	tenths = t % 10 ;
	seconds = (t - tenths) / 10;
	minutes = math.floor(seconds / 60);
	seconds = seconds - minutes * 60;

	if seconds <= 9 then
		decodedTime = minutes..":0"..seconds.."."..tenths;
	else
		decodedTime = minutes..":"..seconds.."."..tenths;
	end

	return decodedTime;
end

function ConvertTimeToValue(t: string)
	if t == "-:--" then
		return 0;
	end

	local decodedTime = 0;

	local tenths = string.sub(t, string.len(t));
	decodedTime += tonumber(tenths);

	local seconds = string.sub(t, string.find(t, ":") + 1, string.find(t, ":") + 2);
	decodedTime += (seconds * 10);

	local minutes = string.sub(t, 1, string.find(t, ":") - 1);
	decodedTime += (minutes * 600);

	return decodedTime;
end

local function GuiOpened(raceinfo)
	if racing then
		return;
	end

	raceGui.RaceName.Text = raceinfo.RaceName;

	raceGui.Difficulty.DifficultyNumber.Text = raceinfo.Difficulty.NumberRating;
	raceGui.Difficulty.DifficultyClass.Text = raceinfo.Difficulty.NameRating;
	raceGui.Difficulty.DifficultyNumber.TextColor3 = raceinfo.Difficulty.Colour;

	raceGui.RaceRoute.RaceRouteDesc.Text = raceinfo.RaceRoute;

	raceGui.YourBest.YourBestTime.Text = ConvertValueToTime(raceinfo.YourBest);
	raceGui.YourBest.YourBestTimeRank.Text = raceinfo.YourBestRank;

	raceGui.WorldRecord.WorldRecordTime.Text = raceinfo.WorldRecordTime;
	raceGui.WorldRecord.HolderIcon.Image = raceinfo.WorldRecordThumbnail;
	raceGui.WorldRecord.WorldRecordHolderName.Text = raceinfo.WorldRecordPlayer;

	raceGui.Times.Values.Gold.Value = raceinfo.Gold;
	raceGui.Times.GoldTime.Text = ConvertValueToTime(raceinfo.Gold);

	raceGui.Times.Values.Silver.Value = raceinfo.Silver;
	raceGui.Times.SilverTime.Text = ConvertValueToTime(raceinfo.Silver);

	raceGui.Times.Values.Bronze.Value = raceinfo.Bronze;
	raceGui.Times.BronzeTime.Text = ConvertValueToTime(raceinfo.Bronze);

	raceGui.Times.Values.Limit.Value = raceinfo.Limit;
	raceGui.Times.LimitTime.Text = ConvertValueToTime(raceinfo.Limit);

	currentId = raceinfo.RaceId;

	raceGui.Visible = true;

	resultGui.RaceName.Text = raceinfo.RaceName;
	resultGui.YourBest.YourBestTime.Text = ConvertValueToTime(raceinfo.YourBest);
	resultGui.WorldRecord.WorldRecordTime.Text = raceinfo.WorldRecordTime;
end

ReplicatedStorage.raceTriggers.GuiOpen.OnClientEvent:Connect(GuiOpened);

--| Close button:

raceGui.Close.MouseButton1Click:Connect(function()
	raceGui.Visible = false;
end);

--| Start time trial:

local sdColour = Color3.fromRGB(255, 50, 0)
local goldColour = Color3.fromRGB(255, 200, 0);
local silverColour = Color3.fromRGB(176, 176, 176);
local bronzeColour = Color3.fromRGB(176, 99, 36);
local limitColour = Color3.new(1, 1, 1);

local betterColour = Color3.fromRGB(25, 212, 103);
local equalColour = Color3.fromRGB(180, 180, 180);
local worseColour = Color3.fromRGB(255, 47, 47);

local defaultLoopFadeOut = TweenService:Create(defaultSongLoop, TweenInfo.new(2), {["Volume"] = 0});

local TimeTrial = require(ReplicatedStorage.Modules.TimeTrial);

function BeginTrial()
	if not currentId then
		warn("No current race id, unable to start");
		return;
	end

	racing = true;
	raceGui.Visible = false;

	local ttFolder = workspace.TimeTrials[currentId]
	local checkpoints = ttFolder.Checkpoints;

	local newTrial = TimeTrial.new(player, currentId, raceGui.Parent.Timer);
	newTrial:InitializeCheckpoints(checkpoints);

	controls:Disable();
	character.HumanoidRootPart.CFrame = ttFolder.StartPart.CFrame;

	timer.Text = "-";
	timer.TextColor3 = Color3.new(1, 1, 1)
	timer.Visible = true;

	task.wait(1);

	game.ReplicatedStorage.RemoteEvents.SpawnCar:FireServer(player.sledstats.SledType.Value);

	defaultSongIntro.TimePosition = 0;
	defaultSongIntro:Play();
	task.wait(2.64);
	character.HumanoidRootPart.Anchored = true;
	controls:Enable();

	for i = 3, 1, -1 do
		timer.Text = tostring(i);
		task.wait(1);
	end

	defaultSongLoop.TimePosition = 0;
	defaultSongLoop:Play();

	task.spawn(function()
		for i = 1, 5, 1 do
			task.wait(1);
			if not defaultSongLoop.Playing then
				defaultSongLoop:Play();
				defaultSongLoop.Volume = 0.5;
			end
			if not timer.Visible then
				timer.Visible = true;
			end
		end
	end);

	character.HumanoidRootPart.Anchored = false;

	local success, result, xptable = newTrial:Start();

	--| Results:

	if success then
		task.spawn(function()
			task.wait(3);
			timer.Visible = false;
		end)

		resultGui.TimeResults.ClientTime.Text = ConvertValueToTime(result[1]);
		resultGui.TimeResults.ServerTime.Text = ConvertValueToTime((math.round(result[2] * 10)));

		local finalTime = math.round(result[3] * 10)
		local finalFormattedTime = ConvertValueToTime(finalTime);
		resultGui.TimeResults.osTime.Text  = finalFormattedTime;
		resultGui.FinalResult.FinalTime.Text  = finalFormattedTime;

		resultGui.FinalResult.Rank.TextColor3 = timer.TextColor3;

		if xptable.sd == true then
			resultGui.FinalResult.Rank.Text = "SPEED DEMON";
			resultGui.FinalResult.Rank.TextColor3 = sdColour;
		elseif timer.TextColor3 == goldColour then
			resultGui.FinalResult.Rank.Text = "Gold";
		elseif timer.TextColor3 == silverColour then
			resultGui.FinalResult.Rank.Text = "Silver";
		elseif timer.TextColor3 == bronzeColour then
			resultGui.FinalResult.Rank.Text = "Bronze";
		elseif timer.TextColor3 == limitColour then
			resultGui.FinalResult.Rank.Text = "None";
		end

		local bestDiff = finalTime - ConvertTimeToValue(raceGui.YourBest.YourBestTime.Text);
		local BDFormatted = ConvertValueToTime(bestDiff);
		if bestDiff == finalTime then
			BDFormatted = "-";
			resultGui.YourBest.YourBestDiff.TextColor3 = equalColour;
		elseif bestDiff < 0 then
			resultGui.YourBest.YourBestDiff.TextColor3 = betterColour;
		elseif bestDiff == 0 then
			BDFormatted = "±"..BDFormatted;
			resultGui.YourBest.YourBestDiff.TextColor3 = equalColour;
		elseif bestDiff > 0 then
			BDFormatted = "+"..BDFormatted;
			resultGui.YourBest.YourBestDiff.TextColor3 = worseColour;
		end

		resultGui.YourBest.YourBestDiff.Text = BDFormatted

		local wrDiff = finalTime - ConvertTimeToValue(raceGui.WorldRecord.WorldRecordTime.Text);
		local wrFormatted = ConvertValueToTime(wrDiff);
		if wrDiff == finalTime then
			wrFormatted = "-";
			resultGui.WorldRecord.WorldRecordDiff.TextColor3 = equalColour;
		elseif wrDiff < 0 then
			resultGui.WorldRecord.WorldRecordDiff.TextColor3 = betterColour;
		elseif wrDiff == 0 then
			wrFormatted = "±"..wrFormatted;
			resultGui.WorldRecord.WorldRecordDiff.TextColor3 = equalColour;
		elseif wrDiff > 0 then
			wrFormatted = "+"..wrFormatted;
			resultGui.WorldRecord.WorldRecordDiff.TextColor3 = worseColour;
		end

		resultGui.WorldRecord.WorldRecordDiff.Text = wrFormatted

		resultGui.XpResults.TimeXP.Text = tostring(xptable.timexp);
		
		if xptable.newbest == true then
			resultGui.XpResults.NewBestXP.Text = tostring(newTrial.Infos.Difficulty * 40);
			game.ReplicatedStorage.raceTriggers.updateLB:FireServer(currentId);
		else
			resultGui.XpResults.NewBestXP.Text = "0";
		end

		if xptable.sd == true then
			resultGui.XpResults.SpeedDemonXP.Text = tostring(newTrial.Infos.Difficulty * 1000);
		else
			resultGui.XpResults.SpeedDemonXP.Text = "0";
		end

		resultGui.XpResults.TotalXP.Text = xptable.totalxp;

		currentId = "";
		resultGui.Visible = true;

		resultGui.Close.MouseButton1Click:Connect(function()
			resultGui.Visible = false;
		end);
	end
	racing = false;
	defaultLoopFadeOut:Play();
	task.wait(2);
	timer.Visible = false;
	defaultSongLoop:Stop()
	defaultSongLoop.TimePosition = 0;
	defaultSongLoop.Volume = 0.5;
end

raceGui.Start.MouseButton1Click:Connect(BeginTrial);