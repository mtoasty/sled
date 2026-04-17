local Players : Players = game:GetService("Players");
local ReplicatedStorage : ReplicatedStorage = game:GetService("ReplicatedStorage");
local customizeUI : ScreenGui = script.Parent;

local player : Player = Players.LocalPlayer;
local playerControls = require(player.PlayerScripts.PlayerModule):GetControls();
local playerData : Folder = player:WaitForChild("Data", 10);

local TweenService : TweenService = game:GetService("TweenService");


--| UI Visibility

ReplicatedStorage.RemoteEvents.openCustomize.OnClientEvent:Connect(function() : nil
	customizeUI.Enabled = true;
	playerControls:Disable();

    --| Assure skins are unlocked on open
    for _, sledType : Frame in pairs(customizeUI.MainUI.SkinSelect:GetChildren()) do
        if (not sledType:IsA("Frame")) then continue; end

        if (player:GetRankInGroup(13628961) >= 254) then
            sledType.Button.Lock.Visible = false;
            sledType.Requirement.Visible = false;
            sledType.Button.ImageTransparency = 0;
            continue;
        end
        
        local requiredLevel : number = sledType:GetAttribute("requiredLevel");
        local requiresMoons : boolean = sledType:GetAttribute("moons");

        if (playerData.playerstats.Level >= requiredLevel) then
            if (requiresMoons == true) then
                local ds_id = sledType:GetAttribute("ds_id");
                if (playerData.sledConfig.cosmetics[ds_id] == true) then
                    sledType.Button.Lock.Visible = false;
                    sledType.Requirement.Visible = false;
                    sledType.Button.ImageTransparency = 0;
                end
            else
                sledType.Button.Lock.Visible = false;
                sledType.Requirement.Visible = false;
                sledType.Button.ImageTransparency = 0;
            end
        end
    end

    --| Set inputs to players current settings
    customizeUI.MainUI.Skin.Text = playerData.sledConfig.sledType.Value;
    customizeUI.MainUI.Colour.BackgroundColor3 = playerData.sledConfig.sledColour.Value;
    customizeUI.MainUI.SteerAngle.Text = playerData.sledConfig.steerAngle.Value;
    customizeUI.MainUI.SteerSpeed.Text = playerData.sledConfig.steerSpeed.Value;
    customizeUI.MainUI.RollMultiplier.Text = playerData.sledConfig.rollMult.Value;
    customizeUI.MainUI.PitchMultiplier.Text = playerData.sledConfig.pitchMult.Value;
    customizeUI.MainUI.YawStrength.Text = playerData.sledConfig.yawStrength.Value;
    customizeUI.MainUI.GyroStrength.Text = playerData.sledConfig.gyroStrength.Value;
end);


--| Close button

customizeUI.MainUI.Close.MouseButton1Click:Connect(function()
    customizeUI.Enabled = false;
    playerControls:Enable();
end)

customizeUI.MainUI.Close.MouseEnter:Connect(function() : nil
    TweenService:Create(customizeUI.MainUI.Close, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {["BackgroundColor3"] = Color3.fromRGB(29, 37, 70)}):Play();
end);

customizeUI.MainUI.Close.MouseLeave:Connect(function() : nil
    TweenService:Create(customizeUI.MainUI.Close, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {["BackgroundColor3"] = Color3.fromRGB(18, 23, 43)}):Play();
end);


--| Sled skin select:

for _, sledType : Frame in pairs(customizeUI.MainUI.SkinSelect:GetChildren()) do
    if (not sledType:IsA("Frame")) then continue; end

    --| Hover colour change:
    sledType.Button.MouseEnter:Connect(function() : nil
        TweenService:Create(sledType.Button, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {["BackgroundColor3"] = Color3.fromRGB(29, 37, 70)}):Play();
    end);

    sledType.Button.MouseLeave:Connect(function() : nil
        TweenService:Create(sledType.Button, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {["BackgroundColor3"] = Color3.fromRGB(18, 23, 43)}):Play();
    end);
    

    sledType.Button.MouseButton1Click:Connect(function() : nil
        if (player:GetRankInGroup(13628961) >= 254) then
            ReplicatedStorage.RemoteEvents.StatChange:FireServer("sledType", sledType.Name);
            customizeUI.MainUI.Skin.Text = sledType.Name;
            return;
        end
        
        local requiredLevel : number = sledType:GetAttribute("requiredLevel");
        local requiresMoons : boolean = sledType:GetAttribute("moons");
    
        if (playerData.playerstats.level.Value >= requiredLevel) then
            if (requiresMoons == true) then
                local ds_id = sledType:GetAttribute("ds_id");
                if (playerData.sledConfig.cosmetics[ds_id] == true) then
                    ReplicatedStorage.RemoteEvents.StatChange:FireServer("sledType", sledType.Name);
                    customizeUI.MainUI.Skin.Text = sledType.Name;
                end
            else
                ReplicatedStorage.RemoteEvents.StatChange:FireServer("sledType", sledType.Name);
                customizeUI.MainUI.Skin.Text = sledType.Name;
            end
        end
    end);
end


--| Color picking

local colourPickerManager = require(customizeUI.ColorPicker.ColorPickerManager);

customizeUI.MainUI.Colour.MouseButton1Click:Connect(function() : nil
    local newColour : Color3 = colourPickerManager:Prompt(customizeUI.MainUI.Colour.BackgroundColor3);
    if (newColour) then
        customizeUI.MainUI.Colour.BackgroundColor3 = newColour;
        ReplicatedStorage.RemoteEvents.StatChange:FireServer("sledColour", newColour);
    end
end);


--| Setting boxes

for _, inst : Instance in pairs(customizeUI.MainUI:GetChildren()) do
    if (inst:IsA("TextBox")) then
        inst.FocusLost:Connect(function() : nil

            local inputtedNumber : number = tonumber(inst.Text);
            local ds_id : string = inst:GetAttribute("ds_id");

            if (inputtedNumber ~= nil) then
                inputtedNumber = math.clamp(inputtedNumber, inst:GetAttribute("MinValue"), inst:GetAttribute("MaxValue"));
                ReplicatedStorage.RemoteEvents.StatChange:FireServer(ds_id, inputtedNumber);
                inst.Text = inputtedNumber;
            else
                inst.Text = playerData.sledConfig[ds_id].value;
            end
        end);
    end
end