local event = game.ReplicatedStorage.raceTriggers.RaceTimer;
local timer = require(script.Parent.TimerModule);

local goldTimes = {
	["mixpeed"] = 200,
	["cupid"] = 285,
	["pure"] = 165
};

local silverTimes = {
	["mixpeed"] = 250,
	["cupid"] = 350,
	["pure"] = 200
};

local bronzeTimes = {
	["mixpeed"] = 300,
	["cupid"] = 450,
	["pure"] = 250
};

local limit = {
	["mixpeed"] = 600,
	["cupid"] = 600,
	["pure"] = 450
};

local nextTimer = 1;
local activeRaces = {};

event.OnServerInvoke = function(player: Player, racename: string, timerGui: Instance, signal: boolean, tId: number)
	if signal == true then
		local id = nextTimer;

		local newLocalTimer = timer.new(goldTimes[racename], silverTimes[racename], bronzeTimes[racename], limit[racename], player, timerGui)
		table.insert(activeRaces, {
			["timerId"] = id,
			["activeTimer"] = newLocalTimer
		});

		task.spawn(function()
			newLocalTimer:Start();
		end)

		nextTimer += 1;

		return id;

	elseif signal == false then
		local foundTimer;

		for i, v in pairs(activeRaces) do
			if v.timerId == tId then
				foundTimer = v;
				break;
			end
		end

		local result = foundTimer.activeTimer:End(false);

		table.remove(activeRaces, table.find(activeRaces, foundTimer));

		return result;
	end
end