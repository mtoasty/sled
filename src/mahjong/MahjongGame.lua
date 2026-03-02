---@diagnostic disable: undefined-type
math.randomseed(tick());

local ReplicatedStorage : ReplicatedStorage = game:GetService("ReplicatedStorage");

local Mahjong : Mahjong = require(script.Parent.Mahjong);
local MahjongGame : MahjongGame = {};

local remoteEvent : RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvents").Mahjong.RemoteEvent;
local remoteFunction : RemoteFunction = ReplicatedStorage:WaitForChild("RemoteEvents").Mahjong.RemoteFunction;

export type MahjongGame = {
    ["players"] : {Player},
    ["hands"] : {Mahjong.Hand},
    ["dealer"] : Player,
    ["deck"] : Mahjong.Deck,

    ["new"] : ({Player}) -> MahjongGame
}

function MahjongGame.new(players : {Player}) : MahjongGame
    local self = setmetatable({}, {
        ["__index"] = MahjongGame
    });

    self.players = players;
    self.hands = {};
    for i, player : Player in pairs(players) do
        self.hands[i] = Mahjong.Hand.new(player);
    end

    self.dealer = players[math.random(1, #players)];
    self.deck = Mahjong.Deck.new();

    return self;
end

function MahjongGame:Deal() : nil
    for i, player : Player in ipairs(self.players) do
        for c : number = 1, 13 do
            print("Dealing card " .. c .. " to player " .. player.Name);
            self.hands[i]:AddCard(self.deck:Draw());
        end

        if player == self.dealer then
            print("Dealing dealer's 14th card");
            self.hands[i]:AddCard(self.deck:Draw());
        end
    end
end

function MahjongGame:GetPlayerDeck(player : Player)
    for i, hand : Mahjong.Hand in pairs(self.hands) do
        if hand.owner == player then
            return hand;
        end
    end
end

local function playerListToStringList(players : {Player}) : string
    local playerNames : {string} = {};
    for _, player in pairs(players) do
        table.insert(playerNames, player.Name);
    end

    return playerNames;
end

function MahjongGame:Start() : nil
    print("Game started with dealer " .. self.dealer.Name);
    self:Deal();

    for _, player in pairs(self.players) do
        local handAsTable : {table} = self:GetPlayerDeck(player):AsTable();
        print("Dealt hand to player " .. player.Name .. ":");
        print(handAsTable)

        local data = {
            ["hand"] = handAsTable,
            ["players"] = playerListToStringList(self.players),
            ["dealer"] = self.dealer.Name
        };

        remoteEvent:FireClient(player, "init", data);
    end

    remoteEvent.OnServerEvent:Connect(function(player : Player, action : string, data : any)
        if action == "dealerDiscard" then
            if player ~= self.dealer then
                warn("Player " .. player.Name .. " attempted to discard as dealer when they are not the dealer");
                return;
            end

            self:GetPlayerDeck(player):RemoveCard(data);

            remoteEvent:FireAllClients("dealerDiscard", {["player"] = player.Name, ["card"] = Mahjong.Card.getImage(data)});
        end
    end);
end



return MahjongGame;