local ReplicatedStorage : ReplicatedStorage = game:GetService("ReplicatedStorage");
local ServerStorage : ServerStorage = game:GetService("ServerStorage");

local TimeTrial : table = require(ReplicatedStorage:WaitForChild("Modules").Race.TimeTrial);
local Stopwatch : table = require(ReplicatedStorage.Modules.Race.Stopwatch);
local TimeTrialInfos : table = require(ReplicatedStorage.Modules.Race.TimeTrialInfos);

local startEvent : RemoteEvent = ReplicatedStorage.RemoteEvents.Race.Start;
local stopwatchEvent : UnreliableRemoteEvent = ReplicatedStorage.RemoteEvents.Race.Stopwatch;
local statusChangeEvent : RemoteEvent = ReplicatedStorage.RemoteEvents.Race.StatusChange;

local leaderboardFetch : BindableFunction = ServerStorage.ServerEvents.LeaderboardFetch;

local spawnSled : BindableEvent = ServerStorage:WaitForChild("ServerEvents").SpawnSled;

local function formatTime(t : number) : string
    if t == 99999 or t == math.huge then
        return "-:--";
    end

    local minutes = math.floor(t / 60);
    local seconds = math.floor(t % 60);
    local ms = math.floor((t - math.floor(t)) * 1000);
    return string.format("%d:%02d.%d", minutes, seconds, ms);
end

local function timeTrialComplete(player: Player, raceID : string, finalTime : number, ttInfo : table) : table
    -- award xp, send final score
    local lbData = leaderboardFetch:Invoke(raceID, true);
    local firstPlaceTime = math.huge;
    local thisTrialRatings = ttInfo.Times;

    if lbData and #lbData > 0    then
        firstPlaceTime = lbData[1].value;
    end

    local xp = 0;

    local results = {
        ["Score"] = finalTime,
        ["Best"] = "-:--",
        ["Rating"] = "-",
        ["XP"] = ""
    };

    results.Best = formatTime(finalTime);

    if finalTime < firstPlaceTime then
        results.Best = "World Record!";
        xp += 1000;
        -- TODO: Update ds
    elseif finalTime < player.Data.racestats[raceID] then
        results.Best = "New best!";
        xp += 250;
        -- TODO: Update ds
    end

    if finalTime < (thisTrialRatings.Gold - 5) then
        -- speed demon
        xp += ttInfo.Difficulty * 250
        results.Rating = "SPEED DEMON";
    elseif finalTime < thisTrialRatings.Gold then
        -- gold
        xp += ttInfo.Difficulty * 100
        results.Rating = "Gold";
    elseif finalTime < thisTrialRatings.Silver then
        -- silver
        xp += ttInfo.Difficulty * 75
        results.Rating = "Silver";
    elseif finalTime < thisTrialRatings.Bronze then
        -- bronze
        xp += ttInfo.Difficulty * 50
        results.Rating = "Bronze";
    else
        -- none
        xp += ttInfo.Difficulty * 25
        results.Rating = "None";
    end

    for i : number, lbEntry in ipairs(lbData) do
        if lbEntry.key == player.UserId then
            results.Best = results.Best .. " #" .. i;
            break;
        end
    end

    results.XP = tostring(xp) .. " XP";
    
    -- TODO: update player xp

    return results;
end

local function beginTimeTrial(player : Player, raceID : string) : nil
    local ttInfo : table = TimeTrialInfos[raceID];
    local ttWorkspace = workspace:WaitForChild("TimeTrials"):FindFirstChild(raceID);
    
    local newStopwatch : table = Stopwatch.new(ttInfo.Times.Limit);
    local newTimeTrial : table = TimeTrial.new(player, raceID, ttWorkspace.Checkpoints, newStopwatch);

    newTimeTrial.event.Event:Connect(function(eventType : string) : nil
        local data : table = nil;
        if eventType == "FINISHED" then
            data = timeTrialComplete(player, raceID, newStopwatch.elapsed, ttInfo);
        end
        statusChangeEvent:FireClient(player, eventType, data);
    end);

    startEvent:FireClient(player, raceID);
    task.spawn(function() : nil
        newTimeTrial:Start(raceID);
    end);

    task.wait(1); --| Allow time for client to connect to stopwatch


    player.Character.HumanoidRootPart.Anchored = true;
    player.Character:PivotTo(ttWorkspace.StartPart.CFrame);
    spawnSled:Fire(player, player.Data.sledConfig.sledType.Value);

    local newSled = workspace:WaitForChild(player.Name .. "'s sled", 10)
    if newSled == nil then
        warn("Sled failed to spawn for player " .. player.Name .. ". Race cancelled");
        -- error handling if sled doesn't spawn for some reason
        return;
    end

    newSled.Components.VehicleSeat.Anchored = true;
    player.Character.HumanoidRootPart.Anchored = false;

    newTimeTrial:EnableEndEventListeners();

    for i = 3, 1, -1 do
        stopwatchEvent:FireClient(player, "COUNTDOWN", i);
        task.wait(1);
    end

    newStopwatch:Start();
    newSled.Components.VehicleSeat.Anchored = false;

    while newTimeTrial.timing do
        stopwatchEvent:FireClient(player, "TICK", newStopwatch.elapsed);
        task.wait(0.1);
    end
end




local function beginPartyRace(raceID: string, party : {Player}) : nil

end




local function handleServerEvent(player : Player, raceID : string, party : {Player}?) : nil
    if party then
        table.insert(party, player, 1);
        beginPartyRace(raceID, party);
    else
        beginTimeTrial(player, raceID);
    end
end


startEvent.OnServerEvent:Connect(handleServerEvent);