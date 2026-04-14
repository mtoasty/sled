local Players : Players = game:GetService("Players");
local ReplicatedStorage : ReplicatedStorage = game:GetService("ReplicatedStorage");

local formatTable = require(ReplicatedStorage.Modules.sledutils).formatTable;

function findUserIdFromStringAsync(user : string) : (boolean, number)
    if (user == "&s") then
        return true, Players.LocalPlayer.UserId;
    end

    local userId : number;

    --| Find user id if username provided
    if (tonumber(user) == nil) then
        --| Search the current lobby to avoid ds requests
        for _, player : Player in pairs(Players:GetPlayers()) do
            if (player.Name == user) then
                userId = player.UserId;
                break;
            end
        end

        --| If not found, find user id and do ds call
        if (userId == nil) then
            local success : boolean, err : any = pcall(function()
                userId = Players:GetUserIdFromNameAsync(user);
            end);

            if (not success) then
                return false, userId;
            end
        end
    else
        --| Keep user id if that is what's passed
        userId = user;
    end

    --| Call server to get data, if caller has permission

    local success : boolean = pcall(function()
        return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48);
    end);

    return success, userId
end


local sds = {
    ["help"] = function(self : table) : nil
        self:log("get [username]               => gets the data tree of the passed user (admin)", false, Color3.fromRGB(100, 250, 255));
        self:log("set [username] [key] [value] => sets the data key of the passed user to [value] (admin)", false, Color3.fromRGB(100, 250, 255));
        self:log("restore [username]           => restores the structure of user data (admin*)", false, Color3.fromRGB(100, 250, 255));
    end,

    ["get"] = function(self : table, user : string) : nil
        --| Assert arguments
        if (user == nil) then
            self:err("No user provided");
        end

        local success : boolean, userId : number = findUserIdFromStringAsync(user);

        if (success) then
            local result : boolean, data : table = script.Gateway:InvokeServer("get", userId);
            if (result == true) then
                local stringified = formatTable(data, 2, false)
                for line in stringified:gmatch("(.-)\n") do
                    self:log(line);
                end
                self:log("}");
            else
                self:err(data);
            end
        else
            self:err("User not found");
        end
    end,

    ["set"] = function(self : table, user : string, key : string, value : string) : nil
        print(user, key, value);
        --| Assert arguments
        if (user == nil) then
            self:err("No user provided");
        end
        if (key == nil) then
            self:err("No key provided");
        end
        if (value == nil) then
            self:err("No value provided to set to");
        end

        local success : boolean, userId : number = findUserIdFromStringAsync(user);

        if (success) then
            local result : boolean, message : string = script.Gateway:InvokeServer("set", userId, key, value);
            if (result == true) then
                self:log(message);
            else
                self:err(message);
            end
        else
            self:err("User not found");
        end
    end,

    ["restore"] = function(self : table, user : string) : nil
        --| Assert arguments
        if (user == nil) then
            self:err("No user provided");
        end

        local success : boolean, userId : number = findUserIdFromStringAsync(user);

        if (success) then
            local result : boolean, message : string = script.Gateway:InvokeServer("restore", userId);
            if (result == true) then
                self:log(message);
            else
                self:err(message);
            end
        else
            self:err("User not found");
        end
    end
};

return sds;