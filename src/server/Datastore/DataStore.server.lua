local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ds = DataStoreService:GetDataStore("sledsave")
--[[
game.Players.PlayerAdded:Connect(function(player)
	local sledstats = Instance.new("Folder")
	sledstats.Parent = player
	sledstats.Name = "sledstats"

	local level = Instance.new("IntValue")
	level.Parent = sledstats
	level.Name = ("Level")

	local sledtype = Instance.new("StringValue")
	sledtype.Parent = sledstats
	sledtype.Name = "SledType"
	
	local moons = Instance.new("IntValue")
	moons.Parent = sledstats
	moons.Name = "Moons"
	
	local flashlightLevel = Instance.new("IntValue")
	flashlightLevel.Parent = sledstats
	flashlightLevel.Name = "FlashlightLevel"
	
	local moonCollection = Instance.new("Folder")
	moonCollection.Parent = sledstats
	moonCollection.Name = "MoonCollection"
	
	local decodeStr = Instance.new("StringValue")
	decodeStr.Parent = moonCollection
	decodeStr.Name = "decodeStr"
	
	local ominous = Instance.new("Folder")
	ominous.Parent = sledstats
	ominous.Name = "Ominous"
	
	local decodeOmn = Instance.new("StringValue")
	decodeStr.Parent = moonCollection
	decodeStr.Name = "decodeStr"
	
	local rd = Instance.new("IntValue")
	rd.Parent = player
	rd.Name = "Distance"
	
	local xp = Instance.new("IntValue")
	xp.Parent = sledstats
	xp.Name = "xp"
	
	for i = 1,20,1 do
		local v = Instance.new("StringValue")
		v.Parent = moonCollection
		v.Name = i
	end
	
	for i = 1,20,1 do
		local v = Instance.new("StringValue")
		v.Parent = ominous
		v.Name = i
	end
	
	if script.Parent.RequestLimits.Get.Value <= 0 then
		repeat wait() until script.Parent.RequestLimits.Get.Value > 0
	end
	
	script.Parent.RequestLimits.Get.Value -= 1
	game.ReplicatedStorage.RemoteEvents.DataLoaded:FireClient(player, "DataLoaded")
	
	local stats = ds:GetAsync(player.UserId)

	if stats ~= nil then
		level.Value = stats[1]
		sledtype.Value = stats[2]
		moons.Value = stats[3]
		decodeStr.Value = stats[4]
		flashlightLevel.Value = stats[5]
		decodeOmn.Value = stats[6]
		xp.Value = stats[7]
	else
		level.Value = 1
		sledtype.Value = "Storm"
		moons.Value = 0
		for i = 1,20,1 do
			player.sledstats.MoonCollection:WaitForChild(i).Value = "0"
		end
		decodeStr.Value = "00000000000000000000"
		flashlightLevel.Value = 1
		decodeOmn.Value = "00000000000000000000"
		xp.Value = 0
	end
	
	if level.Value == nil or level.Value == 0 or level.Value == 99999 then
		level.Value = 1
	end

	if sledtype.Value == nil or sledtype.Value == "" then
		sledtype.Value = "Storm"
	end

	if moons.Value == nil then
		moons.Value = 0
	end

	if decodeStr.Value == "" or decodeStr.Value == nil then
		decodeStr.Value = "00000000000000000000"
	end
	
	if flashlightLevel.Value == 0 then
		flashlightLevel.Value = 1
	end
	
	if decodeOmn.Value == "" or decodeOmn.Value == nil then
		decodeOmn.Value = "00000000000000000000"
	end
	
	if xp.Value == nil then
		xp.Value = 0
	end
	
	local toDecode = decodeStr.Value
	local decoded = ""
	for i = 1,20,1 do
		local v = string.sub(toDecode,i,i)
		player.sledstats.MoonCollection:WaitForChild(i).Value = v
	end
	
	local toDecode2 = decodeOmn.Value
	local decoded2 = ""
	for i = 1,20,1 do
		local v = string.sub(toDecode2,i,i)
		player.sledstats.Ominous:WaitForChild(i).Value = v
	end
	
	print(stats)
end)

game.Players.PlayerRemoving:Connect(function(player)
	
	local encoded = ""
	for i = 1,20,1 do
		local v = player.sledstats.MoonCollection:FindFirstChild(i)
		encoded = encoded..v.Value
	end
	
	local encoded2 = ""
	for i = 1,20,1 do
		local v = player.sledstats.Ominous:FindFirstChild(i)
		encoded2 = encoded2..v.Value
	end
	
	local save = {}
	
	table.insert(save, 1, player.sledstats.Level.Value)
	table.insert(save, 2, player.sledstats.SledType.Value)
	table.insert(save, 3, player.sledstats.Moons.Value)
	table.insert(save, 4, encoded)
	table.insert(save, 5, player.sledstats.FlashlightLevel.Value)
	table.insert(save, 6, encoded2)
	table.insert(save, 7, player.sledstats.xp.Value)
	
	ds:SetAsync(player.UserId, save)
	print(save)
end)
]]

function assignData(assignto, item, conditions, default)
	if item == nil then
		assignto.Value = default
	else
		assignto.Value = item
		for i = 1, #conditions do
			if not (conditions[i])then
				assignto.Value = default
			end
		end
	end
end



game.Players.PlayerAdded:Connect(function(player)
	repeat task.wait() until DataStoreService:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.GetAsync) > 0

	local data = ds:GetAsync(player.UserId)
	local dataPackage = ReplicatedStorage.DataPackage;
	
	for i, v in pairs(dataPackage:GetChildren()) do
		local new = v:Clone();
		new.Parent = player;
	end

	if data ~= nil then -- DATA TRANSFER
		if #data == 7 then
			
			local level = player.sledstats.Level
			local sledtype = player.sledstats.SledType
			local moons = player.sledstats.Moons
			local decodeStr
			local flashlightLevel = player.sledstats.FlashlightLevel
			local xp = player.sledstats.xp
			
			level.Value = data[1]
			sledtype.Value = data[2]
			moons.Value = data[3]
			decodeStr = data[4]
			flashlightLevel.Value = data[5]
			xp.Value = data[7]
			
			for i = 1,20,1 do
				local v = string.sub(decodeStr,i,i)
				player.sledstats.MoonCollection:WaitForChild(i).Value = v
			end
			
		else -- MAIN
			
			local sledstats = data.sledstats
			
			local dataSettings = sledstats.Settings
			local distance = dataSettings.Distance
			local renderTick = dataSettings.RenderTick
			local shadows = dataSettings.Shadows
			
			local flashlightLevel = sledstats.FlashlightLevel
			local level = sledstats.Level
			local moons = sledstats.Moons
			local sledType = sledstats.SledType
			local xp = sledstats.xp
			
			local racestats = data.racestats
			
			local cupid = racestats.cupid
			local mixpeed = racestats.mixpeed
			local pure = racestats.pure
			local wzrd = racestats.wzrd
			local forever = racestats.forever
			
			if sledstats.MoonCollection then
				for i,v in ipairs(sledstats.MoonCollection) do
					if v == nil then
						player.sledstats.MoonCollection[tostring(i)].Value = "0"
					else
						assignData(player.sledstats.MoonCollection[tostring(i)], v, {v == "0" or v == "1"}, "0")
					end
				end
			end
			
			
			
			if sledstats.Ominous then
				for i,v in ipairs(sledstats.Ominous) do
					if v == nil then
						player.sledstats.Ominous[i].Value = false
					else
						assignData(player.sledstats.Ominous[i], v, {v == true or v == false}, false)
					end
				end
			end
			
			
			
			if distance == nil then
				player.sledstats.Settings.Distance.Value = 1000
			else
				assignData(player.sledstats.Settings.Distance, distance, {distance > 0}, 1000)
			end
			
			
			
			if renderTick == nil then
				player.sledstats.Settings.RenderTick.Value = 60
			else
				assignData(player.sledstats.Settings.RenderTick, renderTick, {renderTick > 0}, 60)
			end
			
			
			
			if shadows == nil then
				player.sledstats.Settings.Shadows.Value = true
			else
				assignData(player.sledstats.Settings.Shadows, shadows, {}, true)
			end
			
			
			
			if flashlightLevel == nil then
				player.sledstats.FlashlightLevel.Value = 1
			else
				assignData(player.sledstats.FlashlightLevel, flashlightLevel, {flashlightLevel > 0}, 1)
			end
			
			
			
			if level == nil then
				player.sledstats.Level.Value = 1
			else
				assignData(player.sledstats.Level, level, {level > 0}, 1)
			end

			
			
			if moons == nil then
				player.sledstats.Moons.Value = 0
			else
				assignData(player.sledstats.Moons, moons, {moons <= 20, moons >= 0}, 0)
			end
			
			
			
			if sledType == nil then
				player.sledstats.SledType.Value = "Storm"
			else
				assignData(player.sledstats.SledType, data.sledstats.SledType, {data.sledstats.SledType ~= ""}, "Storm")
			end
			
			
			if xp == nil then
				player.sledstats.xp.Value = 0
			else
				assignData(player.sledstats.xp, xp, {}, 0)
			end



			if cupid == nil then
				player.racestats.cupid.Value = 99999
			else
				assignData(player.racestats.cupid, cupid, {cupid > 0}, 99999)
			end	
			
			
			
			if mixpeed == nil then
				player.racestats.mixpeed.Value = 99999
			else
				assignData(player.racestats.mixpeed, mixpeed, {mixpeed > 0}, 99999)
			end
			
			
			
			if pure == nil then
				player.racestats.pure = 99999
			else
				assignData(player.racestats.pure, pure, {pure > 0}, 99999)
			end



			if wzrd == nil then
				player.racestats.wzrd = 99999
			else
				assignData(player.racestats.wzrd, wzrd, {wzrd > 0}, 99999)
			end



			if forever == nil then
				player.racestats.forever = 99999
			else
				assignData(player.racestats.forever, forever, {forever > 0}, 99999)
			end
		end
	end
	game.ReplicatedStorage.RemoteEvents.DataLoaded:FireClient(player, "DataLoaded")
	print(data)
end)

game.Players.PlayerRemoving:Connect(function(player)
	
	local save = {
		
		["sledstats"] = {
			
			MoonCollection = {
				player.sledstats.MoonCollection["1"].Value,
				player.sledstats.MoonCollection["2"].Value,
				player.sledstats.MoonCollection["3"].Value,
				player.sledstats.MoonCollection["4"].Value,
				player.sledstats.MoonCollection["5"].Value,
				player.sledstats.MoonCollection["6"].Value,
				player.sledstats.MoonCollection["7"].Value,
				player.sledstats.MoonCollection["8"].Value,
				player.sledstats.MoonCollection["9"].Value,
				player.sledstats.MoonCollection["10"].Value,
				player.sledstats.MoonCollection["11"].Value,
				player.sledstats.MoonCollection["12"].Value,
				player.sledstats.MoonCollection["13"].Value,
				player.sledstats.MoonCollection["14"].Value,
				player.sledstats.MoonCollection["15"].Value,
				player.sledstats.MoonCollection["16"].Value,
				player.sledstats.MoonCollection["17"].Value,
				player.sledstats.MoonCollection["18"].Value,
				player.sledstats.MoonCollection["19"].Value,
				player.sledstats.MoonCollection["20"].Value
			},
			
			["Ominous"] = {
				["Currents"] = player.sledstats.Ominous.Currents.Value,
				["SantasSleigh"] = player.sledstats.Ominous.SantasSleigh.Value
			},
			
			["Settings"] = {
				
				["Distance"] = player.sledstats.Settings.Distance.Value,
				["RenderTick"] = player.sledstats.Settings.RenderTick.Value,
				["Shadows"] = player.sledstats.Settings.Shadows.Value
				
			},
			
			["FlashlightLevel"] = player.sledstats.FlashlightLevel.Value,
			["Level"] = player.sledstats.Level.Value,
			["Moons"] = player.sledstats.Moons.Value,
			["SledType"] = player.sledstats.SledType.Value,
			["xp"] = player.sledstats.xp.Value
			
		},
		
		["racestats"] = {

			["cupid"] = player.racestats.cupid.Value,
			["mixpeed"] = player.racestats.mixpeed.Value,
			["pure"] = player.racestats.mixpeed.Value,
			["wzrd"] = player.racestats.wzrd.Value,
			["forever"] = player.racestats.forever.Value
			
		}
		
	}
	
	pcall(function()
		ds:SetAsync(player.UserId, save)
	end)

	print(save)
	
end)