--[[

How to setup a new time trial/race

1. Create a new folder in this workspace.TimeTrials folder with the raceID as the name

The folder must contain 3 items: which is best to be copied from existing folders
- "Checkpoints" folder with checkpoint models with numbered names in order, the last one has a gold highlight
- "RacePost" model with a proximity prompt for opening the info ui
- "StartPart" which is a part that represents the location of where the trial starts from

2. Create a new entry in the TimeTrialInfos module with the same raceID as the folder name, and fill in the required info such as times and difficulty

The module is located in ReplicatedStorage.Modules.Race.TimeTrialInfos

The times are stored in seconds with tenth precision, for example, 10.5 represents 10 seconds and 5 tenths of a second (or 10 seconds and 500 milliseconds)

]]


local ReplicatedStorage : ReplicatedStorage = game:GetService("ReplicatedStorage");
local ServerStorage : ServerStorage = game:GetService("ServerStorage");

local TimeTrialInfos : table = require(ReplicatedStorage:WaitForChild("Modules").Race.TimeTrialInfos);

local raceOpenEvent : RemoteEvent =  ReplicatedStorage:WaitForChild("RemoteEvents").Race.RaceOpen;

-- ! Cache could cause memory leak, if new players are constantly added
local cachedData : {table} = {};

function onPromptTriggered(playerWhoTriggered : Player, raceID : string) : nil

    --| Prevent spamming leaderboard fetches
    local potentialCache : table = cachedData[playerWhoTriggered.Name];
    if potentialCache then
        if raceID == potentialCache.lastTTOpened and (time() - potentialCache.openedTime) < 60 then
            raceOpenEvent:FireClient(playerWhoTriggered, potentialCache.data);
            return;
        end
    end

    local thisTrialInfo : table = TimeTrialInfos[raceID];

    -- fetch recent leaderboard data
    local lbData : table = ServerStorage.ServerEvents.LeaderboardFetch:Invoke(raceID);

    local raceData : table = {
        ["raceID"] = raceID,
        ["trialInfo"] = thisTrialInfo,
        ["playerScore"] = playerWhoTriggered.Data.racestats[raceID].Value,
        ["lbData"] = lbData
    }

    raceOpenEvent:FireClient(playerWhoTriggered, raceData);

    cachedData[playerWhoTriggered.Name] = {
        ["lastTTOpened"] = raceID,
        ["openedTime"] = time(),
        ["data"] = raceData
    };
end


for _, race : Folder | Script in pairs(script.Parent:GetChildren()) do
    if race:IsA("Folder") then
        race.RacePost.MenuPart.ProximityPrompt.Triggered:Connect(function(playerWhoTriggered : Player) : nil
            onPromptTriggered(playerWhoTriggered, race.Name);
        end);
    end
end
