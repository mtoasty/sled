local DataPackage = {};
DataPackage.__index = DataPackage;


-- * IMPORTANT: Write to type tree and constructor when modifying data table

type DataPackage = {
    ["playerstats"] : {
        ["level"] : number,
        ["xp"] : number
    },
    ["racestats"] : {
        ["cupid"] : number,
        ["mixpeed"] : number,
        ["pure"] : number,
        ["wzrd"] : number,
        ["forever"] : number
    },
    ["preferences"] : {

    },
    ["sledConfig"] : {
        ["sledType"] : string,
        ["cosmetics"] : {
            ["currents"] : boolean
        },
        ["sledColour"] : "\\crgb6, 74, 157",
        ["steerAngle"] : number,
        ["steerSpeed"] : number,
        ["rollMult"] : number,
        ["pitchMult"] : number,
        ["yawStrength"] : number,
        ["gyroStrength"] : number
    },
    ["moons"] : {

    },
    ["onLoadNotification"] : boolean,
    ["ToInstTree"] : () -> Folder,
    ["RestoreMissing"] : () -> nil
}


--| Constructors:


--| Creates a new DataPackage.
function DataPackage.new(t : table?) : DataPackage
    local self : DataPackage = setmetatable(t or {
        ["playerstats"] = {
            ["level"] = 1,
            ["xp"] = 0
        },
        ["racestats"] = {
            ["cupid"] = 99999,
            ["mixpeed"] = 99999,
            ["pure"] = 99999,
            ["wzrd"] = 99999,
            ["forever"] = 99999
        },
        ["preferences"] = {
    
        },
        ["sledConfig"] = {
            ["sledType"] = "Storm",
            ["cosmetics"] = {
                ["currents"] = false
            },
            ["sledColour"] = "\\crgb6, 74, 157",
            ["steerAngle"] = 25,
            ["steerSpeed"] = 0.6,
            ["rollMult"] = 1,
            ["pitchMult"] = 1,
            ["yawStrength"] = 1,
            ["gyroStrength"] = 1
        },
        ["moons"] = {

        },
        ["onLoadNotification"] = ""
    }, DataPackage);

    return self;
end

--| Creates a new DataPackage from a instance Folder tree. This should only be used on a tree created by DataPackge:ToInstTree().
function DataPackage.fromInstTree(instTree : Folder) : DataPackage
    local function copyFolderToTree(folder : Folder, tree : table) : table
        for _, inst : Instance in pairs(folder:GetChildren()) do
            local name : string = inst.Name;
            if (inst:IsA("Folder")) then
                tree[name] = {};
                copyFolderToTree(inst, tree[name]);
            elseif (inst:IsA("Color3Value")) then
                --| Encode colours
                tree[name] = "\\crgb" .. tostring(inst.Value);
            else
                tree[name] = inst.Value;
            end
        end

        return tree;
    end

    return setmetatable(copyFolderToTree(instTree, {}), DataPackage);
end


--| Methods


--| Returns a new instance tree from the data of DataPackage
function DataPackage:ToInstTree() : Folder
    local mainFolder : Folder = Instance.new("Folder");

    local typeInstReferences : {string} = {
        ["number"] = "NumberValue",
        ["string"] = "StringValue",
        ["boolean"] = "BoolValue"
    }

    local function createInstancesForTable(t : table, root : Folder) : Folder
        for index : string, value : any in pairs(t) do
            if (typeof(value) == "table") then

                local newFolder : Folder = Instance.new("Folder");
                newFolder.Parent = root;
                newFolder.Name = index;
                createInstancesForTable(value, newFolder);

            elseif (typeInstReferences[typeof(value)] ~= nil) then

                --| Decode colours
                if (typeof(value) == "string") then
                    if (string.sub(value, 1, 5) == "\\crgb") then
                        local cutString : string = string.sub(value, 6, string.len(value))
                        local split : {string} = string.split(cutString, ",");
                        local newInst : Color3Value = Instance.new("Color3Value");
                        newInst.Parent = root;
                        newInst.Name = index;
                        newInst.Value = Color3.fromRGB(split[1], split[2], split[3]);
                        continue;
                    end
                end

                local newInst : Instance = Instance.new(typeInstReferences[typeof(value)]);
                newInst.Parent = root;
                newInst.Name = index;
                newInst.Value = value;

            end
        end

        return root;
    end

    return createInstancesForTable(self, mainFolder);
end


--| Helper method for Restore
local function assertTable(t : DataPackage, reference : DataPackage) : nil
    --| Remove extras
    for index : string, value : any in pairs(t) do
        if (reference[index] == nil) then
            table.remove(t, index);
            print("removing extra data key " .. tostring(index));
        end
    end

    --| Fill missing
    for index : string, value : any in pairs(reference) do
        if (t[index] == nil) then
            t[index] = value;
            print("restoring " .. tostring(index));
        end

        if (typeof(value) == "table") then
            assertTable(value, reference[index]);
        end
    end
end

function DataPackage:Restore() : nil
    assertTable(self,  DataPackage.new());
end


function DataPackage:ToTable() : table
    local t : table = {};

    for key : string, value : any in pairs(self) do
        if (typeof(value) ~= "function") then
            t[key] = value;
        end
    end

    return t;
end

return DataPackage;