local ContentProvider : ContentProvider = game:GetService("ContentProvider");

local crashfish = script.Parent.CrashfishJumpscare;
local tangerine = script.Parent["a charade of shadeless ones and zeros rearranged ad nihilum"];
local tangyinverted = script.Parent.theShatteringCircle;

ContentProvider:PreloadAsync({crashfish, tangerine, tangyinverted});

task.spawn(function() : nil
    while true do
        task.wait(20);
        local rand = math.random();

        if rand < 0.01 then
            crashfish.church_bell:Play();
            crashfish.Visible = true;
            task.wait(0.2);
            crashfish.Visible = false;
        end
    end
end);

task.spawn(function() : nil
    while true do
        task.wait(10);
        local rand = math.random();

        if rand < 0.00027 then
            tangerine.church_bell:Play();
            tangerine.Visible = true;
            for i = 1, 100 do
                tangyinverted.Visible = true;
                task.wait(0.01);
                tangyinverted.Visible = false;
            end
            tangerine.Visible = false;
        end
    end
end);