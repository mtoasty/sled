local RunService : RunService = game:GetService("RunService");

local components : Folder = script.Parent.Parent.Components;


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
		--print("new spray");
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

local heartbeat : RBXScriptConnection;

heartbeat = RunService.Heartbeat:Connect(function(deltaTime : number) : nil
    if components:FindFirstChild("VehicleSeat") == nil then
        heartbeat:Disconnect();
        return;
    end

    local velocity : number = components.VehicleSeat.AssemblyLinearVelocity.Magnitude;
    updateParticles(deltaTime, velocity);
end);
