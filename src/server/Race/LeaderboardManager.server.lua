local ReplicatedStorage : ReplicatedStorage = game:GetService("ReplicatedStorage");
local ServerStorage : ServerStorage = game:GetService("ServerStorage");
local DataStoreService : DataStoreService = game:GetService("DataStoreService");
local Players : Players = game:GetService("Players");
local UserService : UserService = game:GetService("UserService");

local TimeTrialInfos : table = require(ReplicatedStorage:WaitForChild("Modules").Race.TimeTrialInfos);

local fetchCooldown : number = 60;
local emptyPlayerIcon : string = "rbxassetid://6034268008";

local fetchTimes : {number} = {};
local datastores : {OrderedDataStore} = {};

for key : string, _ in pairs(TimeTrialInfos) do
    fetchTimes[key] = time() - fetchCooldown;
    datastores[key] = DataStoreService:GetOrderedDataStore("sledrace_" .. key);
end


local function packageLbData(lbData : {table}) : table
    local packagedData : {table} = {};

    local userIds : {number} = {};

    for i : number, lbEntry : table in ipairs(lbData) do
        table.insert(userIds, lbEntry.key);
    end

    local userInfos : {table} = UserService:GetUserInfosByUserIdsAsync(userIds);

    for i : number, lbEntry : table in ipairs(lbData) do
        local userInfo : table = table.find(userInfos, function(info : table) : boolean
            return info.Id == lbEntry.key;
        end);

        local userId : number = userInfo and userInfo.Id or nil;
        local username : string = userInfo and userInfo.Username or "";
        local displayName : string = userInfo and userInfo.DisplayName or "";

        local thumbnail, isReady : string, boolean = Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100);
        
        if not isReady then
            thumbnail = emptyPlayerIcon;
        end

        table.insert(packagedData, {
            ["userId"] = userId,
            ["username"] = username,
            ["displayName"] = displayName,
            ["score"] = lbEntry.value,
            ["thumbnail"] = thumbnail
        });
    end

    return packagedData;
end


local function invoked(raceID : string) : table
    local timeSinceLastFetch : number = time() - fetchTimes[raceID];
    if (timeSinceLastFetch >= fetchCooldown) then
        fetchTimes[raceID] = time();

        local isAscending : boolean = false;
        local pageSize : number = 10;

        datastores[raceID] = datastores[raceID]:GetSortedAsync(isAscending, pageSize):GetCurrentPage();
    end

    return packageLbData(datastores[raceID]);
end

ServerStorage.ServerEvents.LeaderboardFetch.OnInvoke = invoked;