local Players : Players = game:GetService("Players");
local ReplicatedStorage : ReplicatedStorage = game:GetService("ReplicatedStorage");
local checkpointEvent : RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvents").Race.Checkpoint;
local TimeTrialInfos : table = require(script.Parent.TimeTrialInfos);

local TimeTrial : table = {};
local metatable : table = {
    ["__index"] = TimeTrial
};

function TimeTrial.new(player: Player, raceID : string, checkpoints : Folder, timer : table) : table
    local self : table = {};
    setmetatable(self, metatable);

    self.Player = player;
    self.character = player.Character or player.CharacterAdded:Wait();
    self.ttInfo = TimeTrialInfos[raceID];
    self.timing = false;
    self.finished = false;
    self.timer = timer;

    self.checkpoints = checkpoints;
    self.totalCheckpoints = #checkpoints:GetChildren();
    self.nextCheckpoint = 1;
    self.checkpointPart = nil;
    self.checkpointConnection = nil;
    self.checkpointEvent = Instance.new("BindableEvent");

    self.event = Instance.new("BindableEvent");


    return self;
end

function TimeTrial:RevealNextCheckpoint() : nil
    local nextCheckpoint : Model = self.checkpoints:FindFirstChild(tostring(self.nextCheckpoint));
    if nextCheckpoint then

        if self.checkpointConnection then
            self.checkpointConnection:Disconnect();
        end

        self.checkpointPart = nextCheckpoint.Hitbox;
    else
        --| No more checkpoints
        self:Finish();
    end

    checkpointEvent:FireClient(self.Player, self.nextCheckpoint);
end

function TimeTrial:Start() : nil
    self.timing = true;

    self.character:FindFirstChildOfClass("Humanoid").Seated:Connect(function(active : boolean) : nil
        if active == false then
            self:Abort();
        end
    end);

    self.character:FindFirstChildOfClass("Humanoid").Died:Connect(function() : nil
        self:Abort();
    end);

    self.timer.event.Event:Connect(function(signal : string) : nil
        if signal == "LIMIT_REACHED" then
            self:Abort();
        end
    end);

    while self.timing do
        self:RevealNextCheckpoint();

        self.checkpointConnection = self.checkpointPart.Touched:Connect(function(hit : BasePart) : nil
            local character : Model = hit.Parent;
            local player : Player = Players:GetPlayerFromCharacter(character);

            if player == self.Player then
                self.nextCheckpoint += 1;
                self.checkpointEvent:Fire();
            end
        end);

        self.checkpointEvent.Event:Wait();
    end

end

function TimeTrial:Abort() : nil
    self.timing = false;

    self.event:Fire("ABORTED");
end

function TimeTrial:Finish() : nil
    self.timing = false;
    self.finished = true;

    self.event:Fire("FINISHED");
end

return TimeTrial;