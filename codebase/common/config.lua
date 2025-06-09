--How large the batches should be when
--calling functions like
--batchedParallel().
--Default is 250
local batchSize = 250

--The network peripheral name of the
--turtle that's acting as the server
--for this storage network.
local serverName = "turtle_2"

--This needs to be the network name of
--the Disk Drive you intend to use for
--data transfers between computers.
local transferDrive = "disk"

--The file locations for stuff on the
--transfer drive.
local manifestFile = fs.combine(transferDrive, "manifestFile")
local busWorkFile = fs.combine(transferDrive, "busWork")

--The directory used to hold requests
--from clients before the server has
--a chance to interpret them.
local requestsDir = fs.combine(transferDrive, "requestsDir")
fs.makeDir(requestsDir)

--The directory used to hold recipes
--that the system knows how to craft.
--Stored on the server turtle by
--default (for now).
local recipesDir = "recipes"
fs.makeDir(recipesDir)

--A table of every single inventory
--that's to be used for general item
--storage within the system.
local genInvs = {
"expandedstorage:barrel_4",
"expandedstorage:barrel_5",
"expandedstorage:barrel_6",
"expandedstorage:barrel_7"
}

--The name of an inventory that is
--designated for items coming into the
--system, so that they can be routed
--based on if an item is pending for
--a task or if it can go into the main
--storage area.
local importBuffer = "expandedstorage:chest_4"

--The name of an inventory that items
--are sent to so that client turtles
--can then move the items into their
--own inventories, while not risking
--the transfers failing but still
--updating the manifest as if the items
--were sent successfully.
local clientExportBuffer = "minecraft:chest_0"

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

--Table of items that should be
--auto-condensed by the server program.
--The sub-table structure is as
--follows:
--1. Input encoded name.
--2. Recipe type.
--3. Output encoded name.
--4. Maximum batch craft size.
local condenseTable = {}
table.insert(condenseTable, {"minecraft:redstone", "3x3", "minecraft:redstone_block", 64})

--Return Block
return{
batchSize = batchSize,
transferDrive = transferDrive,
manifestFile = manifestFile,
genInvs = genInvs,
importBuffer = importBuffer,
busWorkFile = busWorkFile,
serverName = serverName,
self = self,
clientExportBuffer = clientExportBuffer,
requestsDir = requestsDir,
modemSide = modemSide,
recipesDir = recipesDir,
condenseTable = condenseTable
}