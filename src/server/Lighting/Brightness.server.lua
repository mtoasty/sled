game.Lighting.ClockTime = 12;
game.Lighting.ColorCorrection.Brightness = 0;

local clockTime = game.Lighting;
local cc = game.Lighting.ColorCorrection;

local tweenservice = game:GetService("TweenService");

local tweeninfo = TweenInfo.new(150 / script.Parent.TimeSpeed.Value);

local fadeout = tweenservice:Create(cc, tweeninfo, {["Brightness"] = -0.05});
local fadein = tweenservice:Create(cc, tweeninfo, {["Brightness"] = 0});

while true do 
	repeat task.wait() until clockTime.ClockTime > 17.4;
	fadeout:Play();
	repeat task.wait() until clockTime.ClockTime > 5.9;
	fadein:Play();
end
