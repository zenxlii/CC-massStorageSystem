--How large the batches should be when
--calling functions like
--batchedParallel().
--Default is 250
local batchSize = 250

--The name of the disk used to hold the
--manifest file.
local manifestDisk = "FILLED BY mssInstaller.lua"

--The name of the disk used to hold
--code and data that should be
--available to all computers in MSS.
local commonCodeDisk = "FILLED BY mssInstaller.lua"

--The name of an inventory that is
--designated for items coming into the
--system, so that they can be routed
--based on if an item is pending for
--a task or if it can go into the main
--storage area.
local importBuffer = "FILLED BY mssInstaller.lua"

--The name of an inventory that items
--are sent to so that client turtles
--can then move the items into their
--own inventories, while not risking
--the transfers failing but still
--updating the manifest as if the items
--were sent successfully.
local clientExportBuffer = "FILLED BY mssInstaller.lua"

--The file locations for stuff on the
--common code disk.
local manifestFile = manifestDisk.."/manifestFile"
local busWorkFile = commonCodeDisk.."/configFiles/busWork"

--The directory used to hold requests
--from clients before the server has
--a chance to interpret them.
local requestsDir = commonCodeDisk.."/requests/"

--The directory used to hold recipes
--that the system knows how to craft.
--Stored on the server turtle by
--default (for now).
local recipesDir = "recipes/"


--Stores the side of the first modem
--the computer finds for ease of
--reference later on.
local modemSide = ""
local sides = {"top", "bottom", "front", "back", "left", "right"}
for _, side in ipairs(sides) do
	if peripheral.isPresent(side) then
		if peripheral.hasType(side, "modem") then
			if peripheral.wrap(side).isWireless() == false then
				modemSide = side
				break
			end
		end
	end
end
if modemSide == "" then
	error("Please attach a modem to this turtle.")
end

--Return Block
return{
batchSize = batchSize,
manifestFile = manifestFile,
importBuffer = importBuffer,
busWorkFile = busWorkFile,
clientExportBuffer = clientExportBuffer,
requestsDir = requestsDir,
modemSide = modemSide,
recipesDir = recipesDir,
commonCodeDisk = commonCodeDisk
}