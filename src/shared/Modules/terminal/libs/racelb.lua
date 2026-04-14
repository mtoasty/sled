local ReplicatedStorage : ReplicatedStorage = game:GetService("ReplicatedStorage");
local formatTable = require(ReplicatedStorage.Modules.sledutils).formatTable;

local racelb = {
    ["help"] = function(self : table) : nil
        self:log("fetch [raceID]                => fetches leaderboard data for the given raceID with full player infos (admin)", false, Color3.fromRGB(100, 250, 255));
        self:log("fetchraw [raceID]             => fetches raw ds leaderboard data for the given raceID (admin)", false, Color3.fromRGB(100, 250, 255));
        self:log("cooldown [raceID]             => gets the time (in seconds) since the last datastore fetch for the given raceID", false, Color3.fromRGB(100, 250, 255));
        self:log("set [raceID] [userId] [score] => sets the leaderboard score for the given user (admin)", false, Color3.fromRGB(100, 250, 255));
    end,

    ["fetch"] = function(self : table, raceID : string) : nil
        local result : boolean, data : (table | string) = script.Gateway:InvokeServer("fetch", raceID);
        if result then
            local stringified = formatTable(data, 2, false);
            for line in stringified:gmatch("(.-)\n") do
                self:log(line);
            end
            self:log("}");
        else
            self:err(data);
        end
    end,

    ["fetchraw"] = function(self : table, raceID : string) : nil
        local result : boolean, data : (table | string) = script.Gateway:InvokeServer("fetchraw", raceID);
        if result then
            self:log(formatTable(data, 2, false));
        else
            self:err(data);
        end
    end,

    ["cooldown"] = function(self : table, raceID : string) : nil
        local result : boolean, data : string = script.Gateway:InvokeServer("cooldown", raceID);
        if result then
            self:log(data);
        else
            self:err(data);
        end
    end,

    ["set"] = function(self : table, raceID : string, userId : string, score : string) : nil
        local result : boolean, data : (string | nil) = script.Gateway:InvokeServer("set", raceID, userId, score);
        if result then
            self:log("Set leaderboard score");
        else
            self:err(data);
        end
    end
};

return racelb;