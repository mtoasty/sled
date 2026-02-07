local clockTime = game.Lighting;
local atmosphere = game.Lighting.Atmosphere;
local cloud = game.Workspace.Terrain:WaitForChild("Clouds");
local tweenService = game:GetService("TweenService");

--| Haze goals (night):

local goalHaze = {["Haze"] = 1};
local goalNoHaze = {["Haze"] = 0};

--| All atmosphere tween goals:

local goalsunset = {
	["Color"] = Color3.fromRGB(212, 165, 208),
	["Decay"] = Color3.fromRGB(245, 252, 255) --Color3.fromRGB(212,205,167)
	--Density = 0.33
};

local goaldusk = {
	["Color"] = Color3.fromRGB(0, 0, 0),
	["Decay"] = Color3.fromRGB(0, 0, 0),
	Density = 0.3
};

local goalbluedusk = {
	["Color"] = Color3.fromRGB(13, 16, 18),
	["Decay"] = Color3.fromRGB(4, 4, 5),
	Density = 0.3
};

local goaldawn = {
	["Color"] = Color3.fromRGB(212, 165, 208),
	["Decay"] = Color3.fromRGB(245, 252, 255),
	["Density"] = 0.3
};

local goalclearday = {
	["Color"] = Color3.fromRGB(255, 255, 255),
	["Decay"] = Color3.fromRGB(255, 255, 255),
	["Density"] = 0.3
};

local goalcloudyday = {
	["Color"] = Color3.fromRGB(106, 106, 106),
	["Decay"] = Color3.fromRGB(255, 255, 255),
	["Density"] = 0.45
};

local goalsnowycloudyday = {
	["Color"] = Color3.fromRGB(106, 106, 106),
	["Decay"] = Color3.fromRGB(255, 255, 255),
	["Density"] = 0.55
};

local goalsnowstormday = {
	["Color"] = Color3.fromRGB(106, 106, 106),
	["Decay"] = Color3.fromRGB(255, 255, 255),
	["Density"] = 0.65
};

--| Cloud tween goals:

local lowCloudy = {
	["Cover"] = 0.5,
	["Density"] = 0.35,
	["Color"] = Color3.fromRGB(255, 255, 255)
};

local nightCloudy = {
	["Cover"] = 0.5,
	["Density"] = 0.35,
	["Color"] = Color3.fromRGB(0, 0, 0)
};

local mediumCloudy = {
	["Cover"] = 0.7,
	["Density"] = 0.5,
	["Color"] = Color3.fromRGB(255, 255, 255)
};

local fullCloudy = {
	["Cover"] = 0.975,
	["Density"] = 0.8,
	["Color"] = Color3.fromRGB(182, 182, 182)
};

local info = TweenInfo.new(60/script.Parent.TimeSpeed.Value); -- one hour fade
local info2 = TweenInfo.new(30/script.Parent.TimeSpeed.Value); -- 30 min fade

local hazeTween = tweenService:Create(atmosphere,info2,goalHaze);
local noHazeTween = tweenService:Create(atmosphere,info2,goalNoHaze);

local duskTween = tweenService:Create(atmosphere,info,goaldusk); -- turn to night
local blueduskTween = tweenService:Create(atmosphere,info,goalbluedusk); -- turn to blue night
local dawnTween = tweenService:Create(atmosphere,info,goaldawn); -- turn to sunrise
local sunsetTween = tweenService:Create(atmosphere,info2,goalsunset); -- turn to sunset

local dayTween = tweenService:Create(atmosphere,info,goalclearday); -- turn to day
local cloudyTween = tweenService:Create(atmosphere,info,goalcloudyday);
local snowycloudyTween = tweenService:Create(atmosphere,info,goalsnowycloudyday);
local snowstormTween = tweenService:Create(atmosphere,info,goalsnowstormday);

local lowcloudTween = tweenService:Create(cloud,info,lowCloudy); -- cloud tweends
local mediumcloudTween = tweenService:Create(cloud,info,mediumCloudy);
local fullcloudTween = tweenService:Create(cloud,info,fullCloudy);
local nightcloudTween = tweenService:Create(cloud,info,nightCloudy);

while true do
	repeat task.wait() until	clockTime.ClockTime > 16.4 and clockTime.ClockTime < 16.6

	sunsetTween:Play();

	repeat task.wait() until clockTime.ClockTime > 17.4 and clockTime.ClockTime < 17.6

	blueduskTween:Play();
	
	nightcloudTween:Play();
	game.ReplicatedStorage.RemoteEvents.Snowing:FireAllClients("remove");
	
	repeat task.wait() until clockTime.ClockTime > 17.9 and clockTime.ClockTime < 18.1

	hazeTween:Play();
	
	repeat task.wait() until clockTime.ClockTime > 5.9 and clockTime.ClockTime < 6.1

	dawnTween:Play();
	lowcloudTween:Play();
	
	repeat task.wait() until clockTime.ClockTime > 6.4 and clockTime.ClockTime < 6.6
	
	noHazeTween:Play();
	
	repeat task.wait() until clockTime.ClockTime > 6.9 and clockTime.ClockTime < 7.1

	local rng = math.random(1,10);

	if rng >= 1 and rng <= 4 then
		dayTween:Play();
		print("clearday "..rng);
	elseif rng >= 5 and rng <= 7 then
		cloudyTween:Play();
		print("smallcloudyday "..rng);
	elseif rng >= 8 and rng <= 9 then
		snowycloudyTween:Play();
		mediumcloudTween:Play();
		print("cloudyday "..rng);
	elseif rng == 10 then
		snowstormTween:Play();
		fullcloudTween:Play();
		print("supercloudyday "..rng);
	end
	task.wait(0.1);
end
