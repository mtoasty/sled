local chassisBuilder = {};
chassisBuilder.__index = chassisBuilder;

function chassisBuilder.new(length: number, width: number, height: number)
	local self = setmetatable({}, chassisBuilder)
	self.length = length;
	self.width = width;
	self.height = height;
	return self;
end

function chassisBuilder:Build(sl)
	
end

return chassisBuilder;
