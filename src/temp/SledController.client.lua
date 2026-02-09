--[[

determine a clean landing by getting percent of y velocity conserved on the landing

]]


local Players : Players = game:GetService("Players");
local RunService : RunService = game:GetService("RunService");
local TweenService : TweenService = game:GetService("TweenService");
local UserInputService : UserInputService = game:GetService("UserInputService");
local ContextActionService : ContextActionService = game:GetService("ContextActionService");

local LocalPlayer : Player = Players.LocalPlayer;
local character : Model = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait();
local humanoid : Humanoid = character:WaitForChild("Humanoid");
local camera : Camera = workspace.CurrentCamera;

local hud : ScreenGui = LocalPlayer:WaitForChild("PlayerGui").HUD;
local keystrokesUI : Frame = hud.Keystrokes;


local components : Folder | nil;
local heartbeatConnection : RBXScriptConnection | nil;
local cameraConnection : RBXScriptConnection | nil;

local playerSledConfig : Folder = LocalPlayer.Data.sledConfig;
local sledSettings = {
	["steerAngle"] = playerSledConfig.steerAngle,
	["steerSpeed"] = playerSledConfig.steerSpeed, --| Clamp between 0 and 1
    ["rollMult"] = playerSledConfig.rollMult,
    ["pitchMult"] = playerSledConfig.pitchMult,
    ["yawStrength"] = playerSledConfig.yawStrength,
    ["gyroStrength"] = playerSledConfig.gyroStrength
};


--| Camera managing


local currentCameraMode = 1;

function SwitchCameraMode(actionName : string, inputState : Enum.UserInputState, inputObject : InputObject) : nil
	if (inputState == Enum.UserInputState.Begin) then
		if currentCameraMode == 5 then
			currentCameraMode = 1;
		else
			currentCameraMode += 1;
		end
	end
end

function HideCharacter() : nil
	for _, v : Instance in pairs(character:GetDescendants()) do
		if (v.Name == "Head" or v.Name == "Torso" or v.Name == "Handle") then
			v.LocalTransparencyModifier = 1;
		end
	end
end

function ShowCharacter() : nil
	for _, v : Instance in pairs(character:GetDescendants()) do
		if (v:IsA("BasePart")) then
			v.LocalTransparencyModifier = 0;
		end
	end
end

function cameraDampOnInst(inst : BasePart, deltaTime : number) : nil
	local cameraDampGoal : BasePart = inst;
	camera.CameraType = Enum.CameraType.Scriptable;
	local step : number = 10 * deltaTime;

	local camRoation : CFrame = camera.CFrame.Rotation;
	local goalCFrame : CFrame = cameraDampGoal:GetPivot();
	local goalRotation : CFrame = goalCFrame.Rotation;

	local rotationLerpCFrame : CFrame = camRoation:Lerp(goalRotation, step);
	local finalCFrame : CFrame = (goalCFrame * goalRotation:Inverse()) * rotationLerpCFrame;
	camera.CFrame = finalCFrame;
end

function UpdateCamera(deltaTime : number) : nil

	--| Default
	if (currentCameraMode == 1) then
		camera.FieldOfView = 70;
		camera.CameraType = Enum.CameraType.Custom;
		ShowCharacter();
	end

	--| Damped rotation first person
	if (currentCameraMode == 2) then
		camera.FieldOfView = 90;
		HideCharacter();
		cameraDampOnInst(components.Cameras.FP, deltaTime);
	end

	--| Locked first person
	if (currentCameraMode == 3) then
		camera.FieldOfView = 90;
		camera.CFrame = components.Cameras.FP.CFrame;
	end

	--| Damped rotation third person
	if (currentCameraMode == 4) then
		camera.FieldOfView = 90;
		ShowCharacter();
		cameraDampOnInst(components.Cameras.TP, deltaTime);
	end

	--| Locked third person
	if (currentCameraMode == 5) then
		camera.FieldOfView = 90;
		ShowCharacter();
		camera.CFrame = components.Cameras.TP.CFrame;
	end

	--| FOV Scaling
	local velocity : number = components.VehicleSeat.AssemblyLinearVelocity.Magnitude;
	local currentFov : number = camera.FieldOfView;
	local targetFov = 0.2 * velocity + 90;
	camera.FieldOfView = currentFov + (targetFov - currentFov) * 0.95;
end




--| Sled physics


function boolToBit(b : boolean) : number
	if (b) then
		return 1;
	else
		return 0;
	end
end

function getKeyboardVector() : Vector2
    local uDown : boolean, hDown : boolean, jDown : boolean, kDown : boolean = UserInputService:IsKeyDown(Enum.KeyCode.U), UserInputService:IsKeyDown(Enum.KeyCode.H), UserInputService:IsKeyDown(Enum.KeyCode.J), UserInputService:IsKeyDown(Enum.KeyCode.K);
    return Vector2.new(boolToBit(uDown) - boolToBit(jDown), boolToBit(kDown) - boolToBit(hDown));
end

function getControllerVector() : Vector2
    local state : {InputObject} = UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1)
    for _, input : InputObject in pairs(state) do
        if (input.KeyCode == Enum.KeyCode.Thumbstick2) then
            return input.Position;
        end
    end
end

function getMobileVector() : Vector2
    return Vector2.new(0, 0);
end

function getTiltVector(inputMode : string) : Vector2 
	if (inputMode == "Auto") then
		return getKeyboardVector() + getControllerVector() + getMobileVector();
    elseif (inputMode == "Keyboard") then
        return getKeyboardVector();
    elseif (inputMode == "Controller" or inputMode == "VR") then
        return getControllerVector();
    elseif (inputMode == "Mobile") then
        return getMobileVector();
	end
end


--| Variable to save last particle size
local lastSprayValue : number = 0;
local sprayIncreasing : boolean = false;

--| Particle size calculator
local vToPSize = function(v : number) : number
	return math.max(math.tanh(0.02 * (v - 20)), 0);
end

function updateParticles(deltaTime : number, velocity : number) : nil
	--| Particle effects

	local velocityVector : Vector3 = components.VehicleSeat.AssemblyLinearVelocity;
	local directionVector : Vector3 = components.VehicleSeat.CFrame.LookVector;
	
	--| Normal particles
	local particleSize : NumberSequence = NumberSequence.new{
		NumberSequenceKeypoint.new(0.0, 1.25 * vToPSize(velocity)),
		NumberSequenceKeypoint.new(0.5, 4.10 * vToPSize(velocity)),
		NumberSequenceKeypoint.new(1.0, 10.0 * vToPSize(velocity))
	};
	
	--| Assign properties
	for _, particlePart : BasePart in pairs(components.ParticleParts:GetChildren()) do
		if (particlePart.Name == "SnowParticle") then
			particlePart.ParticleEmitter.Size = particleSize;
		end
	end

	--| Spray particles

	local sprayAngle : number = math.acos(velocityVector:Dot(directionVector) / (velocityVector.Magnitude * directionVector.Magnitude));
	if (sprayAngle > (math.pi / 2)) then
		sprayAngle = math.pi - sprayAngle;
	end

	--| Calculate which spray side should spray (distance)
	local sideToSpray;
	if ((velocityVector - components.ParticleParts.LeftSpray.Position).Magnitude > (velocityVector - components.ParticleParts.RightSpray.Position).Magnitude) then
		sideToSpray = "Left";
	else
		sideToSpray = "Right";
	end
	
	local sprayValue : number = math.min(2 * sprayAngle * velocity, 70);
	local deltaSpray : number = sprayValue - lastSprayValue;

	--| If big enough respray is detected create a new emitter
	if ((not sprayIncreasing) and (deltaSpray > math.pi / 8)) then
		print("new spray");
		local newEmitter1 = components.ParticleParts.SprayEmitter1:Clone();
		local newEmitter2 = components.ParticleParts.SprayEmitter2:Clone();

		if (sideToSpray == "Left") then
			newEmitter1.Parent = components.ParticleParts.LeftSpray;
			newEmitter2.Parent = components.ParticleParts.LeftSpray;
		else
			newEmitter1.Parent = components.ParticleParts.RightSpray;
			newEmitter2.Parent = components.ParticleParts.RightSpray;
		end
		
	end

	sprayIncreasing = (deltaSpray > 0);
	
	local spraySize = math.clamp(math.sqrt(sprayValue), 0, 10);

	
	-- * Find out why particles dont stop sometimes (not sure if this is 100% fixed)
	
	
	for _, emitter : ParticleEmitter in pairs(components.ParticleParts[sideToSpray .. "Spray"]:GetChildren()) do
		if (emitter:IsA("WeldConstraint")) then
			continue;
		end

		if (sprayIncreasing) then
			if (emitter.Enabled) then
				emitter.Speed = NumberRange.new(sprayValue);
				emitter.Size = NumberSequence.new(spraySize);
			end
		else
			emitter.Enabled = false;
			emitter:SetAttribute("timeout", emitter:GetAttribute("timeout") - deltaTime);

			if (emitter:GetAttribute("timeout") <= 0) then
				emitter:Destroy();
			end
		end
	end


	--| Assure particles stay off
	local notSpraySide;
	if (sideToSpray == "Left") then
		notSpraySide = "Right";
	else
		notSpraySide = "Left";
	end

	for _, emitter : ParticleEmitter in pairs(components.ParticleParts[notSpraySide .. "Spray"]:GetChildren()) do
		if (emitter:IsA("WeldConstraint")) then
			continue;
		end


		emitter.Enabled = false;
		emitter:SetAttribute("timeout", emitter:GetAttribute("timeout") - deltaTime);

		if (emitter:GetAttribute("timeout") <= 0) then
			emitter:Destroy();
		end
	end

	lastSprayValue = sprayValue;
end

function updateMovement(deltaTime : number) : nil
	--| Velocity
	local velocity : number = components.VehicleSeat.AssemblyLinearVelocity.Magnitude;

	--| Unit vector for wasd input
	local movementVectorUnit : Vector2 = Vector2.new(components.VehicleSeat.Throttle, components.VehicleSeat.Steer);

	--| Unit vector for uhjk input
	local uDown : boolean, hDown : boolean, jDown : boolean, kDown : boolean = UserInputService:IsKeyDown(Enum.KeyCode.U), UserInputService:IsKeyDown(Enum.KeyCode.H), UserInputService:IsKeyDown(Enum.KeyCode.J), UserInputService:IsKeyDown(Enum.KeyCode.K);
	local tiltVectorUnit : Vector2 = Vector2.new(boolToBit(uDown) - boolToBit(jDown), boolToBit(kDown) - boolToBit(hDown));

	--| Throttle
	components.PhysicsCore.Thrust.Force = Vector3.new(2250 * movementVectorUnit.X - 250, 0, 0);
	if (velocity > 90) then
		components.PhysicsCore.Thrust.Enabled = false;
	else
		components.PhysicsCore.Thrust.Enabled = true;
	end

	local steerAngle : number = -sledSettings.steerAngle.Value * movementVectorUnit.Y * math.exp(velocity * -0.01); --| Lower turn angle based on more speed
	TweenService:Create(components.Steer, TweenInfo.new(1 - sledSettings.steerSpeed.Value, Enum.EasingStyle.Sine), {["C0"] = CFrame.new(0, 0, -3.5) * CFrame.Angles(0, math.rad(steerAngle), 0)}):Play();

	--| Weight adjustment
	components.PhysicsCore.WeightAnchor.CFrame = CFrame.new(
		(1.5 * movementVectorUnit.Y) + (1 * tiltVectorUnit.Y), --| Left/right
		-5, --| Counterweight
		1 - (1 * tiltVectorUnit.X) --| Forward/backward
	);
	components.PhysicsCore.Weight.Position = components.PhysicsCore.WeightAnchor.WorldPosition;

	--| Tilting + yaw
	components.PhysicsCore.Tilt.Torque = Vector3.new(
		6500 * tiltVectorUnit.Y * sledSettings.rollMult.Value, --| Roll
		3500 * movementVectorUnit.Y * sledSettings.yawStrength.Value, --| Yaw
		7500 * tiltVectorUnit.X * sledSettings.pitchMult.Value --| Pitch
	);

	--| Drag
	components.PhysicsCore.Drag.MaxForce = 1.5 * velocity + 100;

	--| Keystrokes
	keystrokesUI.KS1.Anchor.Position = UDim2.new((movementVectorUnit.Y / 2) + 0.5, 0, (-movementVectorUnit.X / 2) + 0.5);
	keystrokesUI.KS2.Anchor.Position = UDim2.new((tiltVectorUnit.Y / 2) + 0.5, 0, (-tiltVectorUnit.X / 2) + 0.5);

	--| Sled particles
	updateParticles(deltaTime, velocity);
end


--| Sled physics manager


function enableSledControls(sledModel : Model) : nil
	--| Get components of the sled (important parts)
	components = sledModel.Components;

    --| Physics init
	heartbeatConnection = RunService.Heartbeat:Connect(updateMovement);

    --| Camera config
	cameraConnection = RunService.RenderStepped:Connect(UpdateCamera);
    currentCameraMode = 1;
	ContextActionService:BindAction("CameraModeSwitch",  SwitchCameraMode, false, Enum.KeyCode.P);

    --| Gyro strength
    components.PhysicsCore.Gyro.MaxTorque = 1000 * sledSettings.gyroStrength.Value;
	
	--| Sled colouring
	for _, inst : Instance in pairs(sledModel.SledModel:GetChildren()) do
		if (inst:GetAttribute("Colourable") == true) then
			inst.Color = playerSledConfig.sledColour.Value
		end
	end
end

function disableSledControls() : nil
	--| Clear components
	components = nil;

	heartbeatConnection:Disconnect();

	cameraConnection:Disconnect();
	ContextActionService:UnbindAction("CameraModeSwitch");
end

--| Enable / disable sled on seated change
function onSeated(active : boolean, seatPart : BasePart) : nil
	if (active) then
		if (seatPart:GetAttribute("Sled")) then
			print("Seated in sled")
			enableSledControls(seatPart.Parent.Parent);
		end
	else
		disableSledControls();
	end
end

humanoid.Seated:Connect(onSeated);