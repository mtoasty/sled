--[[

sled terminal

use commands from different libraries

written by mtoasty

]]

local terminal = {};
terminal.__index = terminal;

local Players = game:GetService("Players");
local ReplicatedStorage = game:GetService("ReplicatedStorage");

local libraries = {};

for _, lib : ModuleScript in pairs(script.Parent.libs:GetChildren()) do
	libraries[lib.Name] = require(lib);
end

--| Find if given library is real:
function isValidLibrary(lib: string): boolean
	for l, t in pairs(libraries) do
		if lib == l then
			return true;
		end
	end

	return false;
end

type terminal = {
	["logs"]: ScrollingFrame,
	["logCount"]: number,
};



--| Terminal initialization:
function terminal.new(ui: Frame): terminal
	local self = setmetatable({}, terminal);


	self.logs = ui.Logs;
	self.logCount = 0;

	self.using = nil;

	self.commands = setmetatable({
		--| Commands:
		["help"] = function(): nil
			self:log("dir              => view the contents of the directory", false, Color3.fromRGB(100, 250, 255));
			self:log("rversion         => gets current roblox/luau version", false, Color3.fromRGB(100, 250, 255));
			self:log("version          => gets sled version", false, Color3.fromRGB(100, 250, 255));
			self:log("plrs             => gets all players in this server", false, Color3.fromRGB(100, 250, 255));
			self:log("clear            => clears the terminal", false, Color3.fromRGB(100, 250, 255));
		end,

		["dir"] = function(): nil
			self:log("Contents of directory:");
			for libName, _ in pairs(libraries) do
				self:log(libName);
			end
		end,

		["rversion"] = function(): nil
			self:log("roblox game version: " .. _VERSION);
		end,

		["version"] = function(): nil
			self:log("sled game version: " .. ReplicatedStorage.ReplicatedValues.sled_version.Value);
		end,

		["plrs"] = function(): nil
			for _, player in pairs(Players:GetPlayers()) do
				self:log(player.Name);
			end
		end,

		["clear"] = function() : nil
			for _, log : TextLabel in pairs(self.logs:GetChildren()) do
				if (log.name == "log0" or log:IsA("UIListLayout")) then continue; end

				log:Destroy();
			end
			self.logCount = 0;

			self.logs.CanvasSize = UDim2.new(0, 0, 0, self.logs.UIListLayout.AbsoluteContentSize.Y);
			self.logs.CanvasPosition = Vector2.new(0, self.logs.CanvasSize.Y.Offset);
		end
	}, {
		--| Metatable (empty)
	});

	return self;
end

--| Log things to terminal:
function terminal:log(message: string, server: boolean, colour: Color3): nil
	colour = colour or Color3.new(1, 1, 1);

	local newLog = self.logs.log0:Clone();
	newLog.TextColor3 = colour;
	newLog.Parent = self.logs;

	if server then
		newLog.Text = "SERVER >> " .. message;
	else
		newLog.Text = message;
	end

	self.logCount += 1;
	newLog.LayoutOrder = self.logCount;
	newLog.Name = "log" .. self.logCount;


	self.logs.CanvasSize = UDim2.new(0, 0, 0, self.logs.UIListLayout.AbsoluteContentSize.Y);
	self.logs.CanvasPosition = Vector2.new(0, self.logs.CanvasSize.Y.Offset);
end

--| Warnings in terminal:
function terminal:warn(message : string, server : boolean) : nil
	self:log(message, server, Color3.fromRGB(255, 150, 0));
end

--| Errors in terminal:
function terminal:err(message : string, server : boolean) : nil
	self:log(message, server, Color3.fromRGB(255, 0, 0));
end

--| Remove spaces at the front of command input:
function removeWhiteSpace(command : string) : string
	return string.gsub(string.gsub(command, "^%s+", ""), "%s+$", "");
end

--| Command interpreter:
function terminal:InterpretCommand(command: string) : nil
	local removedWhiteSpace : string = removeWhiteSpace(command);
	if removedWhiteSpace == "" then return; end
	
	--| Break up input by words
	local args : {string} = string.split(removedWhiteSpace, " ");

	local firstArg : string = args[1];
	table.remove(args, 1);
	

	--| Commands from the root library
	self:log("sled\\root> " .. command);
	
	--| Check if command exists
	if (self.commands[firstArg] ~= nil) then
		self.commands[firstArg](table.unpack(args));
	else
		--| Direct library input, without using the "using" command
		if (isValidLibrary(firstArg)) then
			--| Check if the library command exists, otherwise throw an error
			local secondArg : string = args[1];
			table.remove(args, 1);
			if (libraries[firstArg][secondArg]) then
				libraries[firstArg][secondArg](self, table.unpack(args));
			else
				self:err("'" .. (secondArg or "") .. "' is not a recognized command, type 'help' for a list of commands");
			end
		else
			--| Error message if not a valid command nor library nor library command
			self:err("'" .. firstArg .. "' is not recognized as a command or library, type 'help' for a list of commands");
		end
	end

end

return terminal;