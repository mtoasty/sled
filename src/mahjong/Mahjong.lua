math.randomseed(tick());

local cardImages : {string} = {
    ["dot1"] = "rbxassetid://123309322341863",
    ["dot2"] = "rbxassetid://83668039635574",
    ["dot3"] = "rbxassetid://112576074113811",
    ["dot4"] = "rbxassetid://100020320817349",
    ["dot5"] = "rbxassetid://123679954949155",
    ["dot6"] = "rbxassetid://102359795501293",
    ["dot7"] = "rbxassetid://86584497336959",
    ["dot8"] = "rbxassetid://132807109063976",
    ["dot9"] = "rbxassetid://136959057044347",
    ["snake1"] = "rbxassetid://115668501755422",
    ["snake2"] = "rbxassetid://117024039598807",
    ["snake3"] = "rbxassetid://133077164975804",
    ["snake4"] = "rbxassetid://117069308955288",
    ["snake5"] = "rbxassetid://98733816688799",
    ["snake6"] = "rbxassetid://91387745414817",
    ["snake7"] = "rbxassetid://127719936925915",
    ["snake8"] = "rbxassetid://125710508495813",
    ["snake9"] = "rbxassetid://84315767644686",
    ["wan1"] = "rbxassetid://94529197802547",
    ["wan2"] = "rbxassetid://126520118599998",
    ["wan3"] = "rbxassetid://129664647113310",
    ["wan4"] = "rbxassetid://106674525804846",
    ["wan5"] = "rbxassetid://95955192752142",
    ["wan6"] = "rbxassetid://74643994126305",
    ["wan7"] = "rbxassetid://80243621120518",
    ["wan8"] = "rbxassetid://79588743749635",
    ["wan9"] = "rbxassetid://82023235656054",
    ["baiban0"] = "rbxassetid://129026097404890",
    ["bei0"] = "rbxassetid://120590405742989",
    ["dong0"] = "rbxassetid://136735076745679",
    ["nan0"] = "rbxassetid://83410595616101",
    ["xi0"] = "rbxassetid://135041723546042",
    ["fa0"] = "rbxassetid://124160524141515",
    ["zhong0"] = "rbxassetid://106398602556688"
}

local allSuits : {string} = {"baiban", "bei", "dong", "nan", "xi", "fa", "zhong", "dot", "snake", "wan"};
local faceCards : {string} = {"baiban", "bei", "dong", "nan", "xi", "fa", "zhong"};
local suits : {string} = {"dot", "snake", "wan"};


local Card : Card = {};

export type Card = {
    ["suit"] : string,
    ["value"] : number,
    ["image"] : string,

    ["new"] : (string, number?) -> Card,
    ["fromString"] : (string) -> Card,
    ["getImage"] : (string) -> string,
    ["AsTable"] : () -> table
}

function Card.new(suit : string, value : number?) : Card
    local self = setmetatable({}, {
        ["__index"] = Card,
        ["__eq"] = function(a : Card, b : Card) : boolean
            return a.suit == b.suit and a.value == b.value;
        end,
        ["__tostring"] = function(t : Card) : string
            return t.suit .. tostring(t.value);
        end
    });

    self.suit = suit;
    self.value = value or 0;
    self.image = cardImages[suit .. tostring(value)];

    return self;
end

function Card.fromString(cardId : string) : Card
    local suit, value = string.sub(cardId, 1, #cardId - 1), string.sub(cardId, #cardId, #cardId + 1);

    if not suit then
        error("Invalid card ID: " .. cardId);
    end

    value = tonumber(value) or 0;

    return Card.new(suit, value);
end

function Card.getImage(cardId : string) : string
    return cardImages[cardId];
end

function Card:AsTable() : table
    return {
        ["suit"] = self.suit,
        ["value"] = self.value,
        ["image"] = self.image
    };
end





local Hand : Hand = {};

export type Hand = {
    ["owner"] : Player,
    ["cards"] : {Card},
    ["lockedCards"] : {Card},

    ["new"] : () -> Hand,
    ["Sort"] : () -> nil,
    ["AddCard"] : (Card) -> Card,
    ["RemoveCard"] : (Card) -> Card,
    ["AsTable"] : () -> {table},
    ["HasWon"] : () -> table,
    ["CanPeng"] : (Card) -> boolean,
    ["CanGang"] : (Card) -> boolean,
    ["CanChi"] : (Card) -> boolean
}

function Hand.new(player : Player) : Hand
    local self = setmetatable({}, {
        ["__index"] = Hand
    });

    self.owner = player;
    self.cards = {};
    self.lockedCards = {};

    return self;
end

function Hand:Sort() : nil
    table.sort(self.cards, function(a : Card, b : Card) : boolean
        if a.suit == b.suit then
            return a.value < b.value;
        else
            return table.find(allSuits, a.suit) < table.find(allSuits, b.suit);
        end
    end);
end

function Hand:AddCard(card : Card) : Card
    table.insert(self.cards, card);
    self:Sort();

    return card
end

function Hand:RemoveCard(card : Card) : Card
    for i : number, c : Card in ipairs(self.cards) do
        if c == card then
            table.remove(self.cards, i);
            break;
        end
    end

    return card;
end

function Hand:LockCards(cards : {Card}) : nil
    for _, card : Card in pairs(cards) do
        table.insert(self.lockedCards, card);
    end
end

function Hand:AsTable() : {table}
    local result : {table} = {};

    for _, card : Card in pairs(self.cards) do
        table.insert(result, card:AsTable());
    end

    return result;
end


local function findPair(cards : {Card}) : {number}
    local pairFound : boolean = false;
    local pairIndex1 : number, pairIndex2 : number = 0, 0;
    
    for i : number, card : Card in pairs(cards) do
        for j : number, otherCard : Card in pairs(cards) do
            if i ~= j and card == otherCard then
                pairIndex1, pairIndex2 = i, j;
                pairFound = true;
                break;
            end
        end
    end

    if pairFound then
        return {pairIndex1, pairIndex2};
    else
        return nil;
    end
end

local function findDragon(cards : {Card}) : number
    local dragonFound = false;
    local dragonSuit = nil;

    --| Search for consecutive 1-9 of a suit (already sorted by suit then number)
    for i : number = 1, #cards - 8 do
        local firstCard : Card = cards[i];

        if firstCard.value == 1 then
            for j : number = 1, 8 do
                local nextCard : Card = cards[i + j];
                if firstCard.suit ~= nextCard.suit or firstCard.value ~= nextCard.value - j then
                    break;
                end

                if j == 8 then
                    dragonFound = true;
                    dragonSuit = firstCard.suit;
                end
            end
        end
    end

    if dragonFound then
        return dragonSuit;
    else
        return nil;
    end
end

local function findSet(cards : {Card}) : {number}
    local setFound : boolean = false;
    local matches : number = 0;
    local matchIndices : {number} = {};

    --| Check for three/four of a kind

    for i : number, card : Card in pairs(cards) do
        table.insert(matchIndices, i);

        for j : number, otherCard : Card in pairs(cards) do
            if not table.find(matchIndices, j) and card == otherCard then
                table.insert(matchIndices, j);
                matches += 1;
            end
        end

        if matches > 2 then
            setFound = true;
            break;
        else
            matches = 0;
            table.clear(matchIndices);
        end
    end

    --| Check for consecutive runs (already sorted by suit then number)

    for i : number = 1, #cards - 2 do
        local card1 : Card = cards[i];
        local card2 : Card = cards[i + 1];
        local card3 : Card = cards[i + 2];

        if card1.suit == card2.suit and card2.suit == card3.suit then
            if card1.value == card2.value - 1 and card2.value == card3.value - 1 then
                matchIndices = {i, i + 1, i + 2};
                setFound = true;
                break;
            end
        end
    end


    if setFound then
        return matchIndices;
    else
        return nil;
    end
end

local function thirteenOrphans(cards : {Card})
    local requiredCards : {} = {
        Card.new("baiban"), Card.new("bei"), Card.new("dong"), Card.new("nan"), Card.new("xi"), Card.new("fa"), Card.new("zhong"),
        Card.new("dot", 1), Card.new("dot", 9),
        Card.new("snake", 1), Card.new("snake", 9),
        Card.new("wan", 1), Card.new("wan", 9)
    };

    for _, requiredCard : Card in pairs(requiredCards) do
        local found : boolean = false;

        for _, card : Card in pairs(cards) do
            if card == requiredCard then
                found = true;
                break;
            end
        end

        if not found then
            return false;
        end
    end

    if findPair(cards) == nil then
        return false;
    end

    return true;
end


function Hand:HasWon() : table
    local cardsCopy : {Card} = table.clone(self.cards);

    --| First check for 13 orphans

    if #cardsCopy == 14 and thirteenOrphans(cardsCopy) then
        return {true, "Win by 13 orphans!"};
    end

    --| First check for a pair

    local foundPair : {number} = findPair(cardsCopy);
    local numPairs : number = 0;

    if foundPair == nil then
        return {false, "No pair found"};
    end

    numPairs += 1;
    table.remove(cardsCopy, math.max(foundPair[1], foundPair[2]));
    table.remove(cardsCopy, math.min(foundPair[1], foundPair[2]));


    local foundDragon : string = findDragon(cardsCopy);

    if foundDragon then
        for i : number, card : Card in pairs(cardsCopy) do
            if card.suit == foundDragon then
                table.remove(cardsCopy, i);
            end
        end
    end

    --| Next, check for 4 sets of three (or just one if there's a dragon)
    local foundSets : number = 0;

    while #cardsCopy > 0 do
        local foundSet : {number} = findSet(cardsCopy);

        if foundSet == nil then
            return {false, "Not all sets found"};
        end

        table.remove(cardsCopy, math.max(foundSet[1], foundSet[2], foundSet[3]));
        table.remove(cardsCopy, math.median(foundSet[1], foundSet[2], foundSet[3]));
        table.remove(cardsCopy, math.min(foundSet[1], foundSet[2], foundSet[3]));

        foundSets += 1;
    end

    --| If no dragon and no sets, check for 7 pairs

    while #cardsCopy > 0 do
        foundPair = findPair(cardsCopy);

        if foundPair == nil then
            return {false, "Not all pairs found"};
        end

        table.remove(cardsCopy, math.max(foundPair[1], foundPair[2]));
        table.remove(cardsCopy, math.min(foundPair[1], foundPair[2]));

        numPairs += 1;
    end

    --| Determine win condition

    if foundDragon then
        return {true, "Win with a dragon!"};
    elseif foundSets == 4 then
        return {true, "Win by 4 sets and pair!"};
    elseif numPairs == 7 then
        return {true, "Win by 7 pairs!"};
    else
        return {false, "Unknown win condition"};
    end
end


function Hand:CanPeng(card : Card) : boolean
    local count : number = 0;
    for i : number, c : Card in ipairs(self.cards) do
        if c == card then
            count += 1;
        end
    end

    return count == 2;
end

function Hand:CanGang(card : Card) : boolean
    local count : number = 0;
    for i : number, c : Card in ipairs(self.cards) do
        if c == card then
            count += 1;
        end
    end

    return count == 3;
end

function Hand:CanChi(card : Card) : boolean
    if not table.find(suits, card.suit) then
        return false;
    end

    local firstCons : Card = nil;
    local firstIsLower : boolean = false;

    for i : number, c : Card in ipairs(self.cards) do
        if c.suit == card.suit then
            if c.value == card.value - 1 then
                firstIsLower = true;
            elseif c.value == card.value + 1 then
                firstIsLower = false;
            else
                continue;
            end

            firstCons = c;
            break;
        end
    end

    local secondCons : Card = nil;

    for i : number, c : Card in ipairs(self.cards) do
        if c.suit == card.suit then
            if firstIsLower and (c.value == card.value + 1 or c.value == card.value - 2) then
                secondCons = c;
                break;
            elseif not firstIsLower and (c.value == card.value - 1 or c.value == card.value + 2) then
                secondCons = c;
                break;
            end
        end
    end

    return firstCons ~= nil and secondCons ~= nil;
end

function Hand:CanAnGang() : boolean
    for i, card : Card in ipairs(self.cards) do
        local count = 0;

        for j, otherCard : Card in ipairs(self.cards) do
            if card == otherCard then
                count += 1;
            end
        end

        if count == 4 then
            return true;
        end
    end

    return false;
end



local Deck : Deck = {};

export type Deck = {
    ["cards"] : {Card},

    ["new"] : () -> Deck,
    ["Draw"] : () -> Card
}

--| Generates a new random full deck
function Deck.new() : Deck
    local self = setmetatable({}, {
        ["__index"] = Deck
    });
    
    local cards : Card = {};
    
    for i, suit in pairs(faceCards) do
        for _ = 0, 3 do
            table.insert(cards, Card.new(suit, 0));
        end
    end

    for i, suit in pairs(suits) do
        for value = 1, 9 do
            for _ = 0, 3 do
                table.insert(cards, Card.new(suit, value));
            end
        end
    end

    self.cards = {};

    while #cards > 0 do
        local randomIndex : number = math.random(1, #cards);
        table.insert(self.cards, cards[randomIndex]);
        table.remove(cards, randomIndex);
    end

    return self;
end

function Deck:Draw() : Card
    return table.remove(self.cards, 1);
end

local Mahjong : table = {
    ["Card"] = Card,
    ["Hand"] = Hand,
    ["Deck"] = Deck
};

return Mahjong;