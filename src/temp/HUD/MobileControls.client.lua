local UserInputService : UserInputService = game:GetService("UserInputService");

if (UserInputService.TouchEnabled) then
    print("mobile detected")
    local mobileControls : Frame = script.Parent;
    local joysticks : Frame = mobileControls.Joysticks;
    local camera : Camera = workspace.CurrentCamera;

    local grabbingMJoystick = false;
    local grabbingTJoystick = false;

    --| Detect if touch position is in the joystick areas
    local function touchInJoystickBounds(joystick : Frame, touchPosition : Vector2) : boolean
        local inXBounds = (joystick.AbsolutePosition.X < touchPosition.X) and (touchPosition.X < (joystick.AbsolutePosition.X + joystick.AbsoluteSize.X));
        local inYBounds = (joystick.AbsolutePosition.Y < touchPosition.Y) and (touchPosition.Y < (joystick.AbsolutePosition.Y + joystick.AbsoluteSize.Y));

        return (inXBounds and inYBounds);
    end

    --| Move joystick anchor towards thumb
    local function joystickAnchorToPos(joystickAnchor : Frame, position : Vector2) : nil
       local joystickCentre : Vector2 = Vector2.new(joystickAnchor.Parent.AbsolutePosition + joystickAnchor.Parent.AbsoluteSize * 2)

       --| Calculate position
       local offsetUnit : Vector2 = (position - joystickCentre) / joystickAnchor.Parent.AbsoluteSize;
       local magnitude : number = math.clamp(offsetUnit.Magnitude, 0, 1);
       local angle : number =  math.tan(offsetUnit.Y / offsetUnit.X);
       local anchorPos : Vector2= Vector2.new(magnitude * math.cos(angle), magnitude * math.sin(angle));

        joystickAnchor.Position = UDim2.new(0.5 + anchorPos.X, 0, 0.5 + anchorPos.Y, 0);
    end


    UserInputService.TouchStarted:Connect(function(touch : InputObject, gameProcessedEvent : boolean)
        if (not gameProcessedEvent) then
            local touchPosition : Vector2 = Vector2.new(touch.Position.X, touch.Position.Y);

            if (touchInJoystickBounds(joysticks.Movement, touchPosition)) then
                joystickAnchorToPos(joysticks.Movement, touchPosition);
                grabbingMJoystick = true;
            end
        end
    end);

    UserInputService.TouchMoved:Connect(function(touch : InputObject, gameProcessedEvent : boolean)
        if (not gameProcessedEvent) then
            local touchPosition : Vector2 = Vector2.new(touch.Position.X, touch.Position.Y);

            if (touchPosition.Y < (camera.ViewportSize.Y / 2)) then
                if (grabbingMJoystick) then
                    joystickAnchorToPos(joysticks.Movement, touchPosition);
                end
            else
                if (grabbingTJoystick) then
                    joystickAnchorToPos(joysticks.Tilt, touchPosition);
                end
            end
        end
    end);

    UserInputService.TouchEnabled:Connect(function(touch : InputObject, gameProcessedEvent : boolean)
        if (not gameProcessedEvent) then
            local touchPosition : Vector2 = Vector2.new(touch.Position.X, touch.Position.Y);

            if (touchPosition.Y < (camera.ViewportSize.Y / 2)) then
                if (grabbingMJoystick) then
                    grabbingMJoystick = false;
                    joystickAnchorToPos(joysticks.Movement, Vector2.new(joysticks.Movement.AbsolutePosition + joysticks.Movement.AbsoluteSize * 2));
                end
            else
                if (grabbingTJoystick) then
                    grabbingTJoystick = false;
                    joystickAnchorToPos(joysticks.Tilt, Vector2.new(joysticks.Tilt.AbsolutePosition + joysticks.Tilt.AbsoluteSize * 2));
                end
            end

        end
    end);
end
