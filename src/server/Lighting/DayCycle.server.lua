local ReplicatedStorage : ReplicatedStorage = game:GetService("ReplicatedStorage");

local locked = false;
local timeSpeed = 1;

local mam; --| Minutes after midnight
local waitTime = 1/10; --| Legnth of the tick
local pi = math.pi;

--| Brightness:
local amplitudeB = 0.5;
local offsetB = 2;

--| Outdoor ambieant:
local var
local amplitudeO = 20;
local offsetO = 100;

--| Shadow softness:
local amplitudeS = 0.2;
local offsetS = 0.8;

--| Color shift top:
local pointer;

local colorShiftColorList = {
    Color3.fromRGB(0,   40,  62 ), --| 0
    Color3.fromRGB(0,   80,  123), --| 1
    Color3.fromRGB(0,   91,  140), --| 2
    Color3.fromRGB(0,   165, 255), --| 3
    Color3.fromRGB(0,   165, 255), --| 4
    Color3.fromRGB(125, 165, 255), --| 5
    Color3.fromRGB(255, 190, 175), --| 6
    Color3.fromRGB(255, 215, 110), --| 7
    Color3.fromRGB(255, 245, 215), --| 8
    Color3.fromRGB(255, 255, 255), --| 9
    Color3.fromRGB(255, 255, 255), --| 10
    Color3.fromRGB(255, 255, 255), --| 11
    Color3.fromRGB(255, 255, 255), --| 12
    Color3.fromRGB(255, 255, 255), --| 13
    Color3.fromRGB(255, 255, 255), --| 14
    Color3.fromRGB(255, 255, 255), --| 15
    Color3.fromRGB(255, 245, 215), --| 16
    Color3.fromRGB(255, 215, 110), --| 17
    Color3.fromRGB(255, 190, 175), --| 18
    Color3.fromRGB(125, 165, 255), --| 19
    Color3.fromRGB(0,   165, 255), --| 20
    Color3.fromRGB(0,   165, 255), --| 21
    Color3.fromRGB(0,   91,  140), --| 22
    Color3.fromRGB(0,   80,  123)  --| 23
};


local black : Color3 = Color3.fromRGB(0, 0, 0);
local white : Color3 = Color3.fromRGB(255, 255, 255);

local atmosphere : Atmosphere = game.Lighting:FindFirstChildOfClass("Atmosphere");

local dawnStart : number = 5.5;
local dawnTime : number = 6.0;
local dawnEnd : number = 6.5;
local duskStart : number = 17.5;
local duskTime : number = 18.0
local duskEnd : number = 18.5;

local dawnDuskColor : Color3 = Color3.fromRGB(212, 165, 208);
local dawnDuskDecay : Color3 = Color3.fromRGB(245, 252, 255);

--| Returns a sine-eased value between 0 and 1
function sineInterpolate(intVal : number) : number
    return (math.sin((intVal - 0.5) * pi) + 1) / 2;
end

--| Calculates the color and decay of the atmosphere based on the time of day
function atmosphereTick() : nil
    local localHour : number = mam % 24;

    if (localHour < dawnStart) then --| Time 0 - 5.5

        atmosphere.Color = black;
        atmosphere.Decay = black;

    elseif (localHour < dawnTime) then -- | Time 5.5 - 6.0

        atmosphere.Color = black:Lerp(dawnDuskColor, sineInterpolate((localHour - dawnStart) / (dawnTime - dawnStart)));
        atmosphere.Decay = black:Lerp(dawnDuskDecay, sineInterpolate((localHour - dawnStart) / (dawnTime - dawnStart)));

    elseif (localHour < dawnEnd) then --| Time 6.0 - 6.5

        atmosphere.Color = dawnDuskColor:Lerp(white, sineInterpolate((localHour - dawnTime) / (dawnEnd - dawnTime)));
        atmosphere.Decay = dawnDuskDecay:Lerp(white, sineInterpolate((localHour - dawnTime) / (dawnEnd - dawnTime)));

    elseif (localHour < duskStart) then --| Time 6.5 - 17.5

        atmosphere.Color = white;
        atmosphere.Decay = white;

    elseif (localHour < duskTime) then --| Time 17.5 - 18.0

        atmosphere.Color = white:Lerp(dawnDuskColor, sineInterpolate((localHour - duskStart) / (duskTime - duskStart)));
        atmosphere.Decay = white:Lerp(dawnDuskDecay, sineInterpolate((localHour - duskStart) / (duskTime - duskStart)));

    elseif (localHour < duskEnd) then --| Time 18.0 - 18.5

        atmosphere.Color = dawnDuskColor:Lerp(black, sineInterpolate((localHour - duskTime) / (duskEnd - duskTime)));
        atmosphere.Decay = dawnDuskDecay:Lerp(black, sineInterpolate((localHour - duskTime) / (duskEnd - duskTime)));

    else --| Time 18.5 - 24

        atmosphere.Color = black;
        atmosphere.Decay = black;

    end
end


--| Updates core lighting properties like ambient lighting, brightness, shadow softness and color shift based on the time of day
function timeTick() : nil
    --| Change time:
    mam = game.Lighting:GetMinutesAfterMidnight() + timeSpeed / 10;
    game.Lighting:SetMinutesAfterMidnight(mam);
    mam = mam / 60; --| Converted to hours
    
    --| Brightness:
    game.Lighting.Brightness = amplitudeB * math.cos(mam * (pi/12) + pi) + offsetB;
    
    --| Outdoor ambient:
    var = amplitudeO * math.cos(mam * (pi/12) + pi) + offsetO;
    game.Lighting.OutdoorAmbient = Color3.fromRGB(var, var, var);
    
    --| Shadow softness:
    game.Lighting.ShadowSoftness = amplitudeS * math.cos(mam * (pi/6)) + offsetS;
    
    
    pointer = math.clamp(math.ceil(mam), 1, 24);
    
    --| Color shift top:

    game.Lighting.ColorShift_Top = Color3.fromRGB(
        ((colorShiftColorList[pointer % 24 + 1].R - colorShiftColorList[pointer].R) * (mam - pointer + 1)) + colorShiftColorList[pointer].R,
        ((colorShiftColorList[pointer % 24 + 1].G - colorShiftColorList[pointer].G) * (mam - pointer + 1)) + colorShiftColorList[pointer].G,
        ((colorShiftColorList[pointer % 24 + 1].B - colorShiftColorList[pointer].B) * (mam - pointer + 1)) + colorShiftColorList[pointer].B
    );

    --| Update atmosphere:
    atmosphereTick();
end



ReplicatedStorage.RemoteEvents.terminalApp.OnServerInvoke = function(player : Player, command : string, ...) : (boolean , string);
    local args : table = {...};

    if (command == "get") then

        return true, "Minutes after midnight: " .. tostring(game.Lighting:GetMinutesAfterMidnight()) .. ", Time speed: " .. tostring(timeSpeed) .. ", Time locked: " .. tostring(locked);

    elseif (command == "lock") then

        if (player:GetRankInGroup(13628961) >= 254) then
            locked = not locked;
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
    end
end


while true do
	repeat
        timeTick();
        task.wait(waitTime);
	until locked.Value;
	
	repeat task.wait() until locked.Value == false;
end



