local ReplicatedStorage : ReplicatedStorage = game:GetService("ReplicatedStorage");
local ServerStorage : ServerStorage = game:GetService("ServerStorage");

local raceID : string = script.Parent.raceID.Value;


local TimeTrialInfos : table = require(ReplicatedStorage:WaitForChild("Modules").TimeTrialInfos);
local thisTrialInfo : table = TimeTrialInfos[raceID];

local raceOpenEvent : RemoteEvent =  ReplicatedStorage:WaitForChild("RemoteEvents").RaceOpen;

function onPromptTriggered(player : Player) : nil

    -- fetch recent leaderboard data
    local lbData : table = ServerStorage.ServerEvents.LeaderboardFetch:Invoke(raceID);

    local raceData : table = {
        ["raceID"] = raceID,
        ["trialInfo"] = thisTrialInfo,
        ["playerScore"] = player.Data.racestats[raceID].Value,
        ["lbData"] = lbData
    }

    raceOpenEvent:FireClient(player, raceData);
end

script.Parent.ProximityPrompt.Triggered:Connect(onPromptTriggered);
