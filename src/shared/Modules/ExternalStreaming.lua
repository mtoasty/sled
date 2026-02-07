local externalStreaming = {};
externalStreaming.__index = externalStreaming;

function externalStreaming.new(player)
	local self = setmetatable({}, externalStreaming);
	assert(typeof(player) == "Instance", "Invalid argument #1: Expected Player got "..typeof(player));
	self.player = player;
	self.running = false;
	return self;
end

function externalStreaming:SetPos(pos)
	assert(typeof(pos) == "Instance", "Invalid argument #1: Expected Instance got "..typeof(pos));
	self.pos = pos;
end

function externalStreaming:Start()
	self.running = true;
	while self.running do
		self.player:RequestStreamAroundAsync(self.pos.Position);
	end
end

function externalStreaming:Stop()
	self.running = false;
end

return externalStreaming;