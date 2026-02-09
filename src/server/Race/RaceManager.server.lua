local ReplicatedStorage : ReplicatedStorage = game:GetService("ReplicatedStorage");
local ServerStorage : ServerStorage = game:GetService("ServerStorage");

local TimeTrial : table = require(ReplicatedStorage:WaitForChild("Modules").Race.TimeTrial);
local Stopwatch : table = require(ReplicatedStorage.Modules.Race.Stopwatch);
local TimeTrialInfos : table = require(ReplicatedStorage.Modules.Race.TimeTrialInfos);

local raceOpenEvent : RemoteEvent =  ReplicatedStorage:WaitForChild("RemoteEvents").Race.RaceOpen;
local startEvent : RemoteEvent = ReplicatedStorage.RemoteEvents.Race.Start;
local stopwatchEvent : UnreliableRemoteEvent = ReplicatedStorage.RemoteEvents.Race.Stopwatch;
local checkpointEvent : RemoteEvent = ReplicatedStorage.RemoteEvents.Race.Checkpoint

local spawnSled : BindableEvent = ServerStorage:WaitForChild("ServerEvents").SpawnSled;



local function timeTrialComplete()
    -- award xp, send final score

    -- cleanup
end

local function beginTimeTrial(player : Player, raceID : string) : nil
    print("Time trial " .. raceID .. " for " .. player.Name .. " request accepted");
    local ttInfo : table = TimeTrialInfos[raceID];
    local ttWorkspace = workspace:WaitForChild("TimeTrials"):FindFirstChild(raceID);
    
    print("Initializing stopwatch and time trial");
    local newStopwatch : table = Stopwatch.new(ttInfo.Times.Limit);
    local newTimeTrial : table = TimeTrial.new(player, raceID, ttWorkspace.Checkpoints, newStopwatch);

    newTimeTrial.event.Event:Connect(function(eventType : string) : nil
        if eventType == "FINISH" then
            --| Handle finish
            print("FINISH")
            timeTrialComplete();
        elseif eventType == "LIMIT_REACHED" then
            print("LIMIT_REACHED")
            --| Handle limit reached
        elseif eventType == "ABORTED" then
            print("ABORTED");
            --| Handle aborted
        end
    end);

    print("Signalling start to client and beginning");
    startEvent:FireClient(player, raceID);
    task.spawn(function() : nil
        newTimeTrial:Start(raceID);
    end);

    task.wait(1); --| Allow time for client to connect to stopwatch

    print("Setting up character and sled")
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

    print("Time trial started");
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