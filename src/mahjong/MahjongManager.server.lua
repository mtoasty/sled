local Players : Players = game:GetService("Players");
local ReplicatedStorage : ReplicatedStorage = game:GetService("ReplicatedStorage");
local MahjongGame = require(ReplicatedStorage:WaitForChild("Modules").Mahjong.MahjongGame);

local startPrompt = script.Parent:WaitForChild("Table"):FindFirstChildOfClass("ProximityPrompt");

local currentGame = nil;

local function onPromptTriggered(player : Player)
    local players : Player = {};
    for _, seat : Seat in pairs(script.Parent.Seats:GetChildren()) do
        if seat and seat.Occupant then
            table.insert(players, Players:GetPlayerFromCharacter(seat.Occupant.Parent));
        end
    end

    if players and #players > 1 then
        print("Starting game");
        currentGame = MahjongGame.new(players);
        currentGame:Start();

        startPrompt.Enabled = false;
    end
end

startPrompt.Triggered:Connect(onPromptTriggered);