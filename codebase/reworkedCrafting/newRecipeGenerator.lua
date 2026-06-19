--Note:
--This must be ran on a turtle to
--function at all.

local function nameEncode(iName, iNBT)
	if iNBT == "" or iNBT == nil then
		return iName
	else
		return iName.."#"..iNBT
	end
end

--GUI Drawing Functions

--Renamed Shorthands
local function pos(...) return term.setCursorPos(...) end
local function cls(...) return term.clear() end
local function tCol(...) return term.setTextColour(...) end
local function bCol(...) return term.setBackgroundColour(...) end
local function box(...) return paintutils.drawFilledBox(...) end
local function line(...) return paintutils.drawLine(...) end 
local x,y = term.getSize()

local compactedFiles = false

local craftingTypeTable = {}
--Makes craftingTypes.txt if it does
--not exist and initialises it.
if not fs.exists("craftingTypes.txt") then
	local file = fs.open("craftingTypes.txt", "w")
	local ctct = {}
	ctct[1] = "c"
	ctct[2] = {"server"}
	ctct[3] = {1,2,3,5,6,7,9,10,11}
	craftingTypeTable["craftingTable"] = ctct
	file.write(textutils.serialise(craftingTypeTable, {compact = compactedFiles}))
	file.close()
	craftingTypeTable = {}
end

--Load the contents of
--craftingTypes.txt into a table.
local ctFile = fs.open("craftingTypes.txt", "r")
craftingTypeTable = textutils.unserialise(ctFile.readAll())
ctFile = nil

local recipeTable = {}
--Ensures that recipeData.txt exists.
if not fs.exists("recipeData.txt") then
	local file = fs.open("recipeData.txt", "w")
	file.close()
end

--Ask the user for a crafting type.
local recipeType = "doesn't exist, please don't use this as a recipe type you-"
if craftingTypeTable[recipeType] ~= nil then
	error("WHY IS THIS EVEN A CRAFTING TYPE?!?!?")
end
while recipeType == "doesn't exist, please don't use this as a recipe type you-" do
	local prompt = {}
	prompt[1] = "What crafting type would you like this"
	prompt[2] = "recipe to be? Valid values are:"
	local i = 3
	for line, _ in pairs(craftingTypeTable) do
		prompt[i] = line
		i = i + 1
	end
	i = nil
	local message = table.concat(prompt, "\n")
	local width, height = term.getCursorPos()
	textutils.pagedPrint(message, height - 4)
	
	local input = io.read()
	if craftingTypeTable[input] == nil then
		print(input)
		print("is not a valid value.")
	else
		print("Is the following correct?")
		print("Y for Yes, otherwise No")
		print(input)
		local confirm = string.lower(io.read())
		if confirm == "y" then
			recipeType = input
		end
	end
end
--Specifically to prevent messing the
--recipe up by mashing Enter too fast.
os.sleep(0.5)

--This program can only create recipes
--with at most 9 input slots and 7
--output slots.
--Anything more complicated than this
--will require writing the recipe
--manually.
--But like... that really only leaves,
--what, the Mechanical Crafter from
--Create?
--Also is limited by the stack sizes
--of the items themselves.

--TODO:
--Add hinting data to the crafting
--types, and then add support to show
--those hints in this section.
local outSlots = {false,false,false,true,false,false,false,true,false,false,false,true,true,true,true,true}
local slotOrder = {1,2,3,7,4,5,6,6,7,8,9,5,4,3,2,1}
local recipeInputs = {}
local recipeOutputs = {}
local recipeItemBuffer = {}
local isRecipeSet = false
term.clear()
term.setCursorPos(1,1)
print("Place the ingredients and results in")
print("the appropriate slots below, matching")
print("their slot numbers according to the")
print("crafting type that was selected,")
print(recipeType)
print("Top-left 3x3 is for ingredients.")
print("All other slots are for results.")
print("Press ENTER when everything is")
print("in place.")
io.read()
for i = 1,16 do
	recipeItemBuffer[i] = turtle.getItemDetail(i, true)
end
if recipeItemBuffer == {} then
	error("No items?")
end
for slot, item in pairs(recipeItemBuffer) do
	local eName = nameEncode(item.name, item.nbt)
	local amount = item.count
	if outSlots[slot] then
		recipeOutputs[slotOrder[slot]] = {eName, amount}
	else
		recipeInputs[slotOrder[slot]] = {eName, amount}
	end
end
os.sleep(0.5)

--Set the maximum batch size.
term.clear()
term.setCursorPos(1,1)
local batchSize = 0
while batchSize == 0 do
	print("Next, what is the maximum batch size")
	print("for this recipe?")
	local input = io.read()
	local inputNum = tonumber(input)
	if inputNum ~= nil then
		inputNum = math.floor(inputNum)
		if inputNum > 0.5 then
			print(inputNum)
			print("Are you sure? Y for Yes, otherwise No")
			local input2 = string.lower(io.read())
			if input2 == "y" then
				batchSize = inputNum
			end
		else
			print("That was less than 1!")
		end
	else
		print("That was not a number!")
	end
end
os.sleep(0.5)

--Priority/override stuff.
term.clear()
term.setCursorPos(1,1)
local priority = 0
while priority == 0 do
	print("Input a number to give this recipe a")
	print("priority that overrides another recipe.")
	print("Or input some text (or nothing) to")
	print("skip over this bit entirely.")
	local input = io.read()
	local inputNum = tonumber(input)
	if inputNum == nil then
		print("Skipping over this section...")
		priority = "nope"
	else
		inputNum = math.floor(inputNum)
		if inputNum > 0.5 then
			print(inputNum)
			print("Are you sure? Y for Yes, otherwise No")
			local input2 = string.lower(io.read())
			if input2 == "y" then
				priority = inputNum
			end
		else
			print("This number is too small!")
		end
	end
end
if priority == "nope" then
	priority = nil
end
os.sleep(0.5)

--TODO:
--Implement recipe map ignored results
--(Index 6).

--Now make the final recipe data table
--and save it to disk.
print("The recipe has been defined!")
print("Saving it to the file now...")

local finalRecipeTable = {}
finalRecipeTable[1] = recipeOutputs
finalRecipeTable[2] = recipeInputs
finalRecipeTable[3] = batchSize
finalRecipeTable[4] = recipeType
finalRecipeTable[5] = priority

local file = fs.open("recipeData.txt", "r")
local rdText = file.readAll()
local masterRecipeList = textutils.unserialise(rdText)
file.close()
if masterRecipeList == nil then
	masterRecipeList = {}
end
table.insert(masterRecipeList, finalRecipeTable)
local file = fs.open("recipeData.txt", "w")
file.write(textutils.serialise(masterRecipeList, {compact = compactedFiles}))
file.close()