--[[

dawn/dusk:
atmos colour 255, 0, 0
brightness 1
colour shift top 214, 124, 124
outdoor ambient 169, 151, 191
tint 233, 225, 255
clouds 103, 87, 107


noon:
atmos colour 255, 255, 255
brightness 2
colour shift top 179, 199, 214
outdoor ambient 184, 203, 220
tint 255, 255, 255
clouds 255, 255, 255

midnight:
atmos colour 17, 18, 25
brightness 0
colour shift top ---
outdoor ambient 40, 43, 56
tint 255, 255, 255
clouds 94, 94, 94

]]
local ReplicatedStorage : ReplicatedStorage = game:GetService("ReplicatedStorage");

local Lighting : Lighting = game:GetService("Lighting");
local Clouds : Clouds = workspace.Terrain.Clouds;

local timeSpeed = 1;
local locked = false;

local atmosColourSequence = ColorSequence.new{
    ColorSequenceKeypoint.new(0,    Color3.fromRGB(17, 18, 25)),
    ColorSequenceKeypoint.new(0.245,    Color3.fromRGB(17, 18, 25)),
    ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 106, 0)),
    ColorSequenceKeypoint.new(0.325, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(0.5,  Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(0.675,  Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(0.75, Color3.fromRGB(255, 106, 0)),
    ColorSequenceKeypoint.new(0.755,    Color3.fromRGB(17, 18, 25)),
    ColorSequenceKeypoint.new(1,    Color3.fromRGB(17, 18, 25)),
};

local clrShiftTopSequence = ColorSequence.new{
    ColorSequenceKeypoint.new(0,    Color3.fromRGB(17, 18, 25)),
    ColorSequenceKeypoint.new(0.245,    Color3.fromRGB(17, 18, 25)),
    ColorSequenceKeypoint.new(0.25, Color3.fromRGB(214, 124, 124)),
    ColorSequenceKeypoint.new(0.325, Color3.fromRGB(214, 124, 124)),
    ColorSequenceKeypoint.new(0.5,  Color3.fromRGB(179, 199, 214)),
    ColorSequenceKeypoint.new(0.675,  Color3.fromRGB(179, 199, 214)),
    ColorSequenceKeypoint.new(0.75, Color3.fromRGB(214, 124, 124)),
    ColorSequenceKeypoint.new(0.755,    Color3.fromRGB(17, 18, 25)),
    ColorSequenceKeypoint.new(1,    Color3.fromRGB(17, 18, 25)),
};

local outdoorAmbientSequence = ColorSequence.new{
    ColorSequenceKeypoint.new(0,    Color3.fromRGB(40, 43, 56)),
    ColorSequenceKeypoint.new(0.245,    Color3.fromRGB(40, 43, 56)),
    ColorSequenceKeypoint.new(0.25, Color3.fromRGB(169, 151, 191)),
    ColorSequenceKeypoint.new(0.325, Color3.fromRGB(169, 151, 191)),
    ColorSequenceKeypoint.new(0.5,  Color3.fromRGB(184, 203, 220)),
    ColorSequenceKeypoint.new(0.675,  Color3.fromRGB(184, 203, 220)),
    ColorSequenceKeypoint.new(0.75, Color3.fromRGB(169, 151, 191)),
    ColorSequenceKeypoint.new(0.755,    Color3.fromRGB(40, 43, 56)),
    ColorSequenceKeypoint.new(1,    Color3.fromRGB(40, 43, 56)),
};

local tintSequence = ColorSequence.new{
    ColorSequenceKeypoint.new(0,    Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(0.245,    Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(0.25, Color3.fromRGB(233, 225, 255)),
    ColorSequenceKeypoint.new(0.325, Color3.fromRGB(233, 225, 255)),
    ColorSequenceKeypoint.new(0.5,  Color3.fromRGB(237, 247, 255)),
    ColorSequenceKeypoint.new(0.675,  Color3.fromRGB(237, 247, 255)),
    ColorSequenceKeypoint.new(0.75, Color3.fromRGB(233, 225, 255)),
    ColorSequenceKeypoint.new(0.755,    Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(1,    Color3.fromRGB(255, 255, 255)),
};

local cloudColourSequence = ColorSequence.new{
    ColorSequenceKeypoint.new(0,    Color3.fromRGB(94, 94, 94)),
    ColorSequenceKeypoint.new(0.25, Color3.fromRGB(103, 87, 107)),
    ColorSequenceKeypoint.new(0.5,  Color3.fromRGB(237, 247, 255)),
    ColorSequenceKeypoint.new(0.75, Color3.fromRGB(103, 87, 107)),
    ColorSequenceKeypoint.new(1,    Color3.fromRGB(94, 94, 94)),
};

--| Get colour at position in the colour sequence
local function evalColorSequence(sequence : ColorSequence, timeInterval : number)
    -- If time is 0 or 1, return the first or last value respectively
    if (timeInterval == 0) then
        return sequence.Keypoints[1].Value;
    elseif (timeInterval == 1) then
        return sequence.Keypoints[#sequence.Keypoints].Value
    end

    -- Otherwise, step through each sequential pair of keypoints
    for i : number = 1, #sequence.Keypoints - 1 do
        local thisKeypoint : ColorSequenceKeypoint = sequence.Keypoints[i];
        local nextKeypoint : ColorSequenceKeypoint = sequence.Keypoints[i + 1];
        if (timeInterval >= thisKeypoint.Time and timeInterval < nextKeypoint.Time) then
            -- Calculate how far alpha lies between the points
            local alpha : number = (timeInterval - thisKeypoint.Time) / (nextKeypoint.Time - thisKeypoint.Time);
            -- Evaluate the real value between the points using alpha
            return Color3.new(
                (nextKeypoint.Value.R - thisKeypoint.Value.R) * alpha + thisKeypoint.Value.R,
                (nextKeypoint.Value.G - thisKeypoint.Value.G) * alpha + thisKeypoint.Value.G,
                (nextKeypoint.Value.B - thisKeypoint.Value.B) * alpha + thisKeypoint.Value.B
            );
        end
    end
end


--| Function to get colours and values for lighting and atmosphere
function calculateLighting(minutesAfterMidnight : number) : table
    local hour : number = minutesAfterMidnight / 60;
    local timeInterval : number = minutesAfterMidnight / 1440;
    return {
        ["clrShiftTop"] = evalColorSequence(clrShiftTopSequence, timeInterval),
        ["brightness"] = 1 - math.cos(math.pi / 12 * hour),
        ["outdoorAmbient"] = evalColorSequence(outdoorAmbientSequence, timeInterval),

        ["tint"] = evalColorSequence(tintSequence, timeInterval),

        ["atmosColour"] = evalColorSequence(atmosColourSequence, timeInterval),
        ["atmosDensity"] = 0.256,

        ["cloudCover"] = 0.494,
        ["cloudDensity"] = 0.512
    };
end


--| Time incrementing
local minutesAfterMidnight : number = 720;

function tickTime() : nil
    --| Change time by one second
    minutesAfterMidnight = Lighting:GetMinutesAfterMidnight() + timeSpeed / 10;
    if (minutesAfterMidnight > 1440) then
        minutesAfterMidnight -= 1440;
    end
    Lighting:SetMinutesAfterMidnight(minutesAfterMidnight);

    task.wait(0.1);
end



function updateDayOnTick() : nil
    tickTime();
    local lightingData = calculateLighting(minutesAfterMidnight);

    Lighting.ColorShift_Top = lightingData.clrShiftTop;
    Lighting.Brightness = lightingData.brightness;
    Lighting.OutdoorAmbient = lightingData.outdoorAmbient;

    Lighting.ColorCorrection.TintColor = lightingData.tint;

    Lighting.Atmosphere.Color = lightingData.atmosColour;
    Lighting.Atmosphere.Density = lightingData.atmosDensity;

    Clouds.Cover = lightingData.cloudCover;
    Clouds.Density = lightingData.cloudDensity;
end


--| Global day cycle

function globalDayCycle() : nil
    while (true) do
        if (locked) then
            coroutine.yield();
        end
        updateDayOnTick();
    end
end

local dayCycleCoroutine : typeof(coroutine) = coroutine.create(globalDayCycle);
coroutine.resume(dayCycleCoroutine);


ReplicatedStorage:WaitForChild("Modules").terminal.libs["time"].Gateway.OnServerInvoke = function(player : Player, command : string, ...) : (boolean , string)

    local args : table = {...};

    if (command == "get") then

        return true, "Minutes after midnight: " .. tostring(minutesAfterMidnight) .. ", Hour: " .. tostring(minutesAfterMidnight / 60) .. ", Time speed: " .. tostring(timeSpeed) .. ", Time locked: " .. tostring(locked);

    elseif (command == "lock") then

        if (player:GetRankInGroup(13628961) >= 254) then

            if (locked == false) then
                locked = true;
            else
                locked = false;
                coroutine.resume(dayCycleCoroutine);
            end

            return true, "Timelock status: " .. tostring(locked);
        else
            return false, "You do not have the permissions to do this action";
        end

    elseif (command == "speed") then

        if (player:GetRankInGroup(13628961) >= 254) then
            timeSpeed = args[1];
            return true, "Time speed set to : " .. tostring(timeSpeed);
        else
            return false, "You do not have the permissions to do this action";
        end
    
    elseif (command == "set") then

        if (player:GetRankInGroup(13628961) >= 254) then
            local newTime : number = args[1]; --| Time passed in hours [0-24)

            Lighting:SetMinutesAfterMidnight(newTime * 60);
            minutesAfterMidnight = newTime;
            updateDayOnTick();
            return true, "Time set to : " .. newTime .. " hours";
        else
            return false, "You do not have the permissions to do this action";
        end

    end
end