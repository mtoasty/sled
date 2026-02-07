local timerModule = {};
timerModule.__index = timerModule;

local startColour = Color3.fromRGB(149, 182, 182);
local goldColour = Color3.fromRGB(255, 200, 0);
local silverColour = Color3.fromRGB(145, 145, 145);
local bronzeColour = Color3.fromRGB(170, 85, 0);
local limitColour = Color3.fromRGB(255, 255, 255);
local failColour = Color3.fromRGB(149, 48, 48);

function timerModule.new(gold: number, silver: number, bronze: number, limit: number, player: Player, timer: Instance)
	local self = setmetatable({}, timerModule);

	self.gold = gold;
	self.silver = silver;
	self.bronze = bronze;
	self.limit = limit;
	self.player = player;
	self.timer = timer;

	self.timing = false;

	return self;
end

function timerModule:End(timeup: boolean)
	self.timing = false;
	if timeup then
		game.ReplicatedStorage.raceTriggers.TimerEnded:FireClient(self.player);
	end
	return self.totalTenths;
end

function timerModule:Start()
	local tenths, seconds, twoDigitSeconds, minutes = 0, 0, 0, 0;
	self.timing = true;
	task.wait(0.1);
	
	self.timer.TextColor3 = goldColour;

	while self.timing == true do
		task.wait(0.1);

		if tenths == 9 then
			tenths = tenths - 10;
			seconds = seconds + 1;
		end

		if seconds == 59 then
			seconds = seconds - 59;
			minutes = minutes + 1;
		end

		tenths = tenths + 1;
		
		--timer
		
		if seconds <= 9 then
			twoDigitSeconds = "0"..seconds;
		else
			twoDigitSeconds = seconds;
		end
		
		self.timer.Text = minutes..":"..twoDigitSeconds.."."..tenths;
		
		-- total tenths 
		
		local totalTenths = tenths + (seconds * 10) + (minutes * 600);
		self.totalTenths = totalTenths;
		
		if totalTenths < self.gold then
			self.timer.TextColor3 = goldColour;
		elseif totalTenths < self.silver then
			self.timer.TextColor3 = silverColour;
		elseif totalTenths < self.bronze then
			self.timer.TextColor3 = bronzeColour;
		elseif totalTenths < self.limit then
			self.timer.TextColor3 = limitColour;
		elseif totalTenths > self.limit then
			
			self:End(true);
		end
		
	end
end

return timerModule;
