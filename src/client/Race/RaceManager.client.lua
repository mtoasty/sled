local ReplicatedStorage : ReplicatedStorage = game:GetService("ReplicatedStorage");
local TweenService : TweenService = game:GetService("TweenService");

local raceOpenEvent : RemoteEvent =  ReplicatedStorage:WaitForChild("RemoteEvents").Race.RaceOpen;
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





--[[

* Race operation

]]--

local ttStartButton = ttInfoPage.Start;

local startEvent : RemoteEvent = ReplicatedStorage.RemoteEvents.Race.Start;
local checkpointEvent : RemoteEvent = ReplicatedStorage.RemoteEvents.Race.Checkpoint;
local stopwatchEvent : UnreliableRemoteEvent = ReplicatedStorage.RemoteEvents.Race.Stopwatch;
local checkpointFolder : Folder = nil;

local raceHUD : Frame = script.Parent.Parent.RaceHUD;
local buttonsHUD : Frame = script.Parent.Parent.Buttons;

local stopwatchConnection : RBXScriptConnection = nil;
local checkpointConnection : RBXScriptConnection = nil;

local baseTweenInfo : TweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Sine);

local function revealCheckpoint(checkpointNumber : number) : nil
    local nextCheckpoint : Model = checkpointFolder:FindFirstChild(tostring(checkpointNumber));

    if nextCheckpoint then
        nextCheckpoint.Ring.Transparency = 0;
        nextCheckpoint.Ring.ParticleEmitter.Enabled = true;

        raceHUD.CheckpointProgress.Text = tostring(checkpointNumber - 1) .. "/" .. tostring(#checkpointFolder:GetChildren());
    else
        TweenService:Create(
            raceHUD.CheckpointProgress,
            baseTweenInfo,
            {["TextTransparency"] = 1, ["BackgroundTransparency"] = 1}
        ):Play();
    end

    local lastCheckpoint : Model = checkpointFolder:FindFirstChild(tostring(checkpointNumber - 1));

    if lastCheckpoint then
        lastCheckpoint.Ring.Transparency = 1;
        lastCheckpoint.Ring.ParticleEmitter.Enabled = false;
    end
end

local function raceStart() : nil
    print("Connecting stopwatch");
    stopwatchConnection = stopwatchEvent.OnClientEvent:Connect(function(timeType : string, timeValue : number) : nil
        if timeType == "COUNTDOWN" then
            raceHUD.Stopwatch.Text = tostring(timeValue);
        elseif timeType == "TICK" then
            raceHUD.Stopwatch.Text = formatTime(timeValue);
        end
    end);

    print("Connecting checkpoints");
    revealCheckpoint(1);

    checkpointConnection = checkpointEvent.OnClientEvent:Connect(function(checkpointNumber) : nil
        revealCheckpoint(checkpointNumber);
    end);
end

local function raceInit(raceID : string, party : {Player}?) : nil
    print("Client initializing UI")
    raceUI.Visible = false;
    checkpointFolder = workspace:WaitForChild("TimeTrials"):FindFirstChild(raceID).Checkpoints;

    -- slide out buttons hud and show race hud
    raceHUD.Stopwatch.Text = "0:00.0";
    raceHUD.CheckpointProgress.Text = "0/" .. tostring(#checkpointFolder:GetChildren());

    TweenService:Create(
        raceHUD.Stopwatch,
        baseTweenInfo,
        {["TextTransparency"] = 0.25, ["BackgroundTransparency"] = 0}
    ):Play();

    TweenService:Create(
        raceHUD.CheckpointProgress,
        baseTweenInfo,
        {["TextTransparency"] = 0.25, ["BackgroundTransparency"] = 0}
    ):Play();

    TweenService:Create(
        buttonsHUD,
        baseTweenInfo,
        {["Position"] = UDim2.new(-0.03, 0, 0.5, 0)}
    ):Play();

    if party then
        -- multiplayer window

        -- add player templates

        TweenService:Create(
            raceHUD.Multiplayer,
            baseTweenInfo,
            {["AnchorPoint"] = Vector2.new(0, 0.5)}
        ):Play();
    end

    raceStart();
end

local function raceCleanup(multiplayer : boolean) : nil
    checkpointFolder = nil;
    stopwatchConnection:Disconnect();
    stopwatchConnection = nil;
    checkpointConnection:Disconnect();
    checkpointConnection = nil;

    TweenService:Create(
        raceHUD.CheckpointProgress,
        baseTweenInfo,
        {["TextTransparency"] = 1, ["BackgroundTransparency"] = 1}
    ):Play();

    TweenService:Create(
        raceHUD.CheckpointProgress,
        baseTweenInfo,
        {["TextTransparency"] = 1, ["BackgroundTransparency"] = 1}
    ):Play();

    TweenService:Create(
        buttonsHUD,
        baseTweenInfo,
        {["Position"] = UDim2.new(0, 10, 0.5, 0)}
    ):Play();

    if multiplayer then
        TweenService:Create(
            raceHUD.Multiplayer,
            baseTweenInfo,
            {["AnchorPoint"] = Vector2.new(1, 0.5)}
        ):Play();
    end
end


ttStartButton.MouseButton1Click:Connect(function() : nil
    print("Client pressed start time trial for " .. lastOpenedTT)
    startEvent:FireServer(lastOpenedTT);
end);

startEvent.OnClientEvent:Connect(raceInit);