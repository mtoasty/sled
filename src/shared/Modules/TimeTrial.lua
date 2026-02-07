local TimeTrialInfos = require(script.Parent.TimeTrialInfos);

local TimeTrial = {};
local metatable = {
    ["__index"] = TimeTrial
};

function TimeTrial.new(player: Player, id: string, timer: Instance)
    local self = setmetatable({}, metatable);

    self.player = player;
    self.raceId = id;
    self.Infos = TimeTrialInfos[id];
    self.timer = timer;

    self.curtime = 0;

    return self;
end

function TimeTrial:InitializeCheckpoints(folder: Folder)
    self.checkpoints = folder;
    self.curPoint = 1;
    self.totalCheckpoints = #folder:GetChildren() + 1;
    self.disqualified = false;

    return true;
end

local goldColour = Color3.fromRGB(255, 200, 0);
local silverColour = Color3.fromRGB(176, 176, 176);
local bronzeColour = Color3.fromRGB(176, 99, 36);
local limitColour = Color3.new(1, 1, 1);
local dqColour = Color3.fromRGB(171, 12, 12);

function FormatTime(t: number)
    local tenths;
	local seconds;
	local minutes;
	local decodedTime;

	tenths = t % 10 ;
	seconds = (t - tenths) / 10;
	minutes = math.floor(seconds / 60);
	seconds = seconds - minutes * 60;

	if seconds <= 9 then
		decodedTime = minutes..":0"..seconds.."."..tenths;
	else
		decodedTime = minutes..":"..seconds.."."..tenths;
	end

	return decodedTime;
end

function TimeTrial:StartTiming()
    local timesList = self.Infos.Times;
    local gold = timesList.Gold;
    local silver = timesList.Silver;
    local bronze = timesList.Bronze;
    local limit = timesList.Limit;

    task.wait(0.1);
    while true do
        if self.disqualified then
            break;
        end

        if self.curPoint == self.totalCheckpoints then
            break;
        end

        self.curtime += 1;
        self.timer.Text = FormatTime(self.curtime);

        if self.curtime < gold then
            self.timer.TextColor3 = goldColour;
        elseif self.curtime < silver then
            self.timer.TextColor3 = silverColour;
        elseif self.curtime < bronze then
            self.timer.TextColor3 = bronzeColour;
        elseif self.curtime < limit then
            self.timer.TextColor3 = limitColour;
        elseif self.curtime > limit then
            self:Abort();
            return;
        end

        task.wait(0.09);
    end
end

function TimeTrial:Start()
    task.spawn(function()
        self:StartTiming()
    end);
    game.ReplicatedStorage.raceTriggers.RaceEvent:InvokeServer("Start");

    self.player.Character.Humanoid.Touched:Connect(function(hit: Instance)
        if hit.Name == "Hitbox" and hit.Parent.Name == tostring(self.curPoint) then
            if self.disqualified == false and self.curPoint < self.totalCheckpoints then
                self.checkpoints:FindFirstChild(self.curPoint).Ring.Transparency = 1;
                self.curPoint = self.curPoint + 1;
            end
        end
    end);

    repeat
        task.wait();
        if self.curPoint < self.totalCheckpoints then
            if self.player.Character.Humanoid.Sit == false then
                self.disqualified = true;
                self:Abort();
                return false;
            else
                if not self.disqualified then
                    self.checkpoints:FindFirstChild(self.curPoint).Ring.Transparency = 0.5;
                end
            end
        end
    until self.curPoint == self.totalCheckpoints or self.disqualified == true

    if self.curPoint == self.totalCheckpoints then
        local serverTime, ostime = game.ReplicatedStorage.raceTriggers.RaceEvent:InvokeServer("Stop");
        local xpresult = self:End();
        return true, {self.curtime, serverTime, ostime}, xpresult;
    end

    if self.disqualified then
        return false;
    end
end

function TimeTrial:End()
    local newbest, speedDemon = false, false;
    local playerCurrent = self.player.racestats[self.raceId].Value;

    if self.curtime < playerCurrent then
        newbest = true;
    end

    if self.curtime < (self.Infos.Times.Gold - 50) then
        speedDemon = true
    end

    local xp = self.Infos["xpFormula"](self.curtime, newbest, speedDemon);

    game.ReplicatedStorage.raceTriggers.RaceEvent:InvokeServer("End", xp, self.curtime, self.raceId);

    return {
        ["timexp"] = math.round((self.Infos.Times.Limit - self.curtime) * (self.Infos.Difficulty / 3)),
        ["newbest"] = newbest,
        ["sd"] = speedDemon,
        ["totalxp"] = xp
    };
end

function TimeTrial:Abort()
    self.disqualified = true;
    self.checkpoints:FindFirstChild(self.curPoint).Ring.Transparency = 1;
    self.timer.TextColor3 = dqColour;
    self.timer.Text = "DISQUALIFIED";
    game.ReplicatedStorage.raceTriggers.RaceEvent:InvokeServer("Abort");
end

return TimeTrial;