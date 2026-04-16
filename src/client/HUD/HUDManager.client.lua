local TweenService : TweenService = game:GetService("TweenService");
local UserInputService : UserInputService = game:GetService("UserInputService");
local ReplicatedStorage : ReplicatedStorage = game:GetService("ReplicatedStorage");
local SoundService : SoundService = game:GetService("SoundService");
local Players : Players = game:GetService("Players");


local hudGUI : ScreenGui = script.Parent;
local player = Players.LocalPlayer
local playerData = player:WaitForChild("Data");

for _, button : ImageButton in pairs(hudGUI.Buttons:GetChildren()) do
    if (button:IsA("ImageButton")) then
        button.MouseEnter:Connect(function() : nil
            TweenService:Create(button.Hover, TweenInfo.new(0.25), {["BackgroundTransparency"] = 0.25, ["TextTransparency"] = 0}):Play();
        end);
        
        button.MouseLeave:Connect(function() : nil
            TweenService:Create(button.Hover, TweenInfo.new(0.25), {["BackgroundTransparency"] = 1, ["TextTransparency"] = 1}):Play();
        end);

        button.MouseButton1Click:Connect(function() : nil
            button.BackgroundColor3 = Color3.fromRGB(37, 48, 92);
            TweenService:Create(button, TweenInfo.new(0.25), {["BackgroundColor3"] = Color3.fromRGB(18, 23, 43)}):Play();
        end);
    end
end


--| Spawn sled

function spawnSled() : nil
    local sledName = playerData.sledConfig.sledType.Value;
	ReplicatedStorage.RemoteEvents.SpawnSled:FireServer(sledName);
end

hudGUI.Buttons.Spawn.MouseButton1Click:Connect(spawnSled);


--| Settings

function toggleSettings() : nil
    hudGUI.Settings.Visible = not hudGUI.Settings.Visible;
end

hudGUI.Buttons.Settings.MouseButton1Click:Connect(toggleSettings);


--| Map




--| Spectate


--| Flashlight

function toggleFlashlight() : nil
    ReplicatedStorage.RemoteEvents.FlashlightToggle:FireServer();
end

hudGUI.Buttons.Flashlight.MouseButton1Click:Connect(toggleFlashlight);


--| Keystrokes

function toggleKeystrokes() : nil
    hudGUI.Keystrokes.Visible = not hudGUI.Keystrokes.Visible;
end

hudGUI.Buttons.Keystrokes.MouseButton1Click:Connect(toggleKeystrokes);


--| Terminal

function toggleTerminal() : nil
    hudGUI.Terminal.Visible = not hudGUI.Terminal.Visible;
end

hudGUI.Buttons.Terminal.MouseButton1Click:Connect(toggleTerminal);

--| Keyboard shortcuts

UserInputService.InputEnded:Connect(function(input : InputObject, gameProcessedEvent : boolean)
    if (not gameProcessedEvent) then
        if (input.KeyCode == Enum.KeyCode.V) then
            spawnSled();
        elseif (input.KeyCode == Enum.KeyCode.N) then
            toggleSettings();
        elseif (input.KeyCode == Enum.KeyCode.L) then
            toggleFlashlight();
        elseif (input.KeyCode == Enum.KeyCode.Semicolon) then
            toggleKeystrokes();
        elseif (input.KeyCode == Enum.KeyCode.BackSlash) then
            toggleTerminal();
        end
    end
end)


--| Level

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