local ReplicatedStorage : ReplicatedStorage = game:GetService("ReplicatedStorage");
local Players : Players = game:GetService("Players");

local PlayerGui : PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui");
local MahjongUI : ScreenGui = PlayerGui:WaitForChild("Mahjong");
local hud : ScreenGui = PlayerGui:WaitForChild("HUD");



--[[

Card drag/resorting

]]--

local yourHand : Frame = MahjongUI:WaitForChild("YourHand");
local dragConnections : {RBXScriptConnection} = {};

local function onDragStart()
    for _, card : Frame in pairs(yourHand:GetChildren()) do
        if not card:IsA("Frame") then continue end
        if card.Name == "DraggableCardTemplate" then continue end

        card.Position = UDim2.new(0, card.AbsolutePosition.X, 0, 0);
        card.DragPos.Value = card.AbsolutePosition.X;
    end

    local listLayout : UIListLayout = yourHand:FindFirstChildOfClass("UIListLayout");
    listLayout:Destroy();
end

local function onDragContinue(delta : number, card : Frame)
    card.Position = UDim2.new(0, card.DragPos.Value + delta.X.Offset, 0, 0);
end

local function regenListLayout()
    local listLayout : UIListLayout = Instance.new("UIListLayout");
    listLayout.FillDirection = Enum.FillDirection.Horizontal;
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder;
    listLayout.Padding = UDim.new(0, 5);
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center;
    listLayout.Parent = yourHand;
end

local function onDragEnd()
    local cards = {};

    for _, card : Frame in pairs(yourHand:GetChildren()) do
        if not card:IsA("Frame") then continue end
        if card.Name == "DraggableCardTemplate" then continue end

        table.insert(cards, card);
    end

    table.sort(cards, function(a, b)
        return a.AbsolutePosition.X < b.AbsolutePosition.X;
    end);

    for i, card : Frame in ipairs(cards) do
        card.LayoutOrder = i - 1;
    end

    regenListLayout();
end

function initDrags() : nil
    for _, card : Frame in pairs(yourHand:GetChildren()) do
        if not card:IsA("Frame") then continue end
        if card.Name == "DraggableCardTemplate" then continue end

        local dragDetector = card:FindFirstChildOfClass("UIDragDetector");

        table.insert(dragConnections, dragDetector.DragStart:Connect(function() : nil
            onDragStart();
            card.ZIndex = 10;
        end));

        table.insert(dragConnections, dragDetector.DragContinue:Connect(function() : nil
            onDragContinue(dragDetector.DragUDim2, card);
        end));

        table.insert(dragConnections, dragDetector.DragEnd:Connect(function() : nil
            onDragEnd();
            card.ZIndex = 0;
        end));
    end
end

function clearDrags() : nil
    for _, connection : RBXScriptConnection in pairs(dragConnections) do
        connection:Disconnect();
    end

    dragConnections = {};
end



--[[

Event handling

]]--

local centreUI = MahjongUI:WaitForChild("Centre");

local remoteEvent : RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvents").Mahjong.RemoteEvent;
local remoteFunction : RemoteFunction = ReplicatedStorage.RemoteEvents.Mahjong.RemoteFunction;

local turnEvent : BindableEvent = Instance.new("BindableEvent");
local interruptEvent : BindableEvent = Instance.new("BindableEvent");

local playerBoxMap : {Frame} = {};

local buttonConnections : {RBXScriptConnection} = {
    ["Peng"] = nil,
    ["Gang"] = nil,
    ["Chi"] = nil,
    ["Draw"] = nil,
    ["AnGang"] = nil
};

local function addCardToHand(cardData : table, i : number) : nil
    local card : Frame = yourHand:FindFirstChild("DraggableCardTemplate"):Clone();
    card.Name = cardData.suit .. tostring(cardData.value);
    card.ImageLabel.Image = cardData.image;
    card.Parent = yourHand;

    card.Size = UDim2.new(1, 0, 1, 0);
    card.Visible = true;
    card.LayoutOrder = i;
end

function disableActionButtons() : nil
    for _, connection : RBXScriptConnection in pairs(buttonConnections) do
        if connection then
            connection:Disconnect();
        end
    end

    for _, button : TextButton in pairs(centreUI.TurnAction:GetChildren()) do
        if not button:IsA("TextButton") then continue end

        button.BackgroundTransparency = 0.75;
        button.TextTransparency = 0.5;
        button.Active = false;
    end
end

function enableActionButton(action : string, callback : () -> nil) : nil
    local button : TextButton = MahjongUI:WaitForChild("Centre").TurnAction:FindFirstChild(action);
    if not button then warn("Button " .. action .. " not found") return end

    button.BackgroundTransparency = 0.25;
    button.TextTransparency = 0;
    button.Active = true;

    buttonConnections[action] = button.MouseButton1Click:Connect(callback);
end

local function myTurn(availableActions : {string})

    for _, action : string in pairs(availableActions) do
        enableActionButton(action, function() : nil
            local newCards : table, tookFromDiscard : boolean = remoteFunction:InvokeServer(action);
            for _, cardData : table in pairs(newCards) do
                addCardToHand(cardData, 0);
            end

            if tookFromDiscard then
                updateDiscard("", "");
            end

            disableActionButtons();

            print("fired turn action")
            turnEvent:Fire();
        end);
    end

    interruptEvent.Event:Once(function() : nil
        disableActionButtons();
        return;
    end);

    if (#availableActions > 0) then
        print("turn action completed, moving to discard")
        turnEvent.Event:Wait();
    end

    MahjongUI.Message.Text = "Choose a card to discard";

    local clickConnections : {RBXScriptConnection} = {};

    clearDrags();

    for _, card : Frame in pairs(yourHand:GetChildren()) do
        if not card:IsA("Frame") then continue end
        if card.Name == "DraggableCardTemplate" then continue end

        table.insert(clickConnections, card.InputEnded:Connect(function(input : InputObject)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                remoteEvent:FireServer("discard", card.Name);

                card:Destroy();
                MahjongUI.Message.Text = "";
                
                initDrags();

                for _, connection : RBXScriptConnection in pairs(clickConnections) do
                    connection:Disconnect();
                end
            end
        end));
    end
end

local function initializeUI(data : {table}) : nil
    local handData : {table} = data.hand;

    --| Add cards to UI
    for i, cardData : table in ipairs(handData) do
        addCardToHand(cardData, i);
    end

    local mySeatNumber : number = -1;

    for _, seat : Seat in pairs(workspace:FindFirstChild("MahjongTable").Seats:GetChildren()) do
        if seat.Occupant and seat.Occupant.Parent.Name == Players.LocalPlayer.Name then
            mySeatNumber = tonumber(string.sub(seat.Name, 5, 6));
            break;
        end
    end


    --| Add cards to other player boxes
    for _, player : string in pairs(data.players) do
        if player == Players.LocalPlayer.Name then continue end

        local theirSeatNumber : number = -1;

        for _, seat : Seat in pairs(workspace:FindFirstChild("MahjongTable").Seats:GetChildren()) do
            if seat.Occupant and seat.Occupant.Parent.Name == player then
                theirSeatNumber = tonumber(string.sub(seat.Name, 5, 6));
                break;
            end
        end

        local seatNumDiff = theirSeatNumber - mySeatNumber;

        local playerBox : Frame = nil;

        if seatNumDiff == 1 then
            playerBox = MahjongUI:WaitForChild("RightHand");
        elseif seatNumDiff == 2 or seatNumDiff == -2 then
            playerBox = MahjongUI:WaitForChild("AcrossHand");
        elseif seatNumDiff == -1 then
            playerBox = MahjongUI:WaitForChild("LeftHand");
        else
            warn("Invalid seat number difference: " .. seatNumDiff);
            continue;
        end

        playerBoxMap[player] = playerBox;

        local cardCount : number = 13;
        if player == data.dealer then
            cardCount = 14;
        end

        for i = 1, cardCount do
            local card : Frame = playerBox:FindFirstChild("CardTopTemplate"):Clone();
            card.Name = "Card";
            card.Parent = playerBox;

            card.Size = UDim2.new(1, 0, 1, 0);
            card.Visible = true;
            card.LayoutOrder = i - 1
        end
        
    end

    MahjongUI.Enabled = true;
    hud.Enabled = false;

    if Players.LocalPlayer.Name == data.dealer then
        myTurn({});
    end
end

function updateDiscard(player : string, discard : string)
    print("discarding from player " .. player)
    if not centreUI.TurnAction.DisplayCard.Visible and discard then
        centreUI.TurnAction.DisplayCard.Visible = true;
    end

    if discard == "" then
        centreUI.TurnAction.DisplayCard.Visible = false;
        centreUI.TurnAction.DisplayCard.ImageLabel.Image = "";
    else
        centreUI.TurnAction.DisplayCard.ImageLabel.Image = discard;
    end

    if player ~= "" and player ~= Players.LocalPlayer.Name then
        playerBoxMap[player]:FindFirstChild("Card"):Destroy();
    end
end


local function cleanupUI()
    for _, child : Instance in pairs(yourHand:GetChildren()) do
        if child:IsA("Frame") and child.Name ~= "DraggableCardTemplate" then
            child:Destroy();
        end
    end

    for _, playerBox : Frame in pairs(playerBoxMap) do
        if not playerBox then continue end

        for _, child : Instance in pairs(playerBox:GetChildren()) do
            if child:IsA("Frame") and child.Name ~= "CardTopTemplate" then
                child:Destroy();
            end
        end
    end

    for _, child : Instance in pairs(centreUI.Discard:GetChildren()) do
        if child:IsA("Frame") and child.Name ~= "CardTemplate" then
            child:Destroy();
        end
    end

    centreUI.TurnAction.DisplayCard.ImageLabel.Image = "";
    centreUI.TurnAction.DisplayCard.Visible = false;
    centreUI.TurnAction.DisplayCard.Card.Value = "";

    disableActionButtons();
    clearDrags();

    MahjongUI.Enabled = false;
    hud.Enabled = true;
end

local function handleRemoteEvent(action : string, data : any)
    print(action);
    print(data);
    if action == "init" then
        print("initializing UI with data: " .. tostring(data));
        initializeUI(data);
    elseif action == "discard" then
        updateDiscard(data.player, data.card);
    elseif action == "turn" then
        if #data > 0 then
            myTurn(data);
        end
    elseif action == "turnStolen" then

    end
end


remoteEvent.OnClientEvent:Connect(handleRemoteEvent);