local ReplicatedStorage : ReplicatedStorage = game:GetService("ReplicatedStorage");

local timeLib = {
    ["help"] = function(self : table) : nil
        self:log("get                => gets the current time information", false, Color3.fromRGB(100, 250, 255));
        self:log("lock               => starts/stops the daylight cycle (admin)", false, Color3.fromRGB(100, 250, 255));
        self:log("speed [timeSpeed]  => sets the speed of the daylight cycle (admin)", false, Color3.fromRGB(100, 250, 255));
        self:log("set [timeHour]     => sets the time to the specified hour (admin)", false, Color3.fromRGB(100, 250, 255));
    end,

    ["get"] = function(self : table) : nil
        local success : boolean, message : string = script.Gateway:InvokeServer("get");
        if (success) then
            self:log(message, true);
        else
            self:err(message, true);
        end
    end,

    ["lock"] = function(self : table) : nil
        local success : boolean, message : string = script.Gateway:InvokeServer("lock");
        if (success) then
            self:log(message, true);
        else
            self:err(message, true);
        end
    end,

    ["speed"] = function(self : table, timeSpeed : string) : nil
        local speedValue : number = tonumber(timeSpeed);
        if (speedValue == nil) then
            self:err("Invalid speed value");
            return;
        end

        if (speedValue == 0) then
            self:err("Speed value cannot be 0, use 'lock' command instead");
            return;
        end

        if (speedValue < 1 or speedValue > 10) then
            self:err("Speed value must be between 1 and 100");
            return;
        end

        local success : boolean, message : string = script.Gateway:InvokeServer("speed", speedValue);
        if (success) then
            self:log(message, true);
        else
            self:err(message, true);
        end
    end,

    ["set"] = function(self : table, timeHour : string) : nil
        local hourValue : number = tonumber(timeHour);
        if (hourValue == nil) then
            self:err("Invalid hour value");
            return;
        end

        if (hourValue < 0 or hourValue >= 24) then
            self:err("Hour value must be between 0 and 24 (inclusive, exclusive)");
            return;
        end

        local success : boolean, message : string = script.Gateway:InvokeServer("set", hourValue);
        if (success) then
            self:log(message, true);
        else
            self:err(message, true);
        end
    end
};

return timeLib;