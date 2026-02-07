local ReplicatedStorage : ReplicatedStorage = game:GetService("ReplicatedStorage");
local UserService : UserService = game:GetService("UserService");
local Players : Players = game:GetService("Players");

local raceOpenEvent : RemoteEvent =  ReplicatedStorage:WaitForChild("RemoteEvents").RaceOpen;
local raceUI : Frame = script.Parent;
local ttInfoPage : Frame = raceUI.TimeTrial.InfoPage;
local ttLbTemplate : Frame = raceUI.TimeTrial.Leaderboard.PlaceTemplate;

local emptyPlayerIcon : string = "rbxassetid://6034268008";

local function formatTime(t : number) : string
    if t == 99999 then
        return "-:--";
    end

    local minutes = math.floor(t / 60);
    local seconds = math.floor(t % 60);
    local tenths = math.floor((t - math.floor(t)) * 10);
    return string.format("%d:%02d.%d", minutes, seconds, tenths);
end



--[[

* Time Trial

TODO: maybe some error handling if the server fails to send data? (timeout after like 5 seconds and show an error message on loading screen or something)

]]--



local lastOpenedTT : string = "";
local lastOpenedTime : number = time() - 60;

local function buildLbFrame(lbEntry : table, place : number) : Frame
    local newFrame : Frame = ttLbTemplate:Clone();
    newFrame.Name = tostring("lb" .. place);
    newFrame.Place.Text = "#" .. tostring(place);
    newFrame.Time.Text = formatTime(lbEntry.score);
    newFrame.LayoutOrder = place;
    
    --| Try to get user info, if it fails use default values
    if (lbEntry.userId == nil) then
        newFrame.Player.Text = "Unknown User";
        newFrame.Thumbnail.Image = emptyPlayerIcon;
        return newFrame;
    end

    newFrame.Player.Text = lbEntry.displayName .. " @" .. lbEntry.username;
    newFrame.Thumbnail.Image = lbEntry.thumbnail;

    newFrame.Size = UDim2.new(1, 0, 0.1, 0);
    newFrame.Visible = true;

    return newFrame;
end

local function loadUI(raceData : table) : nil

    --[[

     local raceData : table = {
        ["raceID"] = raceID :: string
        ["trialInfo"] = thisTrialInfo :: table
        ["playerScore"] = player.Data.racestats[raceID].Value :: number
        ["lbData"] = lbData :: table
    }
    
    ]]

    --| Don't send new requests if the info has no chance of changing (and prevents spamming)

    if (lastOpenedTT == raceData.raceID and time() - lastOpenedTime < 60) then
        raceUI.Visible = true;
        return;
    end

    lastOpenedTT = raceData.raceID;
    lastOpenedTime = time();

    --| Clear ui first

    for _, child : Frame in ipairs(raceUI.TimeTrial.Leaderboard.Container:GetChildren()) do
        child:Destroy();
    end

    ttInfoPage.TrialName.Text = raceData.trialInfo.Name;
    ttInfoPage.Difficulty.Text = raceData.trialInfo.Difficulty;
    ttInfoPage.DifficultyRating.Text = raceData.trialInfo.DifficultyRating;
    ttInfoPage.Route.Text = raceData.trialInfo.Route;
    ttInfoPage.Gold.Text = formatTime(raceData.trialInfo.Times.Gold);
    ttInfoPage.Silver.Text = formatTime(raceData.trialInfo.Times.Silver);
    ttInfoPage.Bronze.Text = formatTime(raceData.trialInfo.Times.Bronze);
    ttInfoPage.Limit.Text = formatTime(raceData.trialInfo.Times.Limit);

    ttInfoPage.Best.Text = formatTime(raceData.playerScore);

    for i : number, lbEntry : table in ipairs(raceData.lbData) do
        local newFrame = buildLbFrame(lbEntry, i);
        newFrame.Parent = ttInfoPage.Leaderboard.Container;
    end

    raceUI.Visible = true;
end

raceOpenEvent.OnClientEvent:Connect(loadUI);



--[[

* Primary Buttons

]]--



local function timeTrialStart() : nil
    -- TODO: Fire server to start
end

ttInfoPage.Start.MouseButton1Click:Connect(timeTrialStart);


local function closeMenu() : nil
    raceUI.Visible = false;
end

raceUI.Close.MouseButton1Click:Connect(closeMenu);