local Players : Players = game:GetService("Players");
local ReplicatedStorage : ReplicatedStorage = game:GetService("ReplicatedStorage");
local ReplicatedFirst : ReplicatedFirst = game:GetService("ReplicatedFirst");
local TweenService : TweenService = game:GetService("TweenService");
local ContentProvider : ContentProvider = game:GetService("ContentProvider");

local player : Player = Players.LocalPlayer;
local playerGui : PlayerGui = player:WaitForChild("PlayerGui");

local loadingScreen = ReplicatedFirst:WaitForChild("LoadingScreen");
loadingScreen.Parent = playerGui;

local loadingScreenImages = {loadingScreen.Image, loadingScreen.UI.AssetDownloadIcon, loadingScreen.UI.DataDownloadIcon, loadingScreen.UI.CompleteIcon}

ContentProvider:PreloadAsync(loadingScreenImages);

ReplicatedFirst:RemoveDefaultLoadingScreen();


local assetTable = workspace:GetDescendants();
for _, inst : Instance in pairs(game:GetService("Lighting"):GetDescendants()) do
    table.insert(assetTable, inst);
end

for _, inst : Instance in pairs(game:GetService("StarterGui"):GetDescendants()) do
    table.insert(assetTable, inst);
end

local totalAssets : number = #assetTable;
local assetsLoaded : number = 0;

ContentProvider:PreloadAsync(assetTable, function()
    assetsLoaded += 1;
    local percentLoaded = math.round((assetsLoaded / totalAssets) * 90);
    loadingScreen.UI.LoadingBar.Fill.Size = UDim2.new(percentLoaded / 100, 0, 1, 0); --| Cap at 90% and partition last 10% for data downloads
    loadingScreen.UI.Progress.Text = "(" .. percentLoaded .. "%)";
end);

print(assetsLoaded .. " out of " .. totalAssets .. " assets loaded");

loadingScreen.UI.Progress.Text = "(90%)";
TweenService:Create(loadingScreen.UI.LoadingBar.Fill, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {["Size"] = UDim2.new(0.9, 0, 1, 0)}):Play();

TweenService:Create(loadingScreen.UI.Process, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {["TextTransparency"] = 1}):Play();
TweenService:Create(loadingScreen.UI.AssetDownloadIcon, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {["ImageTransparency"] = 1}):Play();
task.wait(0.2);
loadingScreen.UI.Process.Text = "Downloading Data";
TweenService:Create(loadingScreen.UI.Process, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {["TextTransparency"] = 0}):Play();
TweenService:Create(loadingScreen.UI.DataDownloadIcon, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {["ImageTransparency"] = 0}):Play();

ReplicatedStorage.RemoteEvents.DataLoaded.OnClientEvent:Wait();

-- tween to 100%, change icon/text, wait a second, then fade out, tween loading bar

TweenService:Create(loadingScreen.UI.Process, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {["TextTransparency"] = 1}):Play();
TweenService:Create(loadingScreen.UI.DataDownloadIcon, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {["ImageTransparency"] = 1}):Play();
task.wait(0.2);
loadingScreen.UI.Process.Text = "Loading Complete";
TweenService:Create(loadingScreen.UI.Process, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {["TextTransparency"] = 0}):Play();
TweenService:Create(loadingScreen.UI.CompleteIcon, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {["ImageTransparency"] = 0}):Play();

loadingScreen.UI.Progress.Text = "(100%)";
TweenService:Create(loadingScreen.UI.LoadingBar.Fill, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {["Size"] = UDim2.new(1, 0, 1, 0)}):Play();

task.wait(1.5);


playerGui.ominousGUI.Enabled = true;

TweenService:Create(loadingScreen.Image, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {["ImageTransparency"] = 1}):Play();
TweenService:Create(loadingScreen.UI.LoadingBar, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {["BackgroundTransparency"] = 1}):Play();
TweenService:Create(loadingScreen.UI.LoadingBar.Fill, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {["BackgroundTransparency"] = 1}):Play();
TweenService:Create(loadingScreen.UI.Progress, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {["TextTransparency"] = 1}):Play();
TweenService:Create(loadingScreen.UI.Process, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {["TextTransparency"] = 1}):Play();
TweenService:Create(loadingScreen.UI.CompleteIcon, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {["ImageTransparency"] = 1}):Play();

task.wait(0.5);
loadingScreen:Destroy();

ReplicatedStorage.LocalEvents.LoadingScreen:Fire("complete");