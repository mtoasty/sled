local ReplicatedStorage : ReplicatedStorage = game:GetService("ReplicatedStorage");
local ServerStorage : ServerStorage = game:GetService("ServerStorage");
local DataStoreService : DataStoreService = game:GetService("DataStoreService");
local Players : Players = game:GetService("Players");
local UserService : UserService = game:GetService("UserService");

local TimeTrialInfos : table = require(ReplicatedStorage:WaitForChild("Modules").Race.TimeTrialInfos);
local isDeveloper = require(ReplicatedStorage.Modules.sledutils).isDeveloper;

local fetchCooldown : number = 60;
local emptyPlayerIcon : string = "rbxassetid://6034268008";

local fetchTimes : {number} = {};
local datastores : {OrderedDataStore} = {};
local cachedData : {DataStorePages} = {};

for key : string, _ in pairs(TimeTrialInfos) do
    fetchTimes[key] = time() - fetchCooldown;
    datastores[key] = DataStoreService:GetOrderedDataStore("sledrace_" .. key);
end


--[[

* DS Fetching

]]--


local function packageLbData(lbData : {table}) : table
    local packagedData : {table} = {};

    local userIds : {number} = {};

    for i : number, lbEntry : table in ipairs(lbData) do
        table.insert(userIds, tonumber(lbEntry.key));
    end

    local userInfos : {table} = UserService:GetUserInfosByUserIdsAsync(userIds);
    
    repeat task.wait() until userInfos

    for i : number, lbEntry : table in ipairs(lbData) do
        local userInfo;

        for k : number, v : table in pairs(userInfos) do
            if v.Id == tonumber(lbEntry.key) then
                userInfo = v;
                break;
            end
        end

        local userId : number = -1;
        local username : string = "";
        local displayName : string = "";
        local thumbnail = emptyPlayerIcon;

        if userInfo then
            userId = userInfo.Id;
            username = userInfo.Username;
            displayName = userInfo.DisplayName

            local t, isReady = Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100);

            if not isReady then
                thumbnail = emptyPlayerIcon;
            else
                thumbnail = t;
            end

            thumbnail = t;
        end

        table.insert(packagedData, {
            ["userId"] = userId,
            ["username"] = username,
            ["displayName"] = displayName,
            ["score"] = (lbEntry.value) / 1000,
            ["thumbnail"] = thumbnail
        });
    end

    return packagedData;
end


local function invoked(raceID : string, raw : boolean?) : table
    local timeSinceLastFetch : number = time() - fetchTimes[raceID];
    if (timeSinceLastFetch >= fetchCooldown) then
        fetchTimes[raceID] = time();
        
        local isAscending : boolean = false;
        local pageSize : number = 10;
        
        cachedData[raceID] = datastores[raceID]:GetSortedAsync(isAscending, pageSize):GetCurrentPage();
    end

    if raw then
        return cachedData[raceID];
    end
    
    return packageLbData(cachedData[raceID]);
end

ServerStorage.ServerEvents.LeaderboardFetch.OnInvoke = invoked;


local function getFetchCooldown(raceID : string) : number
    return time() - fetchTimes[raceID];
end

--[[

* DS Setting

]]--

local function setLbAsync(raceID : string, userId : number, score : number) : nil
    local success : boolean, err : any = pcall(function(): nil
        datastores[raceID]:SetAsync(userId, math.floor(score * 1000));
    end);

    if not success then
        warn("Error trying to update leaderboard : ".. err);
    end
end

ServerStorage.ServerEvents.Leaderboard.Event:Connect(setLbAsync);





ReplicatedStorage.Modules.terminal.libs.racelb.Gateway.OnServerInvoke = function(player : Player, requestType: string, ...) : (boolean, any)
    local query : any = {...};

    if requestType == "fetch" then
        if isDeveloper(player) then
            return true, invoked(query[1], false);
        else
            return false, "You do not have the permissions to do this action";
        end
    elseif requestType == "fetchraw" then
        if isDeveloper(player) then
            return invoked(query[1], true);
        else
            return false, "You do not have the permissions to do this action";
        end
    elseif requestType == "cooldown" then
        return true, "Time since last datastore fetch: " .. tostring(math.round(getFetchCooldown(query[1]))) .. " seconds";
    elseif requestType == "set" then
        if isDeveloper(player) then
            if TimeTrialInfos[query[1]] then
                if tonumber(query[2]) ~= nil then
                    if tonumber(query[3]) ~= nil then
                        return true, setLbAsync(query[1], tonumber(query[2]), tonumber(query[3]));
                    else
                        return "score must be a number";
                    end
                else
                    return false, "userid must be a number";
                end
            else
                return false, "Invalid raceID"
            end
        else
            return false, "You do not have the permissions to do this action";
        end
    end
end