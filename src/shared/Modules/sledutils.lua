local sledutils = {};

--[[

* General functions

]]--

--| Maps an array to another array using the provided function
function sledutils.map<T>(input : {T}, func : (T) -> any) : {any}
    local output : {any} = {};

    for i : number, v : T in ipairs(input) do
        table.insert(output, func(v));
    end

    return output;
end

--| Filters an array using the provided function
function sledutils.filter<T> (input : {T}, func : (T) -> boolean) : {T}
    local output : {T} = {};

    for i : number, v : T in ipairs(input) do
        if func(v) then
            table.insert(output, v);
        end
    end

    return output;
end



--[[

* Formatting

]]--


--| Formats a time in seconds to a string in the format of M:SS.mmm
function sledutils.formatTime(time : number) : string
    if time == math.huge or time == 99999 then
        return "-:--";
    end

    local minutes = math.floor(time / 60);
    local seconds = math.floor(time % 60);
    local milliseconds = math.floor((time - math.floor(time)) * 1000);

    return string.format("%d:%02d.%03d", minutes, seconds, milliseconds);
end

--| source: https://devforum.roblox.com/t/efficiently-turn-a-table-into-a-string/1102221/13
--| Converts a table into a multiline string
function sledutils.formatTable(v, spaces, usesemicolon, depth)
	if type(v) ~= 'table' then
		return tostring(v)
	elseif not next(v) then
		return '{}'
	end

	spaces = spaces or 4
	depth = depth or 1

	local space = (" "):rep(depth * spaces)
	local sep = usesemicolon and ";" or ","
	local concatenationBuilder = {"{"}
	
	for k, x in next, v do
		table.insert(concatenationBuilder, ("\n%s[%s] = %s%s"):format(space,type(k)=='number'and tostring(k)or('"%s"'):format(tostring(k)), sledutils.formatTable(x, spaces, usesemicolon, depth+1), sep))
	end

	local s = table.concat(concatenationBuilder)
	return ("%s\n%s}"):format(s:sub(1,-2), space:sub(1, -spaces-1))
end


--[[

* Unit Testing

]]--

local function areTablesEqual(t1 : table, t2 : table) : boolean
    -- Check if both tables have the same keys
    local t1Keys : {string | number} = {};
    local t2Keys : {string | number} = {};

    for k : string | number, _ in pairs(t1) do
        table.insert(t1Keys, k);
    end

    for k : string | number, _ in pairs(t2) do
        table.insert(t2Keys, k);
    end

    -- Compare the keys
    if #t1Keys ~= #t2Keys then
        return false;
    end

    -- Sort the keys to ensure they're in the same order
    table.sort(t1Keys);
    table.sort(t2Keys);

    for i = 1, #t1Keys do
        if t1Keys[i] ~= t2Keys[i] then
            return false;
        end
    end

    -- Compare the values
    for k : string | number, v : any in pairs(t1) do
        if t2[k] ~= v then
            return false;
        end
    end

    return true;
end

--| Standard unit test, non-halting
function sledutils.checkExpect<T>(testingValue : T, expectedValue : T) : nil
    local cond : boolean;
    if type(testingValue) == "table" then
        cond = areTablesEqual(testingValue, expectedValue);
    else
        cond = testingValue == expectedValue;
    end

    if cond then
        print("Test passed for value:");
    else
        warn("Test failed. Expected:");
        print(expectedValue);
        warn("got:")
        print(testingValue);
    end
end


--[[

* Other

]]--

function sledutils.isDeveloper(player : Player) : boolean
    return player:GetRankInGroupAsync(13628961) >= 254;
end

function sledutils.xpRequirement(currentLevel : number) : number
    return math.floor(10 * currentLevel * math.log10(currentLevel)) + 100;
end

return sledutils;