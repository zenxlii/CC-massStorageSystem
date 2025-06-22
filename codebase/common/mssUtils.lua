local config = require("config")

local batchSize = config.batchSize

--A table with keys of peripheral names
--and values of wrapped peripherals.
local wrappedPeriTable = {}

--Back-End Functions

--When given a table, this function
--returns the keys of said table.
function getTableKeys(tab)
	local keyset = {}
	for k,v in pairs(tab) do
		keyset[#keyset + 1] = k
	end
	return keyset
end

--Does parallel.waitForAll() but with
--fixes to allow for batched operation.
--No return statement as it assumes
--that we alter variables in the
--calling function. Does not affect the
--supplied function table.
local function batchedParallel(funcs)
	for cnt = 1, #funcs, batchSize do
        local batchEnd = cnt + batchSize - 1
        local highLim = math.min(batchEnd, #funcs)
        parallel.waitForAll(table.unpack(funcs, cnt, highLim))
    end
end

--Serialises and then prints out the
--argument that is given to this
--function.
--Not called in main execution, but is
--an aid for adding tasks to busWork.
local function serialPrinter(inData)
	local serialised = textutils.serialise(inData)
	print(serialised)
end
--Use this space to use serialPrinter()
--and make some stuff!
--[[
local toSerialise = {{}}
toSerialise[1]["job"] = "export"
toSerialise[1]["eName"] = "minecraft:iron_block"
toSerialise[1]["target"] = "expandedstorage:chest_3"
toSerialise[1]["targetSlot"] = 0
toSerialise[1]["amount"] = 1
serialPrinter(toSerialise)
]]

--Item Name Encoding/Decoding Functions

--Converts an item's internal name and
--NBT hash into an encoded name.
--Send
local function nameEncode(iName, iNBT)
	if iNBT == "" or iNBT == nil then
		return iName
	else
		return iName.."#"..iNBT
	end
end

--Converts an item's encoded name into
--the internal name and NBT hash.
local function nameDecode(eName)
	local splitName = {}
    for part in string.gmatch(eName, "[^#]+") do
        splitName[#splitName+1] = part
    end
    local out = {}
    out["name"] = splitName[1]
    if #splitName == 1 then
        out["NBT"] = ""
    else
        out["NBT"] = splitName[2]
    end
    return out
end

--Checks to see if the given peripheral
--name has been wrapped before, and
--passes that wrapped handle if so, and
--if not, wrap the peripheral and add
--it to the table.
local function fastWrap(peripheralName)
	if not wrappedPeriTable[peripheralName] then
		wrappedPeriTable[peripheralName] = peripheral.wrap(peripheralName)
	end
	return wrappedPeriTable[peripheralName]
end

--Table Serialisation Functions

--Below are functions that serialise
--displayManifest tables to and from a
--formatted string, which uses less
--space on-disk compared to the stock
--textutils.serialise function family.

return{
getTableKeys = getTableKeys,
batchedParallel = batchedParallel,
serialPrinter = serialPrinter,
nameEncode = nameEncode,
nameDecode = nameDecode,
fastWrap = fastWrap
}