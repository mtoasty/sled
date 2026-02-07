local racingPlayers = {};

function OnServerEvent(player: Player, command: string, xp: number, curtime: number, raceId: string)
    if command == "Start" then
        task.spawn(function()
            local serverTime = time();
            local osTime = os.clock();
            racingPlayers[player.Name] = {serverTime, osTime};
        end);
        return true;
    elseif command == "Stop" then
        local serverTime = time();
        local osTime = os.clock();
        local deltaServer = serverTime - racingPlayers[player.Name][1];
        local deltaos = osTime - racingPlayers[player.Name][2];

        racingPlayers[player.Name] = nil;

        return deltaServer, deltaos;
    elseif command == "Abort" then
        racingPlayers[player.Name] = nil;
        return true;
    elseif command == "End" then
        local currentPlayerScore = player.racestats[raceId].Value;
        if curtime < currentPlayerScore then
            player.racestats[raceId].Value = curtime;
        end

        player.sledstats.xp.Value += xp;
    end
end

game.ReplicatedStorage.raceTriggers.RaceEvent.OnServerInvoke = OnServerEvent;