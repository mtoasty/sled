local player = game.Players.LocalPlayer;
local samples = script.Parent.MainFrame.Samples or player.PlayerGui.adminUI.MainFrame.Samples;
local console = script.Parent.MainFrame.Console or player.PlayerGui.adminUI.MainFrame.Console;
local inputLine = script.Parent.InputLine or player.PlayerGui.adminUI.InputLine;

local rank = player:GetRankInGroup(13628961);

local admin = {};

function splitArgs(args: string)
    return table.pack(string.split(args, " "));
end

function admin.throwError(msg: string)
	local newLabel = samples.Error:Clone();
	newLabel.Text = msg;
	newLabel.Parent = console;
	newLabel.Visible = true;
	if #console:GetChildren() > 10 then
		console.CanvasSize = UDim2.new(0, 0, console.CanvasSize.Y.Scale + 0.067, 0);
		console.CanvasPosition = Vector2.new(0, console.AbsoluteWindowSize.Y);
	end
end

function admin.log(msg: string)
	local newLabel = samples.Log:Clone();
	newLabel.Text = msg;
	newLabel.Parent = console;
	newLabel.Visible = true;
	if #console:GetChildren() > 10 then
		console.CanvasSize = UDim2.new(0, 0, console.CanvasSize.Y.Scale + 0.067, 0);
		console.CanvasPosition = Vector2.new(0, console.AbsoluteWindowSize.Y);
	end
end

function admin.help(args: string)
    args = splitArgs(args);

    if #args == 0 then
        return admin.throwError("err: unknown arguments given: "..args[1]);
    end

	admin.log("List of commands");
	admin.log("clear -- clears console");
	admin.log("opacity [value: number] -- changes console opacity");
	admin.log("tp [player1, destination] [destination] -- teleport to player or player to player");
	admin.log("time [func: speed, lock] [value: num, bool] -- change time speed / lock");
	admin.log("kick [player: player] [reason: string] -- kick player");
	admin.log("sledstats [method: get, set] [player] [stat: any] [value: any] -- get or set sledstats");
	admin.log("racestats [method: get, set] [player] [stat: any] [value: any] -- get or set racestats");
end

function admin.clear(args)
    args = splitArgs(args);

    if #args == 0 then
        return admin.throwError("err: unknown arguments given: "..args[1]);
    end

	for i,v in pairs(console:GetChildren()) do
		if v.Name == "UIListLayout" then
			continue;
		else
			v:Destroy();
		end
	end

	console.CanvasSize = UDim2.new(0, 0, 1, 0);
end

function admin.tp(args: string)
    args = splitArgs(args);

    if args[3] then
        return admin.throwError("err: unknown arguments given: "..args[3]);
    end

    local target, location = args[1], args[2];

	if not target and not location then
		return admin.throwError("err: no arguments given");
	end

	if target == "#self" then
		target = player.Name;
	end

	if location == "#self" then
		target = player.Name;
	end

	local s, e = pcall(function()
		if not location then
            if not game.Players[target] then
                return admin.throwError("err: player not found");
            end

            if not game.Players[target].Character then
                return admin.throwError("err: player has no character");
            end

            game.ReplicatedStorage.Shared.RemoteEvents.AdminTool:FireServer("Teleport", player, game.Players[target]);
		else
            if not game.Players[target] then
                return admin.throwError("err: player not found");
            end

            if not game.Players[target].Character then
                return admin.throwError("err: player has no character");
            end

            if not game.Players[location] then
                return admin.throwError("err: player not found");
            end

            if not game.Players[location].Character then
                return admin.throwError("err: player has no character");
            end

            game.ReplicatedStorage.Shared.RemoteEvents.AdminTool:FireServer("Teleport", player, game.Players[location]);
            admin.log("teleported "..target.." to "..location);
		end
	end);

	if not s then
		return admin.throwError("err: "..e);
	end
end

function admin.time(args: string)
    args = splitArgs(args);

	if args[3] then
        return admin.throwError("err: unknown arguments given: "..args[3]);
    end

    local func, val = args[1], args[2];

	if not func and not val then
		return admin.throwError("err: no arguments given");
	end

	if val == "true" then
		val = true;
	elseif val == "false" then
		val = false;
	end

	local validVal = false;

	if typeof(val) == "boolean" or tonumber(val) ~= nil then
		validVal = true;
	else
		validVal = false;
	end

	if func == "speed" then

		if val == nil then
			admin.log("time speed is currently at "..game.ReplicatedStorage.RemoteEvents.TimeSpeedGet:InvokeServer("TimeSpeed"));
		else
			if validVal then
				game.ReplicatedStorage.RemoteEvents.ChangeTime:FireServer(tonumber(val));
				admin.log("time speed set to "..val);
			else
				return admin.throwError("err: invalid argument #2, expected number, got '"..val.."'");
			end
		end

	elseif func == "lock" then

		if val == nil then
			admin.log("time speed is currently at "..tostring(game.ReplicatedStorage.RemoteEvents.TimeSpeedGet:InvokeServer("Locked")));
		else
			if validVal then
				game.ReplicatedStorage.RemoteEvents.LockTime:FireServer(val);
				admin.log("time lock set to "..tostring(val));
			else
				return admin.throwError("err: invalid argument #2, expected boolean, got '"..val.."'");
			end
		end

	else
		return admin:throwError("err: unknown function of \'time\'");
	end
end

function admin.kick(plr, reason, extra)
	if extra then
		return admin.throwError("err: unknown arguments given: "..extra)
	end

	if not plr then
		return admin.throwError("err: no player given")
	end

	if plr == "#self" then
		plr = player.Name
	end

	if not game.Players[plr] then
		return admin.throwError("err: player not found")
	end

	if reason then
		game.ReplicatedStorage.RemoteEvents.Kick:FireServer(plr, reason)
	else
		game.ReplicatedStorage.RemoteEvents.Kick:FireServer(plr)
	end
	admin.log("kicked "..plr)
end

function admin.opacity(num, extra)
	if extra then
		return admin.throwError("err: unknown arguments given: "..extra)
	end

	if num == nil then
		admin.log("opacity is currently at "..console.Transparency)
	else
		if tonumber(num) == nil then
			admin.throwError("err: invalid argument, expected number from 0 to 1, got '"..num.."'")
		else
			console.Parent.BackgroundTransparency = 1 - num
			inputLine.BackgroundTransparency = 1 - num
			admin.log("opacity set to "..num)
		end
	end
end

local function recursiveList(f: table, name: string)
	admin.log(name..":")
	for i,v in pairs(f) do
		if v:IsA("Folder") then
			if v.Name == "MoonCollection" then
				local str = ""
				for i,v in pairs(v:GetChildren()) do
					if v.Name == "decodeStr" then
						continue
					else
						str = str..v.Value
					end
				end
				admin.log("MoonCollection: "..str)
			else
				recursiveList(v:GetChildren(), v.Name)
			end
		else
			admin.log(v.Name..": "..tostring(v.Value))
		end
	end
end

function admin.sledstats(method, plr, stat, val, extra)
	if extra then
		return admin.throwError("err: unknown arguments given: "..extra)
	end

	if not method then
		return admin.throwError("err: no given method")
	end

	if method == "get" then

		if not plr then
			return admin.throwError("err: no given player")
		else
			if plr == "#self" then
				plr = player.Name
			end
			if game.Players[plr] then
				recursiveList(game.Players[plr].sledstats:GetChildren(), "sledstats")
			else
				return admin.throwError("err: player not found")
			end
		end

	elseif method == "set" then

		if rank == 255 then
			if not plr then
				return admin.throwError("err: no given player")
			else
				if plr == "#self" then
					plr = player.Name
				end
				if game.Players[plr] then
					if not stat then
						return admin.throwError("err: no given stat")
					else
						if not val then
							return admin.throwError("err: no given value")
						else
							local encodedStat = string.split(stat, ".")
							local result = game.ReplicatedStorage.RemoteEvents.ChangeStat:InvokeServer(plr, encodedStat, val)
							if result == "success" then
								admin.log("changed "..stat.." to "..val)
							elseif result == "unknown" then
								return admin.throwError("err: unknown stat: '"..stat.."'")
							elseif result == "invalid" then
								return admin.throwError("err: failed to assign stat, make sure it is a valid value")
							end
						end
					end
				else
					return admin.throwError("err: player not found")
				end
			end
		else
			return admin.throwError("err: you are not high enough rank to use this method")
		end

	else
		return admin.throwError("err: unknown method of 'sledstats'")
	end

end

function admin.racestats(method, plr, stat, val, extra)
	if extra then
		return admin.throwError("err: unknown arguments given: "..extra)
	end

	if not method then
		return admin.throwError("err: no given method")
	end

	if method == "get" then

		if not plr then
			return admin.throwError("err: no given player")
		else
			if plr == "#self" then
				plr = player.Name
			end
			if game.Players[plr] then
				recursiveList(game.Players[plr].racestats:GetChildren(), "racestats")
			else
				return admin.throwError("err: player not found")
			end
		end

	elseif method == "set" then

		if rank == 255 then
			if not plr then
				return admin.throwError("err: no given player")
			else
				if plr == "#self" then
					plr = player.Name
				end
				if game.Players[plr] then
					if not stat then
						return admin.throwError("err: no given stat")
					else
						if not val then
							return admin.throwError("err: no given value")
						else
							local result = game.ReplicatedStorage.raceTriggers.ChangeStatRace:InvokeServer(plr, {stat}, val)
							if result == "success" then
								admin.log("changed "..stat.." to "..val)
							elseif result == "unknown" then
								return admin.throwError("err: unknown stat: '"..stat.."'")
							elseif result == "invalid" then
								return admin.throwError("err: failed to assign stat, make sure it is a valid value")
							end
						end
					end
				else
					return admin.throwError("err: player not found")
				end
			end
		else
			return admin.throwError("err: you are not high enough rank to use this method")
		end

	else
		return admin.throwError("err: unknown method of 'racestats'")
	end
end

admin.log("type help for list of commands")

return admin
