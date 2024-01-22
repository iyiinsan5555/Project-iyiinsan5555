local CustomInstanceCreator = {}
CustomInstanceCreator.__index = CustomInstanceCreator

CustomInstanceCreator.Id_Table = {}

--[[
	So how does it works
	-It allows us to create a instance with id (id could be a string or number)
	-So after creating a new instance, we give the id to edit the instance

]]


local function Check_Id_Is_Valid(Id)
	
	local Id_Table = CustomInstanceCreator.Id_Table

	if Id_Table[Id] then
		return true
	else
		warn("Instance with Id " .. tostring(Id) .. " does not exist.")
		return false
	end

end



function CustomInstanceCreator:CreateInstance(InstanceName :string, Id, Parent)

	local CreatedInstance = Instance.new(InstanceName)
	if Parent then
		CreatedInstance.Parent = Parent
	end

	local Id_Table = CustomInstanceCreator.Id_Table

	Id_Table[Id] = CreatedInstance

	return CreatedInstance

end

function CustomInstanceCreator:GetInstanceFromId(Id)

	if not Check_Id_Is_Valid(Id) then
        return
    end

	local Id_Table = CustomInstanceCreator.Id_Table

	return Id_Table[Id]

end

function CustomInstanceCreator:EditInstance(Id, PropertyName :string, Value)

    if not Check_Id_Is_Valid(Id) then
        return
    end

    local CreatedInstance = self:GetInstanceFromId(Id)

    local success, errorMessage = pcall(function()
        CreatedInstance[PropertyName] = Value
    end)

    if not success then
        warn("Failed to set property '" .. tostring(PropertyName) .. "' on instance with Id " .. tostring(Id) .. ". Error: " .. errorMessage)
    end

end





return CustomInstanceCreator