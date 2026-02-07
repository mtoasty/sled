local ReplicatedStorage = game:GetService("ReplicatedStorage");
local LogService = game:GetService("LogService");

function pingTerminals(message: string, messageType: Enum.MessageType): nil
    if not string.find(message, "TextScraper text too long") then
        ReplicatedStorage.RemoteEvents.terminal:FireAllClients(message, messageType);
    end
end

LogService.MessageOut:Connect(pingTerminals);