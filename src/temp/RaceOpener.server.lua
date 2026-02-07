local ReplicatedStorage : ReplicatedStorage = game:GetService("ReplicatedStorage");

local raceID : string = script.Parent.Parent.Parent.Parent.Name;

local TimeTrialInfos = require(ReplicatedStorage:WaitForChild("Shared").Modules.TimeTrialInfos);
local thisTrialInfo = TimeTrialInfos[raceID];

local responseFunc =  ReplicatedStorage:WaitForChild("RemoteEvents").RaceResponse;

function onPromptTriggered(player)
    local raceResponce : boolean = responseFunc:InvokeClient(player, raceID, thisTrialInfo);
    
    if (raceResponce == true) then
        
    else

    end
end

script.Parent.ProximityPrompt.Triggered:Connect(onPromptTriggered);