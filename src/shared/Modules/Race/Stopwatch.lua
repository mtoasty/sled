local RunService : RunService = game:GetService("RunService");

local Stopwatch : table = {};

local metatable : table = {
    ["__index"] = Stopwatch
};


function Stopwatch.new(limit : number) : table
    local self : table = {};
    setmetatable(self, metatable);

    self.limit = limit;
    self.elapsed = 0;
    self.running = false;
    self.HeartbeatConnection = nil;
    self.event = Instance.new("BindableEvent");
    
    self.startClock = -1;

    return self;
end

function Stopwatch:Start() : nil
    self.running = true;
    self.startClock = os.clock();

    self.HeartbeatConnection = RunService.Heartbeat:Connect(function(deltaTime : number) : nil
        if self.running then
            self.elapsed = self.elapsed + deltaTime;

            if self.elapsed >= self.limit then
                self:LimitReached();
            end
        end
    end);
end

function Stopwatch:Stop() : nil
    self.running = false;
    self.elapsed = os.clock() - self.startClock;

    if self.HeartbeatConnection then
        self.HeartbeatConnection:Disconnect();
        self.HeartbeatConnection = nil;
    end
end

function Stopwatch:LimitReached() : nil
    self:Stop();
    self.event:Fire("LIMIT_REACHED");
end

return Stopwatch;