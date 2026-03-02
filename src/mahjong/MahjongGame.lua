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

    self.turnIndex = math.random(1, #players);
    self.dealer = players[self.turnIndex];
    self.deck = Mahjong.Deck.new();

    self.discard = {};

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

function MahjongGame:GetAvailableActions(hand : Mahjong.Hand, myturn : boolean) : {string}
    local actions : {string} = {};
    local recentDiscard : string = self.discard[#self.discard];

    if hand:CanPeng(recentDiscard) then
        table.insert(actions, "Peng");
    end

    if hand:CanGang(recentDiscard) then
        table.insert(actions, "Gang");
    end

    if myturn then
        if hand:CanAnGang() then
            table.insert(actions, "AnGang");
        end
        
        if hand:CanChi(recentDiscard) then
            table.insert(actions, "Chi");
        end

        table.insert(actions, "Draw");
    end

    return actions;
end

local function getNextTurnIndex(currentTurnIndex : number, numPlayers : number) : number
    if currentTurnIndex == numPlayers then
        return 1;
    else
        return currentTurnIndex + 1;
    end
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
        if action == "discard" then
            self:GetPlayerDeck(player):RemoveCard(data);
            table.insert(self.discard, Mahjong.Card.fromString(data));

            remoteEvent:FireAllClients("discard", {["player"] = player.Name, ["card"] = Mahjong.Card.getImage(data)});

            self:NextTurn();
        end
    end);

    remoteFunction.OnServerInvoke = function(player : Player, action : string)
        if action == "Draw" then
            return {self:GetPlayerDeck(player):AddCard(self.deck:Draw())}, false;
        elseif action == "AnGang" then
            local drawnCard = self:GetPlayerDeck(player):AddCard(self.deck:Draw());

            -- ! box cards

            return {drawnCard}, false;
        elseif action == "Peng" or action == "Chi" then
            local recentDiscard : string = self.discard[#self.discard];
            local addedCard = self:GetPlayerDeck(player):AddCard(Mahjong.Card.fromString(recentDiscard));
            table.remove(self.discard, #self.discard);

            -- ! box cards

            return {addedCard}, true;
        elseif action == "Gang" then
            local recentDiscard : string = self.discard[#self.discard];
            local addedCard = self:GetPlayerDeck(player):AddCard(Mahjong.Card.fromString(recentDiscard));
            local drawnCard = self:GetPlayerDeck(player):AddCard(self.deck:Draw());
            table.remove(self.discard, #self.discard);

            -- ! box cards

            return {addedCard, drawnCard}, true;
        end
    end
end

function MahjongGame:NextTurn() : nil
    local nextPlayerIndex = getNextTurnIndex(self.turnIndex, #self.players);
    local nextPlayer = self.players[nextPlayerIndex];

    print("Next turn: " .. nextPlayer.Name);
    self.turnIndex = nextPlayerIndex;

    for _, p : Players in pairs(self.players) do
        if p == nextPlayer then
            remoteEvent:FireClient(p, "turn", self:GetAvailableActions(self:GetPlayerDeck(p), true));
        else
            remoteEvent:FireClient(p, "turn", self:GetAvailableActions(self:GetPlayerDeck(p), false));
        end
    end
end


return MahjongGame;