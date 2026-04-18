local ReplicatedStorage : ReplicatedStorage = game:GetService("ReplicatedStorage");
local ServerStorage : ServerStorage = game:GetService("ServerStorage");
local BadgeService : BadgeService = game:GetService("BadgeService");

local TimeTrial : table = require(ReplicatedStorage:WaitForChild("Modules").Race.TimeTrial);
local Stopwatch : table = require(ReplicatedStorage.Modules.Race.Stopwatch);
local TimeTrialInfos : table = require(ReplicatedStorage.Modules.Race.TimeTrialInfos);
local xpRequirement = require(ReplicatedStorage.Modules.sledutils).xpRequirement;

local startEvent : RemoteEvent = ReplicatedStorage.RemoteEvents.Race.Start;
local stopwatchEvent : UnreliableRemoteEvent = ReplicatedStorage.RemoteEvents.Race.Stopwatch;
local statusChangeEvent : RemoteEvent = ReplicatedStorage.RemoteEvents.Race.StatusChange;
local multiplayerEvent : RemoteEvent = ReplicatedStorage.RemoteEvents.Race.MultiplayerEvent;

local leaderboardFetch : BindableFunction = ServerStorage.ServerEvents.LeaderboardFetch;

local spawnSled : BindableEvent = ServerStorage:WaitForChild("ServerEvents").SpawnSled;

local formatTime = require(ReplicatedStorage.Modules.sledutils).formatTime;

--| XP for next level = (current level)^2 * log(current level) + 100, floored.
--| Repeatedly update the player's level until they don't have enough XP
local function developPlayerLevel(player : Player) : nil
    local playerLevel = player.Data.playerstats.level.Value;
    local xpNeeded = xpRequirement(playerLevel);
    local playerXP = player.Data.playerstats.xp.Value;
    local levelsGained = 0;
    while playerXP >= xpNeeded do
        playerLevel += 1;
        levelsGained += 1;
        
        playerXP = playerXP - xpNeeded;
        xpNeeded = xpRequirement(playerLevel);
    end

    if levelsGained > 0 then
        player.Data.playerstats.level.Value = playerLevel;
    end

    player.Data.playerstats.xp.Value = playerXP;
end

local function timeTrialComplete(player: Player, raceID : string, finalTime : number, ttInfo : table) : table
    -- award xp, send final score
    local lbData = leaderboardFetch:Invoke(raceID, true);
    local firstPlaceTime = math.huge;
    local thisTrialRatings = ttInfo.Times;
    local playerBest = player.Data.racestats[raceID].Value;

    if lbData and #lbData > 0 then
        firstPlaceTime = (lbData[1].value) / 1000;
    end

    local xp = 0;

    local results = {
        ["Score"] = finalTime,
        ["Best"] = "-:--",
        ["Rating"] = "-",
        ["XP"] = "",
        ["WR"] = formatTime(firstPlaceTime),
        ["BestDiff"] = "n/a",
        ["WRDiff"] = "n/a"
    };

    if playerBest ~= math.huge and playerBest ~= 99999 then
        results.Best = formatTime(playerBest);
        results.BestDiff = formatTime(math.abs(finalTime - playerBest));

        if finalTime <= playerBest then
            results.BestDiff = "-" .. results.BestDiff;
        else
            results.BestDiff = "+" .. results.BestDiff;
        end
    else
        results.Best = "-:--";
    end

    if firstPlaceTime ~= math.huge and firstPlaceTime ~= 99999 then
        results.WRDiff = formatTime(math.abs(finalTime - firstPlaceTime));

        if finalTime <= firstPlaceTime then
            results.WRDiff = "-" .. results.WRDiff;
        else
            results.WRDiff = "+" .. results.WRDiff;
        end
    else
        results.WR = "-:--";
    end

    if finalTime < firstPlaceTime and (firstPlaceTime ~= math.huge and firstPlaceTime ~= 99999) then
        results.Best = "World Record!";
        xp += 1000;
        
        ServerStorage.ServerEvents.Leaderboard:Fire(raceID, player.UserId, finalTime);
        player.Data.racestats[raceID].Value = finalTime;
    elseif finalTime < playerBest then
        results.Best = "New best!";
        xp += 250;
        
        ServerStorage.ServerEvents.Leaderboard:Fire(raceID, player.UserId, finalTime);
        player.Data.racestats[raceID].Value = finalTime;
    end

    if finalTime < (thisTrialRatings.Gold - 5) then
        xp += ttInfo.Difficulty * 250;
        results.Rating = "SPEED DEMON";
        BadgeService:AwardBadgeAsync(player.UserId, 2127560958);
    elseif finalTime < thisTrialRatings.Gold then
        xp += ttInfo.Difficulty * 100;
        results.Rating = "Gold";
    elseif finalTime < thisTrialRatings.Silver then
        xp += ttInfo.Difficulty * 75;
        results.Rating = "Silver";
    elseif finalTime < thisTrialRatings.Bronze then
        xp += ttInfo.Difficulty * 50;
        results.Rating = "Bronze";
    else
        xp += ttInfo.Difficulty * 25;
        results.Rating = "None";
    end

    for i : number, lbEntry in ipairs(lbData) do
        if lbEntry.key == player.UserId then
            results.Best = results.Best .. " #" .. i;
            break;
        end
    end

    xp = math.floor(xp);

    results.XP = tostring(xp) .. " XP";

    player.Data.playerstats.xp.Value = player.Data.playerstats.xp.Value + xp;

    developPlayerLevel(player);

    return results;
end

local function eventToAllPlayers(players : {Player}, ...) : nil
    for _, player in pairs(players) do
        multiplayerEvent:FireClient(player, ...);
    end
end

local function beginRace(players : Player | {Player}, raceID : string) : nil
    local ttInfo : table = TimeTrialInfos[raceID];
    local ttWorkspace = workspace:WaitForChild("TimeTrials"):FindFirstChild(raceID);
    
    local newStopwatch : table = Stopwatch.new(ttInfo.Times.Limit);

    for _, player in pairs(players) do
        task.spawn(function() : nil

            local newTimeTrial : table = TimeTrial.new(player, raceID, ttWorkspace.Checkpoints, newStopwatch);

            newTimeTrial.event.Event:Connect(function(eventType : string) : nil
                local data : table = nil;
                if eventType == "FINISHED" then
                    data = timeTrialComplete(player, raceID, newStopwatch.elapsed, ttInfo);
                end

                if #players > 1 then
                    eventToAllPlayers(player, eventType);
                end
                statusChangeEvent:FireClient(player, eventType, data);
            end);

            startEvent:FireClient(player, raceID);
            task.spawn(function() : nil
                newTimeTrial:Start(raceID);
            end);

            task.wait(1); --| Allow time for client to connect to stopwatch


            player.Character.Humanoid.WalkSpeed = 0;
            player.Character.Humanoid.JumpHeight = 0;
            player.Character:PivotTo(ttWorkspace.StartPart.CFrame);
            spawnSled:Fire(player, player.Data.sledConfig.sledType.Value);

            local newSled = workspace:WaitForChild(player.Name .. "'s sled", 10)
            if newSled == nil then
                warn("Sled failed to spawn for player " .. player.Name .. ". Race cancelled");
                -- ! error handling if sled doesn't spawn for some reason
                return;
            end

            newSled.Components.Lock.Enabled = true;
            newSled.Components.RotLock.Enabled = true;

            newTimeTrial:EnableEndEventListeners();

            newTimeTrial.checkpointEvent.Event:Connect(function(checkpointNumber : number)
                 if #players > 1 then
                    eventToAllPlayers(player, checkpointNumber);
                end
            end);


            for i = 3, 1, -1 do
                stopwatchEvent:FireClient(player, "COUNTDOWN", i);
                task.wait(1);
            end

            
            newStopwatch:Start();
            newSled.Components.Lock.Enabled = false;
            newSled.Components.RotLock.Enabled = false;

            player.Character.Humanoid.WalkSpeed = 16;
            player.Character.Humanoid.JumpHeight = 7.2;

            while newTimeTrial.timing do
                stopwatchEvent:FireClient(player, "TICK", newStopwatch.elapsed);
                task.wait(0.1);
            end
        end);
    end
end


local function handleServerEvent(player : Player, raceID : string, party : {Player}?) : nil
    if party then
        table.insert(party, player, 1);
        beginRace(party, raceID);
    else
        beginRace({player}, raceID);
    end
end

startEvent.OnServerEvent:Connect(handleServerEvent);