local TweenService : TweenService = game:GetService("TweenService");
local UserInputService : UserInputService = game:GetService("UserInputService");
local ReplicatedStorage : ReplicatedStorage = game:GetService("ReplicatedStorage");
local SoundService : SoundService = game:GetService("SoundService");
local RunService : RunService = game:GetService("RunService");
local Players : Players = game:GetService("Players");
local UserService : UserService = game:GetService("UserService");


local hudGUI : ScreenGui = script.Parent;
local player = Players.LocalPlayer
local playerData = player:WaitForChild("Data");

--* Hover effects

--| makes object button.Hover fade in and out when hovering
function addHoverText(button : GuiButton) : nil
    button.MouseEnter:Connect(function() : nil
        TweenService:Create(button.Hover, TweenInfo.new(0.25), {["BackgroundTransparency"] = 0.25, ["TextTransparency"] = 0}):Play();
    end);
    
    button.MouseLeave:Connect(function() : nil
        TweenService:Create(button.Hover, TweenInfo.new(0.25), {["BackgroundTransparency"] = 1, ["TextTransparency"] = 1}):Play();
    end);
end

function addHoverLight(button : GuiButton) : nil
    button.MouseEnter:Connect(function() : nil
        TweenService:Create(button, TweenInfo.new(0.25), {["BackgroundColor3"] = Color3.fromRGB(37, 48, 92)}):Play();
    end);
    
    button.MouseLeave:Connect(function() : nil
        TweenService:Create(button, TweenInfo.new(0.25), {["BackgroundColor3"] = Color3.fromRGB(18, 23, 43)}):Play();
    end);

    button.MouseButton1Click:Connect(function() : nil
        button.BackgroundColor3 = Color3.fromRGB(37, 48, 92);
        TweenService:Create(button, TweenInfo.new(0.25), {["BackgroundColor3"] = Color3.fromRGB(18, 23, 43)}):Play();
    end);
end

for _, button : ImageButton in pairs(hudGUI.Buttons:GetChildren()) do
    if (button:IsA("ImageButton")) then
        addHoverLight(button);
        addHoverText(button);
    end
end

for _, obj : GuiObject in pairs(hudGUI.Map:GetChildren()) do
    if obj:IsA("GuiButton") then
        addHoverLight(obj);
    end
end


--* Spawn sled

function spawnSled() : nil
    local sledName = playerData.sledConfig.sledType.Value;
	ReplicatedStorage.RemoteEvents.SpawnSled:FireServer(sledName);
end

hudGUI.Buttons.Spawn.MouseButton1Click:Connect(spawnSled);


--* Settings

function toggleSettings() : nil
    hudGUI.Settings.Visible = not hudGUI.Settings.Visible;
end

hudGUI.Buttons.Settings.MouseButton1Click:Connect(toggleSettings);


--* Map

local camera = workspace.CurrentCamera;

local mapParts = workspace:WaitForChild("MapParts");
local curMapIndex = 0;
local camHeartBeat : RBXScriptConnection = nil;

function getMapInfos(index : number) : (string, BasePart, BasePart)
    local camName : string = "";
    local camPart : BasePart = nil;
    local tpPart : BasePart = nil;

    for _, part : BasePart in pairs(mapParts:GetChildren()) do
        if (part:GetAttribute("CamIndex") == index) then
            if (part:GetAttribute("CamPartType") == "cam") then
                camPart = part;
                elseif (part:GetAttribute("CamPartType") == "tp") then
                camName = part:GetAttribute("CamName");
                tpPart = part;
            end
        end
    end

    return camName, camPart, tpPart;
end

local curName, targetCamPart, targetTpPart : BasePart = getMapInfos(curMapIndex);

function toggleMap() : nil
    if hudGUI.Map.Visible == true then
        hudGUI.Map.Visible = false;
        
        if camHeartBeat then
            camHeartBeat:Disconnect();
        end
        
        camera.CameraType = Enum.CameraType.Custom;

        ReplicatedStorage.LocalEvents.POVCamOverride:Fire(false);
    else
        ReplicatedStorage.LocalEvents.POVCamOverride:Fire(true);
        updateMapHUD();
        hudGUI.Map.Visible = true;

        camHeartBeat = RunService.Heartbeat:Connect(function() : nil
            camera.CameraType = Enum.CameraType.Scriptable;
            if targetCamPart and targetTpPart then
                camera.CFrame = targetCamPart.CFrame;
            end
        end);
    end
end

function updateMapHUD() : nil
    curName, targetCamPart, targetTpPart = getMapInfos(curMapIndex);
    hudGUI.Map.Location.Text = curName;
end

function moveLeft() : nil
    if curMapIndex > 0 then
        curMapIndex -= 1;
    else
        curMapIndex = #mapParts:GetChildren() / 2 - 1;
    end

    updateMapHUD();
end

function moveRight() : nil
    if curMapIndex < #mapParts:GetChildren() / 2 - 1 then
        curMapIndex += 1;
    else
        curMapIndex = 0;
    end

    updateMapHUD();
end

function teleport() : nil
    player.Character.Humanoid.Sit = false;
    player.Character:PivotTo(targetTpPart.CFrame);
    toggleMap();
end

hudGUI.Buttons.Map.MouseButton1Click:Connect(toggleMap);
hudGUI.Map.Left.MouseButton1Click:Connect(moveLeft);
hudGUI.Map.Right.MouseButton1Click:Connect(moveRight);
hudGUI.Map.Teleport.MouseButton1Click:Connect(teleport);


--* Spectate

local spectating = false;

function spectate(p : Player) : nil
    print("spectating " .. p.Name);
    if not spectating then
        ReplicatedStorage.LocalEvents.POVCamOverride:Fire(true);
        spectating = true;
    end

    local char = p.Character or p.CharacterAdded:Wait();
    camera.CameraSubject = char:FindFirstChildWhichIsA("Humanoid");
end

function stopSpectating() : nil
    camera.CameraSubject = player.Character:FindFirstChildWhichIsA("Humanoid");
    ReplicatedStorage.LocalEvents.POVCamOverride:Fire(false);
    spectating = false;
end

function checkEmpty() : nil
    if #Players:GetPlayers() == 1 then
        hudGUI.Spectate.Container._NoPlayers.Size = UDim2.new(1, 0, 0.2, 0)
    end
end

function addSpecButton(p : Player) : nil
    if hudGUI.Spectate.Container._NoPlayers.Size == UDim2.new(1, 0, 0.2, 0) then
        hudGUI.Spectate.Container._NoPlayers.Size = UDim2.new(1, 0, 0, 0)
    end

    local newButton : TextButton = hudGUI.Spectate.Container._Template:Clone();
    newButton.Name = p.Name;
    newButton.Parent = hudGUI.Spectate.Container;
    newButton.Text = p.Name;
    newButton.Size = UDim2.new(1, 0, 0.2, 0);

    newButton.MouseButton1Click:Connect(function() : nil
        spectate(p);
    end);

    local userInfo : table = nil;
    local success, err = pcall(function() : nil
        userInfo = UserService:GetUserInfosByUserIdsAsync({p.UserId});
    end);

    if success and userInfo[1].DisplayName then
        newButton.Text = userInfo[1].DisplayName;
    else
        warn("Could not get and assign UserInfos for player " .. p.Name);
        warn("Associated error: " .. tostring(err));
    end

    addHoverLight(newButton);
end

function removeSpecButton(p : Player) : nil
    if p == player then return; end
    hudGUI.Spectate.Container:FindFirstChild(p.Name):Destroy();

    checkEmpty();
end

function toggleSpectate() : nil
    hudGUI.Spectate.Visible = not hudGUI.Spectate.Visible;
end

for _, p in pairs(Players:GetPlayers()) do
    if p == player then continue; end
    addSpecButton(p);
end

addHoverLight(hudGUI.Spectate.Stop);

Players.PlayerAdded:Connect(addSpecButton);
Players.PlayerRemoving:Connect(removeSpecButton);
hudGUI.Spectate.Stop.MouseButton1Click:Connect(stopSpectating)
hudGUI.Buttons.Spectate.MouseButton1Click:Connect(toggleSpectate);

--* Flashlight

function toggleFlashlight() : nil
    ReplicatedStorage.RemoteEvents.FlashlightToggle:FireServer();
end

hudGUI.Buttons.Flashlight.MouseButton1Click:Connect(toggleFlashlight);


--* Keystrokes

function toggleKeystrokes() : nil
    hudGUI.Keystrokes.Visible = not hudGUI.Keystrokes.Visible;
end

hudGUI.Buttons.Keystrokes.MouseButton1Click:Connect(toggleKeystrokes);


--* Terminal

function toggleTerminal() : nil
    hudGUI.Terminal.Visible = not hudGUI.Terminal.Visible;
end

hudGUI.Buttons.Terminal.MouseButton1Click:Connect(toggleTerminal);

--* Keyboard shortcuts

UserInputService.InputEnded:Connect(function(input : InputObject, gameProcessedEvent : boolean)
    if (not gameProcessedEvent) then
        if (input.KeyCode == Enum.KeyCode.V) then
            spawnSled();
        elseif (input.KeyCode == Enum.KeyCode.N) then
            toggleSettings();
        elseif (input.KeyCode == Enum.KeyCode.B) then
            toggleSpectate();
        elseif (input.KeyCode == Enum.KeyCode.M) then
            toggleMap();
        elseif (input.KeyCode == Enum.KeyCode.L) then
            toggleFlashlight();
        elseif (input.KeyCode == Enum.KeyCode.Semicolon) then
            toggleKeystrokes();
        elseif (input.KeyCode == Enum.KeyCode.BackSlash) then
            toggleTerminal();
        end
    end
end)


--* Level

local playerLevel : number = playerData.playerstats.level;
local playerXP : number = playerData.playerstats.xp;
local currentLevel = playerLevel.Value;
local xpRequirement = require(ReplicatedStorage.Modules.sledutils).xpRequirement;

local levelUI : Frame = hudGUI.Level;
local levelupSound : Sound = levelUI.Levelup;

levelUI.Level.Text = "Level " .. playerLevel.Value;
levelUI.XP.Text = playerXP.Value .. "/" .. xpRequirement(playerLevel.Value);
levelUI.Bar.Fill.Size = UDim2.new(playerXP.Value / xpRequirement(playerLevel.Value), 0, 1, 0);

local function tweenXPBar(xpPercent : number) : nil
    TweenService:Create(levelUI.Bar.Fill, TweenInfo.new(0.5), {["Size"] = UDim2.new(xpPercent, 0, 1, 0)}):Play();
end

local function xpChanged() : nil
    if playerLevel.Value ~= currentLevel then return; end
    tweenXPBar(playerXP.Value / xpRequirement(playerLevel.Value));
    levelUI.XP.Text = playerXP.Value .. "/" .. xpRequirement(playerLevel.Value);
end

local function levelChanged() : nil
    local newLevel = playerLevel.Value;
    local newXP = playerXP.Value;

    for i = currentLevel, newLevel - 1 do
        tweenXPBar(1);
        levelUI.Level.Text = "Level " .. (i + 1);
        levelUI.XP.Text = xpRequirement(i) .. "/" .. xpRequirement(i);
        task.wait(0.5);
        levelUI.Bar.Fill.Size = UDim2.new(0, 0, 1, 0);
        SoundService:PlayLocalSound(levelupSound);
    end

    tweenXPBar(newXP / xpRequirement(newLevel));
    levelUI.Level.Text = "Level " .. newLevel;
    levelUI.XP.Text = newXP .. "/" .. xpRequirement(newLevel);
end

playerLevel:GetPropertyChangedSignal("Value"):Connect(levelChanged);
playerXP:GetPropertyChangedSignal("Value"):Connect(xpChanged);