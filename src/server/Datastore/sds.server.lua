--[[
sds (sled data store)

? Could be used to see request budget
for _, enumItem in pairs(Enum.DataStoreRequestType:GetEnumItems()) do
	print(enumItem.Name, DataStoreService:GetRequestBudgetForRequestType(enumItem))
end

? Maybe implement session locking in the future

TODO: Implement autosave every few minutes, but only if data has changed
TODO: Using version history to recover data from a few saves ago if needed
]]

local Players : Players = game:GetService("Players");
local DataStoreService : DataStoreService = game:GetService("DataStoreService");
local ReplicatedStorage : ReplicatedStorage = game:GetService("ReplicatedStorage");
local RunService : RunService = game:GetService("RunService");
local sds : DataStore = DataStoreService:GetDataStore("sledsave");

local DataPackage = require(script.Parent.DataPackage);
local serverSessionCache : {Folder} = {};
local autosaveHistory : {number} = {};

local serverShuttingDown : boolean = false;
local leavingSavingPlayers : {number} = {};

--| Event used to signal finish
local finishedEvent : BindableEvent = Instance.new("BindableEvent");

function onPlayerAdded(player : Player | number) : nil
    --| Obtain player data

    local data = getWithRetries(player.UserId, 5);

    if (data) then
        if (data.onLoadNotification ~= nil) then

            --| Create a new folder from JSON data
            local playerDataPackage = DataPackage.new(data);
            playerDataPackage:Restore();
            print("Packaged data:");
            print(playerDataPackage);
            local playerDataFolder : Folder = playerDataPackage:ToInstTree();
            playerDataFolder.Name = "Data";
            playerDataFolder.Parent = player;
            
            --| Add to cache
            serverSessionCache[player.UserId] = playerDataFolder;

        else
            print("transferring data");
            --| Transfer existing data
            local playerDataPackage = DataPackage.new();

            --| Core stats
            playerDataPackage.playerstats.level = data.sledstats.Level;
            playerDataPackage.playerstats.xp = data.sledstats.xp;

            --| Sled type and unlocked moon sleds
            playerDataPackage.sledConfig.sledType = data.sledstats.SledType;
            playerDataPackage.sledConfig.cosmetics.Currents = data.sledstats.Currents;
            playerDataPackage.sledConfig.cosmetics.SantasSleigh = data.sledstats.santasSleigh;

            --| Race times not transferred due to sled chassis rework

            --| Moons
            local moonIndices : {string} = {};
            for index : string in pairs(data.sledstats.MoonCollection) do
                table.insert(moonIndices, index);
            end

            table.sort(moonIndices, function(a : string, b : string) : boolean
                return tonumber(a) < tonumber(b);
            end);

            for index : string in pairs(moonIndices) do
                local value : string = data.sledstats.MoonCollection[index];
                local boolValue : boolean;
                if (value == "0" or value == nil) then
                    boolValue = false;
                elseif (value == "1") then
                    boolValue = true;
                end

                table.insert(playerDataPackage.moons, boolValue);
            end

            playerDataPackage:Restore();
            print("Packaged data:");
            print(playerDataPackage);

            local playerDataFolder = playerDataPackage:ToInstTree();
            playerDataFolder.Name = "Data";
            playerDataFolder.Parent = player;

            --| Add to cache
            serverSessionCache[player.UserId] = playerDataFolder;
        end
    else
        local playerDataPackage = DataPackage.new();
        playerDataPackage:Restore();
        print("Packaged data:");
        print(playerDataPackage);
        local playerDataFolder : Folder = playerDataPackage:ToInstTree();
        playerDataFolder.Name = "Data";
        playerDataFolder.Parent = player;
        
        --| Add to cache
        serverSessionCache[player.UserId] = playerDataFolder;
    end

    ReplicatedStorage.RemoteEvents.DataLoaded:FireClient(player, "DataLoaded");
end

function onPlayerRemoving(player : Player) : nil
    if (serverShuttingDown) then return; end

    --| Save player data
    local playerDataPackage  = DataPackage.fromInstTree(player.Data);
    local tabledData = playerDataPackage:ToTable();

    saveWithRetries(player.UserId, tabledData, 10);
end


function getWithRetries(userId : number, tries : number) : table

    --| Try saving x times
    while (tries > 0) do
        local success : boolean, result : table = pcall(function() : table
            return sds:GetAsync(userId);
        end);
        if (not success) then
            warn("Error: Failed to get " .. userId .. "'s data, retrying.");
        else
            print("Successfully got " .. userId .. "'s data. Acquired data: ");
            print(result);
            return result;
        end

        task.wait(7);
        tries -= 1;
    end
end

function saveWithRetries(userId : number, data : table, tries) : nil

    --| Try saving x times
    while (tries > 0) do
        local success : boolean, result : table = pcall(savePlayerDataAsync, userId, data);
        if (not success) then
            warn("Error: Failed to save " .. userId .. "'s data, retrying. Data to save: ");
            print(data);
            warn(result);
        else
            print("Successfully saved " .. userId .. "'s data. Saved data: ");
            print(data);

            table.remove(serverSessionCache, userId);
            return;
        end

        task.wait(7);
        tries -= 1;
    end
end

-- ! PCALL THIS FUNCTION
function savePlayerDataAsync(userId : number, data : table) : nil
    --| Save data
    print("Trying to save " .. userId .. "s data ");
    sds:UpdateAsync(userId, function(oldData : table) : table
        -- * Could optimize this with more efficient callback?
        return data;
    end);
end

function onServerShutdown(closeReason : Enum.CloseReason) : nil
    --if (RunService:IsStudio()) then return; end
    --if (closeReason == Enum.CloseReason.ServerEmpty) then return; end
    print("Server shutting down. Reason: " .. tostring(closeReason));
    serverShuttingDown = true;

    --| Counts thread and resumes main thread once completed all running threads
    local numThreadsRunning : number = 0;

    local function startSaveThread(userId : number, data : table) : nil
        numThreadsRunning += 1;
        task.spawn(function()
            --| Save data
            local tabledData = DataPackage.fromInstTree(data):ToTable();
            saveWithRetries(userId, tabledData, 3);
        
            numThreadsRunning -= 1;
            print("Task complete, tasks remaining " .. numThreadsRunning);

            if (numThreadsRunning == 0) then
                finishedEvent:Fire();
            end
        end);

    end;

    --| Run a save thread for each user in the data cache
    for userId : number, data : table in pairs(serverSessionCache) do
        startSaveThread(userId, data);
    end

    if (numThreadsRunning == 0) then
        finishedEvent:Fire();
    end

    --| Yield shutdown if there is data to save
    finishedEvent.Event:Wait();
    print("DONE");
end

Players.PlayerAdded:Connect(onPlayerAdded);
Players.PlayerRemoving:Connect(onPlayerRemoving);
game:BindToClose(onServerShutdown);



------| Terminal functionality |------



function findPlayerInServer(userId : number) : Player
    for _, player : Player in pairs(Players:GetPlayers()) do
        if (player.UserId == userId) then
            return player;
        end
    end
end

--| Terminal access to sds
ReplicatedStorage:WaitForChild("Modules").terminal.libs["sds"].Gateway.OnServerInvoke = function(player : Player, requestType : string, ...) : (boolean, any)

    local query : table = {...};

    --| Acquiring data --- query[1] = player
    if (requestType == "get") then

        if (player:GetRankInGroup(13628961) >= 254) then
            
            --| Check if player is in server to reference their instance tree
            local playerInServer = findPlayerInServer(query[1]);
            if (playerInServer) then
                return true, DataPackage.fromInstTree(playerInServer.Data);
            end

            --| If player not in server use datastore request
            local data = sds:GetAsync(query[1]);
            return true, DataPackage.new(data);
        else
            return false, "You do not have the permissions to do this action";
        end

    --| Mutating data --- query[1] = player, query[2] = data to change (name in server, path for ds) , query[3] = new value, query[4] = datatype (needed for out of server updating)
    elseif (requestType == "set") then

        if (player:GetRankInGroup(13628961) >= 254) then

            local instTree : Folder;

            local playerInServer = findPlayerInServer(query[1]);
            if (playerInServer) then

                --| Find target value by directly editing instance tree
                instTree = playerInServer.Data;
                
            else

                --| Write directly to their ds data, by creating an instance tree and updating
                local data = DataPackage.new(sds:GetAsync(query[1]));

                instTree = data:ToInstTree();
                
            end

            --| Instance tree writing process:
            local success : boolean, err : any = pcall(function()

                for _, d : Instance in pairs(instTree:GetDescendants()) do
                    if (d.Name == query[2]) then
                        
                        if (d:IsA("NumberValue")) then

                            d.Value = tonumber(query[3]);

                        elseif (d:IsA("BoolValue")) then

                            if (query[3] == "true") then
                                d.Value = true;
                            elseif (query[3] == "false") then
                                d.Value = false;
                            else
                                error("Tried to set boolean value, got " .. query[3]);
                            end

                        elseif (d:IsA("Color3Value")) then

                            if (string.sub(query[3], 1, 5) == "\\crgb") then
                                local cutString : string = string.sub(query[3], 6, #query[3])
                                local split : {string} = string.split(cutString, ",");
                                d.Value = Color3.new(split[1], split[2], split[3]);
                                continue;
                            else
                                error("Incorrect format for colour value, use \\crgb[r], [g], [b]");
                            end

                        else
                            d.value = query[3];
                        end

                    end
                end

                if (playerInServer == nil) then
                    sds:SetAsync(query[1], DataPackage.fromInstTree(instTree));
                end
            end);


            if (success) then
 
                return true, "Set " .. query[2] .. " to " .. query[3];
            else
                return false, err;
            end
        else
            return false, "You do not have the permissions to do this action";
        end

    --| Restoring data (within this server, can be called by anyone)
    elseif (requestType == "restore") then
        local data : table;
        --| Restore own data
        if (query[1] == player.UserId) then
            data = DataPackage.fromInstTree(player.Data);
        else
            if (player:GetRankInGroup(13628961) >= 254) then
                local playerInServer = findPlayerInServer(query[1]);
                if (playerInServer) then
                    data = playerInServer.Data;
                else
                    local success : boolean, err : any = pcall(function()
                        data = DataPackage.new(sds:GetAsync(query[1]));
                    end);

                    if (not success) then
                        return false, err;
                    end
                end
            end
        end

        local success, err = pcall(function()
            data:Restore();
        end);

        if (success) then
            return true, "Data restored successfully";
        else
            return false, err;
        end
    end
end