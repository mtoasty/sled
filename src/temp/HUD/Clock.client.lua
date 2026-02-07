local dayImage : string = "rbxassetid://6034412758";
local nightImage : string = "rbxassetid://6031572317";
local twilightImage : string = "rbxassetid://6034412760";

local Lighting : Lighting = game:GetService("Lighting");

local timeIcon  = script.Parent:WaitForChild("Icon");
local timeText = script.Parent:WaitForChild("Time");

function updateClock()
    local currentTime = Lighting.ClockTime;

    if (currentTime >= 6 and currentTime < 18) then
        timeIcon.Image = dayImage;
    elseif ((currentTime >= 17 and currentTime < 19) or (currentTime >= 5 and currentTime < 7)) then
        timeIcon.Image = twilightImage;
    else
        timeIcon.Image = nightImage;
    end

    --| Format time into hh:mm (24 hour format)
    local hours = math.floor(currentTime);
    local minutes = math.floor((currentTime - hours) * 60);
    local timeString = string.format("%02d:%02d", hours, minutes);
    timeText.Text = timeString;
end

while (true) do
    updateClock();
    task.wait(2);
end