local ReplicatedStorage : ReplicatedStorage = game:GetService("ReplicatedStorage");
local UserInputService : UserInputService = game:GetService("UserInputService");

local terminal = require(ReplicatedStorage.Modules.terminal.root);

local terminalWindow : Frame = script.Parent;
local root_terminal = terminal.new(terminalWindow);

function commandInputed(): nil
    root_terminal:InterpretCommand(terminalWindow.Input.Text);
    terminalWindow.Input:CaptureFocus();
    task.wait();
    terminalWindow.Input.Text = "";
end

UserInputService.InputBegan:Connect(function(input : InputObject, gameProcessedEvent : boolean)
    if (not gameProcessedEvent) then
        return;
    end

    if (input.KeyCode == Enum.KeyCode.Return) then
        commandInputed();
    end
end);

--| Server message:

function serverMessageRecieved(message: string, messageType: Enum.MessageType): nil
    if messageType == Enum.MessageType.MessageError then
        root_terminal:err(message, true);
    elseif messageType == Enum.MessageType.MessageWarning then
        root_terminal:warn(message, true);
    elseif messageType == Enum.MessageType.MessageInfo then
        root_terminal:log(message, true, Color3.fromRGB(150, 150, 150));
    elseif messageType == Enum.MessageType.MessageOutput then
        root_terminal:log(message, true);
    end
end

ReplicatedStorage.RemoteEvents.terminal.OnClientEvent:Connect(serverMessageRecieved);
