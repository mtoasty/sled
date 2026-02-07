while true do
	task.wait(1);
	if os.date("%M") == "00" and os.date("%S") == "00" then
		
		--spawn traveller
		local ominousTraveller = game.ServerStorage.OminousTraveller;
		ominousTraveller.Parent = game.Workspace;
		
		local t = {
			"Currents",
			"SantasSleigh"
		};
		
		local choice = math.random(1, #t);
		
		game.ReplicatedStorage.RemoteEvents.OminousChange:FireAllClients(t[choice]);
		task.wait(300);
		game.ReplicatedStorage.RemoteEvents.OminousChange:FireAllClients("off");
		ominousTraveller.Parent = game.ServerStorage;
	end
end