local ReplicatedStorage : ReplicatedStorage = game:GetService("ReplicatedStorage");
local TweenService : TweenService = game:GetService("TweenService");
local ContextActionService : ContextActionService = game:GetService("ContextActionService");
local Players : Players = game:GetService("Players");
local EasyVisuals = require(ReplicatedStorage.Modules.UI.EasyVisuals);
local formatTime = require(ReplicatedStorage.Modules.sledutils).formatTime;

local player : Player = Players.LocalPlayer;

local raceOpenEvent : RemoteEvent =  ReplicatedStorage:WaitForChild("RemoteEvents").Race.RaceOpen;
local raceUI : Frame = script.Parent;
local ttInfoPage : Frame = raceUI.TimeTrial.InfoPage;
local ttLbTemplate : Frame = raceUI.TimeTrial.Leaderboard.PlaceTemplate;

local emptyPlayerIcon : string = "rbxassetid://6034268008";



--[[

* Time Trial UI

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

    --| Don't reset everything if nothing is going to change
    if (lastOpenedTT == raceData.raceID and time() - lastOpenedTime < 60) then
        raceUI.Visible = true;
        ttInfoPage.Best.Text = formatTime(player.Data.racestats[raceData.raceID].Value);
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

    ttInfoPage.Best.Text = formatTime(player.Data.racestats[raceData.raceID].Value);

    for i : number, lbEntry : table in ipairs(raceData.lbData) do
        local newFrame = buildLbFrame(lbEntry, i);
        newFrame.Parent = raceUI.TimeTrial.Leaderboard.Container;
    end

    raceUI.Visible = true;
end

raceOpenEvent.OnClientEvent:Connect(loadUI);



--[[

* Multiplayer UI

]]





--[[

* Primary Buttons

]]--



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
local statusChangeEvent : RemoteEvent = ReplicatedStorage.RemoteEvents.Race.StatusChange;

local checkpointFolder : Folder = nil;
local curCheckpoint = 0;
local returnToStartPart : BasePart = nil;
local sled : Model = nil;

local racing : boolean = false;

local raceHUD : Frame = script.Parent.Parent.RaceHUD;
local buttonsHUD : Frame = script.Parent.Parent.Buttons;

local ttFinishHUD : Frame = raceHUD.TimeTrialResults;
local bestGradient : table = nil;
local newBestColorSequence = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
    ColorSequenceKeypoint.new(0.25, Color3.new(1, 0.7, 0)),
    ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
    ColorSequenceKeypoint.new(0.75, Color3.new(1, 0.7, 0)),
    ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1))
});
local wrColorSequence = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromHex("0084ff")),
    ColorSequenceKeypoint.new(0.25, Color3.fromHex("9500ff")),
    ColorSequenceKeypoint.new(0.5, Color3.fromHex("00ff73")),
    ColorSequenceKeypoint.new(0.75, Color3.fromHex("d900ff")),
    ColorSequenceKeypoint.new(1, Color3.fromHex("0084ff"))
});

local dqWindow : Frame = raceHUD.Disqualified;

local stopwatchConnection : RBXScriptConnection = nil;
local checkpointConnection : RBXScriptConnection = nil;
local tpLastConnection : RBXScriptConnection = nil;

local baseTweenInfo : TweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Sine);

local function revealCheckpoint(checkpointNumber : number) : nil

    curCheckpoint = checkpointNumber - 1;
    local nextCheckpoint : Model = checkpointFolder:FindFirstChild(tostring(checkpointNumber));

    if nextCheckpoint then
        nextCheckpoint.Ring.Transparency = 0;
        nextCheckpoint.Ring.ParticleEmitter.Enabled = true;

        raceHUD.CheckpointProgress.Text = tostring(curCheckpoint) .. "/" .. tostring(#checkpointFolder:GetChildren());
    else
        TweenService:Create(
            raceHUD.CheckpointProgress,
            baseTweenInfo,
            {["TextTransparency"] = 1, ["BackgroundTransparency"] = 1}
        ):Play();
    end

    local lastCheckpoint : Model = checkpointFolder:FindFirstChild(tostring(curCheckpoint));

    if lastCheckpoint then
        lastCheckpoint.Ring.Transparency = 1;
        lastCheckpoint.Ring.ParticleEmitter.Enabled = false;
    end
end

local function tpLastCheckpoint(actionName : string | GuiButton, inputState : Enum.UserInputState, inputObject : InputObject)
    if typeof(actionName) ~= "string" or inputState == Enum.UserInputState.Begin then
        sled.Components.Lock.Enabled = true;
        sled.Components.RotLock.Enabled = true;

        if curCheckpoint == 0 then
            player.Character:PivotTo(returnToStartPart.CFrame);
        else
            player.Character:PivotTo(checkpointFolder:FindFirstChild(tostring(curCheckpoint)).Hitbox.CFrame * CFrame.Angles(0, -math.rad(90), 0));
        end
        
        task.wait(0.5);
        sled.Components.Lock.Enabled = false;
        sled.Components.RotLock.Enabled = false;
    end
end

local function raceStart() : nil

    stopwatchConnection = stopwatchEvent.OnClientEvent:Connect(function(timeType : string, timeValue : number) : nil
        if timeType == "COUNTDOWN" then
            raceHUD.Stopwatch.Text = tostring(timeValue);
        elseif timeType == "TICK" then
            if not racing then
                racing = true;
            end
            raceHUD.Stopwatch.Text = formatTime(timeValue);
        end
    end);

    revealCheckpoint(1);

    checkpointConnection = checkpointEvent.OnClientEvent:Connect(function(checkpointNumber) : nil
        revealCheckpoint(checkpointNumber);
    end);

    sled = workspace:WaitForChild(player.Name .. "'s sled");

    repeat task.wait() until racing == true;

    ContextActionService:BindAction("TPLastCheckpoint", tpLastCheckpoint, false, Enum.KeyCode.R);
    tpLastConnection = raceHUD.TPLastCheckpoint.MouseButton1Click:Connect(tpLastCheckpoint);
    
    raceHUD.TPLastCheckpoint.Visible = true;
    TweenService:Create(
        raceHUD.TPLastCheckpoint,
        baseTweenInfo,
        {["TextTransparency"] = 0, ["BackgroundTransparency"] = 0.25}
    ):Play();
end

local function raceInit(raceID : string, party : {Player}?) : nil
    raceUI.Visible = false;
    checkpointFolder = workspace:WaitForChild("TimeTrials"):FindFirstChild(raceID).Checkpoints;
    returnToStartPart = checkpointFolder.Parent.StartPart;

    -- slide out buttons hud and show race hud
    raceHUD.Stopwatch.Text = "0:00.0";
    raceHUD.CheckpointProgress.Text = "0/" .. tostring(#checkpointFolder:GetChildren());

    TweenService:Create(
        raceHUD.Stopwatch,
        baseTweenInfo,
        {["TextTransparency"] = 0, ["BackgroundTransparency"] = 0.25}
    ):Play();

    TweenService:Create(
        raceHUD.CheckpointProgress,
        baseTweenInfo,
        {["TextTransparency"] = 0, ["BackgroundTransparency"] = 0.25}
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
    tpLastConnection:Disconnect();
    tpLastConnection = nil;
    sled = nil;
    racing = false;

    ContextActionService:UnbindAction("TPLastCheckpoint");

    TweenService:Create(
        raceHUD.CheckpointProgress,
        baseTweenInfo,
        {["TextTransparency"] = 1, ["BackgroundTransparency"] = 1}
    ):Play();

    TweenService:Create(
        raceHUD.Stopwatch,
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

    TweenService:Create(
        raceHUD.TPLastCheckpoint,
        baseTweenInfo,
        {["TextTransparency"] = 0, ["BackgroundTransparency"] = 0.25}
    ):Play();

    task.wait(0.5);
    raceHUD.TPLastCheckpoint.Visible = false;
end

local function playerBackToStart() : nil
    player.Character.Humanoid.Sit = false;
    player.Character:PivotTo(returnToStartPart.CFrame);
    returnToStartPart = nil;
end

local function onStatusEvent(eventType : string, data : {string}) : nil
    for _, checkpoint : Model in pairs(checkpointFolder:GetChildren()) do
        if checkpoint.Ring.Transparency == 0 then
            checkpoint.Ring.Transparency = 1;
            checkpoint.Ring.ParticleEmitter.Enabled = false;
        end
    end

    if eventType == "FINISHED" then
        ttFinishHUD.Score.Text = formatTime(data.Score);
        ttFinishHUD.Best.Text = data.Best;
        ttFinishHUD.Rating.Text = data.Rating;
        ttFinishHUD.XP.Text = data.XP;
        ttFinishHUD.WR.Text = data.WR;
        ttFinishHUD.BestDiff.Text = data.BestDiff;
        ttFinishHUD.WRDiff.Text = data.WRDiff;

        print(data.BestDiff)

        if (string.sub(data.BestDiff, 1, 1) == "+") then
            ttFinishHUD.BestDiff.TextColor3 = Color3.fromRGB(63, 253, 114);
        else
            ttFinishHUD.BestDiff.TextColor3 = Color3.fromRGB(200, 50, 50);
        end

        if (string.sub(data.WRDiff, 1, 1) == "+") then
            ttFinishHUD.WRDiff.TextColor3 = Color3.fromRGB(63, 253, 114);
        else
            ttFinishHUD.WRDiff.TextColor3 = Color3.fromRGB(200, 50, 50);
        end

        if data.Best == "World Record!" then
            bestGradient = EasyVisuals.Gradient.new(ttFinishHUD.Best, wrColorSequence, 0);
            bestGradient:SetOffsetSpeed(0.5, 1);
        elseif data.Best == "New best!" then
            bestGradient = EasyVisuals.Gradient.new(ttFinishHUD.Best, newBestColorSequence, 0);
            bestGradient:SetOffsetSpeed(0.5, 1);
        end

        ttFinishHUD.Visible = true;

        ttFinishHUD.BackToStart.MouseButton1Click:Once(function() : nil
            playerBackToStart();

            if bestGradient then
                bestGradient:Destroy();
                bestGradient = nil;
            end

            ttFinishHUD.Visible = false;
        end);

        ttFinishHUD.Close.MouseButton1Click:Once(function() : nil
            ttFinishHUD.Visible = false;
        end);

    else
        if eventType == "LIMIT_REACHED" then
            dqWindow.TimeLimitMessage.Visible = true;
        elseif eventType == "ABORTED" then
            dqWindow.AbortMessage.Visible = true;
        end

        dqWindow.Visible = true;

        dqWindow.BackToStart.MouseButton1Click:Once(function() : nil
            playerBackToStart();
            dqWindow.Visible = false;
            dqWindow.TimeLimitMessage.Visible = false;
            dqWindow.AbortMessage.Visible = false;
        end);

        dqWindow.Close.MouseButton1Click:Once(function() : nil
            dqWindow.Visible = false;
            dqWindow.TimeLimitMessage.Visible = false;
            dqWindow.AbortMessage.Visible = false;
        end);
    end

    raceCleanup();
end


ttStartButton.MouseButton1Click:Connect(function() : nil
    startEvent:FireServer(lastOpenedTT);
end);

startEvent.OnClientEvent:Connect(raceInit);
statusChangeEvent.OnClientEvent:Connect(onStatusEvent);



--[[

gradient effects

local EasyVisuals = require(game.ReplicatedStorage.Modules.UI.EasyVisuals);
local Gradient = EasyVisuals.Gradient.new(script.Parent, myColorSequence, 0);
-- Then we can use the gradient to apply it to an object
Gradient:SetOffsetSpeed(0.5, 1)
print(Gradient.IsPaused);

]]