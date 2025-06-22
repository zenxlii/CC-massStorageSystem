--Imports
local commonCodeDisk = require("commonCodeDisk")
local ccd = commonCodeDisk.commonCodeDisk
local config = require("../"..ccd.."/mss/configFiles/config")
local rll = require("recipeListLoader")
local mssU = require("../"..ccd.."/mss/mssUtils")
local condList = require("../"..ccd.."/mss/configFiles/condenseList")
local storeList = require("configFiles/storageList")

--Constants
local batchSize = config.batchSize

local self = peripheral.find("modem").getNameLocal()

local genInvs = storeList.genInvs

local allInvs = genInvs

local manifestFile = config.manifestFile

local busWorkFile = config.busWorkFile

local importBuffer = config.importBuffer
local clientExportBuffer = config.clientExportBuffer

local requestsDir = config.requestsDir

local modemSide = config.modemSide

rednet.open(modemSide)

local recipeList = rll.recipeList

local condenseTable = condList.condenseTable

--Manifest Stuff

--The master manifest that contains
--every item in the storage system.
local manifest = {}

--Nested table of booleans which
--corresponds to if a given slot in the
--storage system has anything in there.
--Is true if the slot is empty.
--Is false if the slot isn't empty.
local emptySlotsTable = {}

--Constructs a cut-down copy of the
--manifest, serialises it and then
--saves it to a file on a floppy disk.
local function saveDisplayManifest()
	--Make a greatly cut-down version
	--of the current manifest that the
	--clients are to use.
	local displayManifest = {}
	for eName, data in pairs(manifest) do
		displayManifest[eName] = {}
		displayManifest[eName]["amount"] = data["free"]
		displayManifest[eName]["displayName"] = data["displayName"]
		--Only adds the maxStack if it
		--isn't 64, as we assume it is
		--64 if omitted.
		if data["maxStack"] ~= 64 then
			displayManifest[eName]["maxStack"] = data["maxStack"]
		end
		--Only adds hasRecipe if it has
		--a recipe, as we assume it
		--doesn't if omitted.
		if recipeList[eName] then
			displayManifest[eName]["hasRecipe"] = true
		end
	end
	local serialDM = textutils.serialise(displayManifest)
	--Check if a manifestFile exists at
	--all.
	if fs.exists(manifestFile) then
		--Load the current manifestFile
		--to see if anything has
		--changed.
		local dmSerial = ""
		local file = fs.open(manifestFile, "r")
		local line = ""
		local count = 1
		while line ~= nil do
			count = count + 1
			dmSerial = dmSerial..line
			line = file.read()
		end
		file.close()
	end
	--Only updates the file if there's
	--new data to write to it.
	if serialDM ~= dmSerial or not fs.exists(manifestFile) then
		--Creates a fresh file to get
		--to work with.
		local file = fs.open(manifestFile, "w")
		file.write(serialDM)
		file.close()
	end
end

--If there is a manifestFile present,
--read in the display names and the
--maximum stack size from that.
local function loadDataFromDM()
	if not fs.exists(manifestFile) then
		return
	end
	local dmSerial = ""
	local file = fs.open(manifestFile, "r")
	local line = ""
	local count = 1
	while line ~= nil do
		count = count + 1
		dmSerial = dmSerial..line
		line = file.read()
	end
	file.close()
	local outData = textutils.unserialise(dmSerial)
	--Add the missing maxStack and
	--hasRecipe values back in.
	for eName, data in pairs(outData) do
		if data["maxStack"] == nil then
			data["maxStack"] = 64
		end
		if data["hasRecipe"] == nil then
			data["hasRecipe"] = false
		end
	end
	return outData
end

--Uses the data in manifestFile to add
--details to the manifest, without the
--tick cost of calling .getItemDetail()
--and this works for items that aren't
--in storage but are in manifestFile.
local function loadDetailsFromDM()
	local dmData = loadDataFromDM()
	if dmData == nil then
		return
	end
	for eName, data in pairs(dmData) do
		if not manifest[eName] then
			manifest[eName] = {}
		end
		if not manifest[eName]["data"] then
			manifest[eName]["data"] = {}
		end
		if not manifest[eName]["total"] then
			manifest[eName]["total"] = 0
		end
		if not manifest[eName]["free"] then
			manifest[eName]["free"] = 0
		end
		if not manifest[eName]["reserved"] then
			manifest[eName]["reserved"] = 0
		end
		if not manifest[eName]["pending"] then
			manifest[eName]["pending"] = 0
		end
		manifest[eName]["displayName"] = data["displayName"]
		manifest[eName]["maxStack"] = data["maxStack"]
	end
end

--Takes the name of an inventory on the
--network, as well as the slot number
--to check, and adds the relevant
--details to the "metadata" for that
--item in the manifest.
--Does not update the display manifest,
--as this function can be called many
--times in a row.
local function addDetailsToManifest(invName, slotNum)
	local itemDetails = mssU.fastWrap(invName).getItemDetail(slotNum)
	local eName = mssU.nameEncode(itemDetails.name, itemDetails.nbt)
	--Check to see if the item has a
	--manifest entry in the first place
	--and if not, make one.
	if not manifest[eName] then
		manifest[eName] = {}
	end
	if not manifest[eName]["data"] then
		manifest[eName]["data"] = {}
	end
	if not manifest[eName]["total"] then
		manifest[eName]["total"] = 0
	end
	if not manifest[eName]["free"] then
		manifest[eName]["free"] = 0
	end
	if not manifest[eName]["reserved"] then
		manifest[eName]["reserved"] = 0
	end
	if not manifest[eName]["pending"] then
		manifest[eName]["pending"] = 0
	end
	manifest[eName]["displayName"] = itemDetails.displayName
	manifest[eName]["maxStack"] = itemDetails.maxCount
end



--Replaces the current "totals" fields
--for the given item name with ones
--that has just been calculated by
--summing every stack of that item in
--the manifest.
--Returns the newly-calculated totals
--for this item, for convenience.
local function initialiseManifest()
	loadDetailsFromDM()
	local funcs = {}
	local genInvsList = {}
	local genInvsSlots = {}
	--List the contents of every
	--general storage inventory.
	for index, inv in ipairs(genInvs) do
		table.insert(funcs, function()
			--Ensures that the index
			--order of genInvsList is
			--always the same.
			genInvsList[index] = mssU.fastWrap(inv).list()
			genInvsSlots[index] = mssU.fastWrap(inv).size()
		end)
	end
	mssU.batchedParallel(funcs)
	funcs = {}
	--Next stage, start filling out the
	--manifest with itemstack data.
	--Also sums up the item totals from
	--scratch because no other task can
	--be mid-execution before we start
	--the main execution loop.
	for index, list in ipairs(genInvsList) do
		for slotNum, iData in pairs(list) do
			local slot = slotNum
			local eName = mssU.nameEncode(iData.name, iData.nbt)
			local count = iData.count
			if manifest[eName] == nil then
				manifest[eName] = {}
				manifest[eName]["total"] = 0
				table.insert(funcs, function()
					addDetailsToManifest(genInvs[index], slot)
				end)
			else
			end
			if manifest[eName]["data"] == nil then
				manifest[eName]["data"] = {}
			end
			if manifest[eName]["data"][index] == nil then
				manifest[eName]["data"][index] = {}
			else
			end
			manifest[eName]["data"][index][slot] = {}
			manifest[eName]["data"][index][slot] = count
			manifest[eName]["total"] = manifest[eName]["total"] + count
		end
	end
	--Now add all the item details in
	--parallel.
	mssU.batchedParallel(funcs)
	funcs = {}
	--And we can also set the free and
	--reserved totals now.
	for eName, _ in pairs(manifest) do
		manifest[eName]["free"] = manifest[eName]["total"]
		manifest[eName]["reserved"] = 0
		manifest[eName]["pending"] = 0
	end
	--Go through and identify which
	--slots are filled and which are
	--empty.
	for index = 1, #genInvsSlots do
		local slotCount = genInvsSlots[index]
		emptySlotsTable[index] = {}
		for slot = 1, slotCount do
			if genInvsList[index][slot] then
				emptySlotsTable[index][slot] = false
			else
				emptySlotsTable[index][slot] = true
			end
		end
	end
	--Finally, update the display
	--manifest for the clients to use.
	saveDisplayManifest()
end

--Requestable Functions

--Returns true if there is at least the
--supplied amount of this item in the
--system, and false otherwise.
local function ensureItem(eName, amount)
	if manifest[eName]["free"] < amount then
		return false
	else
		return true
	end
end

--First uses ensureItem to see if the
--desired amount is in storage, and if
--there is enough, returns a table of
--storage system IDs, peripheral names,
--slot numbers and amounts to take.
--Will return the amount of this item
--present if there isn't enough.
local function locateItem(eName, amount)
	local amountCheck = ensureItem(eName, amount)
	if amountCheck == false then
		return manifest[eName]["free"]
	end
	local leftToFind = amount
	local sources = {}
	local miniManifest = manifest[eName]["data"]
	for index, inv in pairs(miniManifest) do
		if leftToFind == 0 then
			break
		else
			local invName = genInvs[index]
			for slot, count in pairs(inv) do
				if leftToFind == 0 then
					break
				elseif count > leftToFind then
					table.insert(sources, {index, invName, slot, leftToFind})
					leftToFind = 0
				else
					table.insert(sources, {index, invName, slot, count})
					leftToFind = leftToFind - count
				end
			end
		end
	end
	return sources
end

--Manifest Altering Functions
--NOTE:
--All functions in this section will
--require a review when implementing
--bulk storage, and might need an
--execution split to handle it.

--Subtracts a value from the number of
--items in a given inventory and slot.
--Accounts for trying to subtract more
--items than exists in the slot and the
--nil-ing of values that are 0.
--Always takes items from "reserved"!!!
local function subtractReservedItems(eName, allInvsID, slot, subtract)
	local data = manifest[eName]["data"][allInvsID][slot]
	local diff = subtract
	data = data - subtract
	if data <= 0 then
		diff = manifest[eName]["data"][allInvsID][slot]
		data = 0
		emptySlotsTable[allInvsID][slot] = true
		manifest[eName]["data"][allInvsID][slot] = nil
		if manifest[eName]["data"][allInvsID] == {} then
			manifest[eName]["data"][allInvsID] = nil
		end
	else
		manifest[eName]["data"][allInvsID][slot] = data
	end
	manifest[eName]["total"] = manifest[eName]["total"] - diff
	manifest[eName]["reserved"] = manifest[eName]["reserved"] - diff
end

--Adds a value to the number of items
--in a given inventory and slot.
--Has no protections for going over the
--stack size limit of a given item, it
--expects that the prior function calls
--have that handled already.
--If scanInv and scanSlot are provided,
--then use those for the call made to
--addDetailsToManifest().
local function addItems(eName, allInvsID, slot, addition, scanInv, scanSlot)
	if scanInv and scanSlot then
		if manifest[eName] == nil or manifest[eName]["data"] == nil then
			addDetailsToManifest(scanInv, scanSlot)
		end
	else
		if manifest[eName] == nil or manifest[eName]["data"] == nil then
			addDetailsToManifest(allInvs[allInvsID], slot)
		end
	end
	--In case 0 items are added.
	if addition == 0 then
		if manifest[eName]["data"][allInvsID] == nil then
			emptySlotsTable[allInvsID][slot] = true
		else
			if manifest[eName]["data"][allInvsID][slot] == nil then
				emptySlotsTable[allInvsID][slot] = true
			end
		end
		return
	end
	if manifest[eName]["data"][allInvsID] == nil then
		manifest[eName]["data"][allInvsID] = {}
		manifest[eName]["data"][allInvsID][slot] = addition
	elseif manifest[eName]["data"][allInvsID][slot] == nil then
		manifest[eName]["data"][allInvsID][slot] = addition
	else
		manifest[eName]["data"][allInvsID][slot] = manifest[eName]["data"][allInvsID][slot] + addition
	end
	if manifest[eName]["pending"] == 0 then
		--If nothing is pending-...
		manifest[eName]["free"] = manifest[eName]["free"] + addition
		manifest[eName]["total"] = manifest[eName]["total"] + addition
	elseif manifest[eName]["pending"] < addition then
		--If only part of this stack is
		--pending-...
		manifest[eName]["free"] = manifest[eName]["free"] + addition - manifest[eName]["pending"]
		manifest[eName]["reserved"] = manifest[eName]["reserved"] + manifest[eName]["pending"]
		manifest[eName]["pending"] = 0
		manifest[eName]["total"] = manifest[eName]["total"] + addition
	else
		--If the entire stack is
		--pending-...
		manifest[eName]["reserved"] = manifest[eName]["reserved"] + addition
		manifest[eName]["pending"] = manifest[eName]["pending"] - addition
		manifest[eName]["total"] = manifest[eName]["total"] + addition
	end
	emptySlotsTable[allInvsID][slot] = false
end

--Checks if there are enough items in
--storage, and if so it will move them
--from "free" to "reserved".
--Also returns the success of the
--reservation attempt.
local function freeToReserved(eName, amount)
	if ensureItem(eName, amount) then
		manifest[eName]["free"] = manifest[eName]["free"] - amount
		manifest[eName]["reserved"] = manifest[eName]["reserved"] + amount
		return true
	else
		return false
	end
end

--Updates the manifest to factor in the
--movement of items entirely within the
--storage system itself.
--It is expected that the caller of
--this function has already done checks
--on the amounts of the two slots.
local function moveItemsInternal(eName, amount, sendInvID, sendSlot, receInvID, receSlot)
	--Add items to the receiving
	--inventory and slot.
	if emptySlotsTable[receInvID][receSlot] == true then
		if manifest[eName]["data"][receInvID] == nil then
			manifest[eName]["data"][receInvID] = {}
		end
		manifest[eName]["data"][receInvID][receSlot] = amount
		emptySlotsTable[receInvID][receSlot] = false
	else
		manifest[eName]["data"][receInvID][receSlot] = amount + manifest[eName]["data"][receInvID][receSlot]
	end
	--Remove items from the sending
	--inventory and slot.
	manifest[eName]["data"][sendInvID][sendSlot] = manifest[eName]["data"][sendInvID][sendSlot] - amount
	if manifest[eName]["data"][sendInvID][sendSlot] <= 0 then
		manifest[eName]["data"][sendInvID][sendSlot] = nil
		emptySlotsTable[sendInvID][sendSlot] = true
		if manifest[eName]["data"][sendInvID] == {} then
			manifest[eName]["data"][sendInvID] = nil
		end
	end
end

--Errand Stuff

--List of all the scan-type (.list())
--errands that the system needs to make
--in this iteration of the main loop.
--Indices correspond to inventories to
--scan, values correspond to the
--function call.
local scanErrands = {}

--Return values from scanErrands.
--Indices correspond to inventories to
--scan, values correspond to the
--contents of said scan (but can be
--altered by later errand types).
local scanReturns = {}

local scanSlotCounts = {}

local function scan(target)
	scanReturns[target] = mssU.fastWrap(target).list()
end

--Loops over every scanned inventory,
--and processes that data.
local function postScanWork()
	for index, scanReturn in pairs(scanReturns) do
		local slotCount = scanSlotCounts[index]
		local scanResult = scanReturns[index]
		for slotIndex = 1, slotCount do
			if scanResult[slotIndex] == nil then
				scanReturns[index][slotIndex] = false
			end
		end
	end
end

--Parallel-friendly addScanErrand().
local function addScanErrand(target)
	--Prevents duplicate scans for the
	--same inventory being made.
	if not scanReturns[target] then
		--If we've never seen this
		--inventory before, figure out
		--its slot count.
		if not scanSlotCounts[target] then
			scanSlotCounts[target] = mssU.fastWrap(target).size()
		end
		table.insert(scanErrands, function()
			scan(target)
		end)
	end
end

--List of all the push-type (exporting)
--errands that the system needs to make
--in this iteration of the main loop.
local pushErrands = {}

local function push(target, targetSlot, source, sourceSlot, amount)
	mssU.fastWrap(source).pushItems(target, sourceSlot, amount, targetSlot)
end

local function addPushErrand(target, sourceID, sourceSlot, amount, eName, isFinalPush)
	local targetSlot = -1
	for tSlot, contents in ipairs(scanReturns[target]) do
		if contents == false then
			targetSlot = tSlot
			break
		end
	end
	if targetSlot == -1 then
		return false
	end
	table.insert(pushErrands, function()
		push(target, targetSlot, allInvs[sourceID], sourceSlot, amount)
	end)
	subtractReservedItems(eName, sourceID, sourceSlot, amount)
	scanReturns[target][targetSlot] = true
	if isFinalPush == true then
		--Sets aside the slot that this
		--push errand is going to
		--insert into, so that no other
		--push errand tries to use it.
		scanReturns[target][targetSlot] = true
		return true
	end
end

--Variant of push which just doesn't
--care about inserted slot, but still
--reserves one just to be safe.
local function dumbPush(target, source, sourceSlot, amount)
	mssU.fastWrap(source).pushItems(target, sourceSlot, amount)
end

local function addDumbPushErrand(target, sourceID, sourceSlot, amount, eName, isFinalPush)
	local targetSlot = -1
	for tSlot, contents in ipairs(scanReturns[target]) do
		if contents == false then
			targetSlot = tSlot
			break
		end
	end
	if targetSlot == -1 then
		return false
	end
	table.insert(pushErrands, function()
		dumbPush(target, allInvs[sourceID], sourceSlot, amount)
	end)
	subtractReservedItems(eName, sourceID, sourceSlot, amount)
	scanReturns[target][targetSlot] = true
	if isFinalPush == true then
		--Sets aside the slot that this
		--push errand is going to
		--insert into, so that no other
		--push errand tries to use it.
		scanReturns[target][targetSlot] = true
		return true
	end
end

--Variant of addPushErrand() that
--pushes to a specific slot of the
--target's inventory.
--Is intended for crafting, and does
--not rely on scanning to work.
local function addFixedPushErrand(target, targetSlot, sourceID, sourceSlot, amount, eName)
	table.insert(pushErrands, function()
		mssU.fastWrap(allInvs[sourceID]).pushItems(target, sourceSlot, amount, targetSlot)
	end)
	subtractReservedItems(eName, sourceID, sourceSlot, amount)
end

--Tracks if this loop iteration should
--call turtle.craft() or not.
local shouldCraft = false

--Sets shouldCraft to true, and this
--function returns if there was already
--a crafting errand happening in this
--main loop iteration.
local function addCraftErrand()
	local oldShouldCraft = shouldCraft
	shouldCraft = true
	return oldShouldCraft
end

--List of all the pull-type (importing)
--errands that the system needs to make
--in this iteration of the main loop.
local pullErrands = {}

local function pull(target, targetSlot, source, sourceSlot, amount, eName, targetID)
	local amountMoved = mssU.fastWrap(target).pullItems(source, sourceSlot, amount, targetSlot)
	addItems(eName, targetID, targetSlot, amountMoved)
end

local function addPullErrand(source, sourceSlot, amount, eName)
	--Find a free slot to pull the
	--items into.
	local targetID = false
	local targetSlot = false
	--Ensures that we insert into the
	--lowest index inventory possible.
	local breaker = false
	for genInvsID, container in pairs(emptySlotsTable) do
		for slotID, state in pairs(container) do
			if state == true then
				targetID = genInvsID
				targetSlot = slotID
				breaker = true
				break
			end
		end
		if breaker then
			break
		end
	end
	--Give up if we can't find a slot
	--to insert into.
	if targetID == false then
		return
	end
	table.insert(pullErrands, function()
		pull(genInvs[targetID], targetSlot, source, sourceSlot, amount, eName, targetID)
	end)
	--Designate the slot as being
	--occupied now, so that other calls
	--to addPullErrand() in this main
	--loop iteration can put stuff into
	--the system.
	emptySlotsTable[targetID][targetSlot] = false
end

--Quickly dumps everything in the
--turtle's inventory into the
--importBuffer.
local function dumpInventory()
	local dumpInv = mssU.fastWrap(importBuffer)
	for cnt = 1,16 do
		table.insert(pullErrands, function() 
			dumpInv.pullItems(self, cnt)
		end)
	end
end

--Handles a "combine" errand.
local function combine(target, targetSlot, source, sourceSlot, amount)
	mssU.fastWrap(target).pullItems(source, sourceSlot, amount, targetSlot)
end

local function addCombineErrand(target, targetSlot, targetAmount, source, sourceSlot, sourceAmount, maxStack, eName)
	local mergedAmount = targetAmount + sourceAmount
	--Send as much of sourceStack that
	--we can without overflowing the
	--targetStack.
	local amount = sourceAmount
	if mergedAmount > maxStack then
		amount = maxStack - targetAmount
	end
	table.insert(pullErrands, function()
		combine(genInvs[target], targetSlot, genInvs[source], sourceSlot, amount)
	end)
	moveItemsInternal(eName, amount, source, sourceSlot, target, targetSlot)
end

--Resets all of the errands tables back
--to being empty.
local function clearAllErrands()
	scanErrands = {}
	scanReturns = {}
	pushErrands = {}
	shouldCraft = false
	pullErrands = {}
end

--Executes all the errands we've got
--built up, then deletes them.
local function executeAllErrands()
	mssU.batchedParallel(pushErrands)
	if shouldCraft == true then
		turtle.craft()
	end
	mssU.batchedParallel(pullErrands)
	clearAllErrands()
end

--Task Stuff

--List of every task that should be
--handled by the system at this current
--point in time. It is expected that
--each task type includes a condition
--for removal from the masterTaskList.
local masterTaskList = {}

--Below are examples of each task type.
--[[
export = {"taskType" = "export", "amount" = 4, "target" = "expandedstorage:chest_3", "eName" = "minecraft:redstone"}
import = {"taskType" = "import", "target" = "minecraft:chest_0"}
craft = {"taskType" = "craft", "eName" = "minecraft:iron_ingot", "amount" = 18}
supply = {}--TODO
output = {"taskType" = "output", "amount" = 12, "eName" = "minecraft:iron_block", "target" = "turtle_3"}
]]

--All of the pushSpreader functions
--rely upon the manifest being accurate
--at the moment they are evaluated...
--and aren't PERFECTLY safe.

--Used for both export and output tasks
--that are not dumb.
local function pushSpreader(target, eName, amount)
	--The upper limit on how many items
	--this task should move.
	local amountLeft = amount
	local potSources = manifest[eName]["data"]
	local maxStack = manifest[eName]["maxStack"]
	--How many items have been moved in
	--this task so far.
	local willMove = 0
	for allInvsID, slotIDs in pairs(potSources) do
		local sourceID = allInvsID
		for slot, quant in pairs(slotIDs) do
			--Early check for if there
			--is any space in the
			--target inventory.
			local targetState = scanReturns[target]
			local hasSpace = false
			for slotNum, state in pairs(targetState) do
				if state == false then
					hasSpace = true
					break
				end
			end
			if hasSpace == false then
				return amountLeft
			end
			local sourceSlot = slot
			--Figure out how many items
			--we can move in this
			--errand.
			local spaceInCurrStack = maxStack - (willMove % maxStack)
			local moveThisErrand = math.min(amountLeft, spaceInCurrStack, quant)
			if moveThisErrand + willMove == amount then
				wasTaskSuccessful = addPushErrand(target, sourceID, sourceSlot, moveThisErrand, eName, true)
			else
				wasTaskSuccessful = addPushErrand(target, sourceID, sourceSlot, moveThisErrand, eName, false)
			end
			amountLeft = amountLeft - moveThisErrand
			willMove = willMove + moveThisErrand
			if amountLeft == 0 then
				break
			end
		end
		if amountLeft == 0 then
			break
		end
	end
	return amountLeft
end

--Used for both export and output tasks
--that are dumb.
local function dumbPushSpreader(target, eName, amount)
	--The upper limit on how many items
	--this task should move.
	local amountLeft = amount
	local potSources = manifest[eName]["data"]
	--How many items have been moved in
	--this task so far.
	local willMove = 0
	for allInvsID, slotIDs in pairs(potSources) do
		local sourceID = allInvsID
		for slot, quant in pairs(slotIDs) do
			--Early check for if there
			--is any space in the
			--target inventory.
			local targetState = scanReturns[target]
			local hasSpace = false
			for slotNum, state in pairs(targetState) do
				if state == false then
					hasSpace = true
					break
				end
			end
			if hasSpace == false then
				return amountLeft
			end
			local sourceSlot = slot
			--Figure out how many items
			--we can move in this
			--errand.
			local moveThisErrand = math.min(amountLeft, quant)
			if moveThisErrand + willMove == amount then
				wasTaskSuccessful = addDumbPushErrand(target, sourceID, sourceSlot, moveThisErrand, eName, true)
			else
				wasTaskSuccessful = addDumbPushErrand(target, sourceID, sourceSlot, moveThisErrand, eName, false)
			end
			amountLeft = amountLeft - moveThisErrand
			willMove = willMove + moveThisErrand
			if amountLeft == 0 then
				break
			end
		end
		if amountLeft == 0 then
			break
		end
	end
	return amountLeft
end

--Used to spread out push errands for a
--craft task or job.
local function fixedPushSpreader(target, targetSlot, eName, amount)
	--The upper limit on how many items
	--this task should move.
	local amountLeft = amount
	local potSources = manifest[eName]["data"]
	local maxStack = manifest[eName]["maxStack"]
	--How many items have been moved in
	--this task so far.
	local willMove = 0
	for allInvsID, slotIDs in pairs(potSources) do
		local sourceID = allInvsID
		for slot, quant in pairs(slotIDs) do
			local sourceSlot = slot
			--Figure out how many items
			--we can move in this
			--errand.
			local spaceInCurrStack = maxStack - willMove
			local moveThisErrand = math.min(amountLeft, spaceInCurrStack, quant)
			addFixedPushErrand(target, targetSlot, sourceID, sourceSlot, moveThisErrand, eName)
			amountLeft = amountLeft - moveThisErrand
			willMove = willMove + moveThisErrand
			if amountLeft == 0 or willMove == maxStack then
				break
			end
		end
		if amountLeft == 0 or willMove == maxStack then
			break
		end
	end
	return amountLeft
end

--Pulls everything from all slots of an
--inventory into the system.
local function pullAllSlots(target)
	if scanReturns[target] then
		for slotNum, slotData in pairs(scanReturns[target]) do
			if slotData then
				local amount = slotData.count
				local eName = mssU.nameEncode(slotData.name, slotData.nbt)
				addPullErrand(target, slotNum, amount, eName)
			end
		end
	end
end

--Completes an "output" task.
local function outputTask(taskTable)
	local amount = taskTable.amount
	local target = taskTable.target
	local eName = taskTable.eName
	local isDumb = taskTable.isDumb
	local amountLeft = amount
	if isDumb == nil then
		isDumb = true
	end
	if isDumb then
		amountLeft = dumbPushSpreader(target, eName, amount)
	else
		amountLeft = pushSpreader(target, eName, amount)
	end
	return amountLeft
end

--Completes an "export" task.
local function exportTask(taskTable)
	local amount = taskTable.amount
	local target = taskTable.target
	local eName = taskTable.eName
	local isDumb = taskTable.isDumb
	if isDumb == nil then
		isDumb = true
	end
	if isDumb then
		dumbPushSpreader(target, eName, amount)
	else
		pushSpreader(target, eName, amount)
	end
end

--Completes an "import" task.
local function importTask(taskTable)
	local target = taskTable.target
	local specificSlots = taskTable.specificSlots
	if specificSlots == nil then
		specificSlots = false
	end
	if specificSlots == false then
		pullAllSlots(target)
	else
		--TODO:
		--Implement the case where only
		--specific slots are pulled
		--from.
	end
end

--Completes a "supply" task.
local function supplyTask(taskTable)
	local target = taskTable.target
	local eName = taskTable.eName
	local amount = taskTable.amount
end

--From an ingredient list and a batch
--limit, determines the maximum amount
--of times we can craft a recipe with
--what's currently in storage.
local function maxCanCraft(ingTable, batchLim)
	--Expand out to find out how much
	--of each ingredient we need to do
	--one craft of the item.
	local ingAmounts = {}
	for _, ingData in pairs(ingTable) do
		if ingAmounts[ingData[1]] then
			ingAmounts[ingData[1]] = ingAmounts[ingData[1]] + ingData[2]
		else
			ingAmounts[ingData[1]] = ingData[2]
		end
	end
	--Divide the free amount off each
	--ingredient in the manifest by how
	--much this recipe needs, and
	--retain the lowest value we've
	--seen.
	local craftsPossible = math.huge
	for eName, amountPerCraft in pairs(ingAmounts) do
		craftsPossible = math.min(math.floor(manifest[eName]["reserved"] / ingAmounts[eName]), craftsPossible)
	end
	return craftsPossible
end

--Completes a "craft" task.
local function craftTask(taskTable)
	local eName = taskTable.eName
	local amount = taskTable.amount
	local amountLeft = amount
	local recipe = recipeList[eName]
	--Deletes invalid craft tasks.
	if not recipe then
		print("No recipe exists for "..eName.."!")
		return 0
	end
	--Determine if we can make a craft
	--of this item happen with what is
	--currently in the system.
	local maxCraft = maxCanCraft(recipe[3], recipe[2])
	local craftsToDo = math.ceil(amountLeft/recipe[1])
	maxCraft = math.min(maxCraft, craftsToDo)
	if maxCraft == 0 then
		return amountLeft
	end
	if recipe[4] == "craftingTable" then
		--Only attempt to craft this
		--type of recipe when no other
		--recipes of this type have
		--been allocated for this
		--iteration.
		local hasCraft = addCraftErrand()
		if hasCraft == true then
			return amountLeft
		end
		--Since we know for sure that
		--we can craft by now, do the
		--movement stuffs.
		for slot, iData in pairs(recipe[3]) do
			fixedPushSpreader(self, slot, iData[1], iData[2])
		end
		dumpInventory()
		amountLeft = amountLeft - recipe[1]
	end
	return amountLeft
end

--Partially merges the stacks for a
--provided item's encoded name.
local function combineStacks(eName)
	--Return early if no items exist.
	if manifest[eName]["total"] == 0 then
		return
	end
	local rawStacks = manifest[eName]["data"]
	local maxStack = manifest[eName]["maxStack"]
	local optimalStackCount = math.ceil(manifest[eName]["total"]/maxStack)
	local combinedStackGoal = optimalStackCount
	--We don't need to look at any
	--stacks that are full.
	local stacks = {}
	for invID, slots in pairs(rawStacks) do
		for slot, amount in pairs(slots) do
			if amount ~= maxStack then
				table.insert(stacks, {invID, slot, amount})
			else
				combinedStackGoal = combinedStackGoal - 1
			end
		end
	end
	--If there are no stacks to merge,
	--end execution here.
	if #stacks < 2 then
		return
	end
	local targetStacks = {}
	local sourceStacks = {}
	--Split stacks into "target" and
	--"source" stacks, taking from the
	--sources and adding them to the
	--targets.
	for cnt, stack in ipairs(stacks) do
		if cnt <= combinedStackGoal then
			table.insert(targetStacks, stack)
		else
			table.insert(sourceStacks, stack)
		end
	end
	local smallerStacksCount = math.min(#targetStacks, #sourceStacks)
	--Try to merge at most 1 target
	--stack into each source stack.
	for cnt = 1, smallerStacksCount do
		local sourceStack = sourceStacks[cnt]
		local sourceID = sourceStack[1]
		local sourceSlot = sourceStack[2]
		local sourceAmount = sourceStack[3]
		local targetStack = targetStacks[cnt]
		local targetID = targetStack[1]
		local targetSlot = targetStack[2]
		local targetAmount = targetStack[3]
		addCombineErrand(targetID, targetSlot, targetAmount, sourceID, sourceSlot, sourceAmount, maxStack, eName)
	end
end

--Calls combineStacks() on all items in
--the system.
local function massCombine()
	for eName, _ in pairs(manifest) do
		combineStacks(eName)
	end
end

--Condense task logic, basically a
--hard-coded special case of a craft
--task that executes entirely within a
--single main loop iteration.
local function condenseTask(condenseTableKey)
	local inputName = condenseTable[condenseTableKey][1]
	local condenseType = condenseTable[condenseTableKey][2]
	local outputName = condenseTable[condenseTableKey][3]
	local maxBatch = condenseTable[condenseTableKey][4]
	local amountFree = manifest[inputName]["free"]
	local crafts = 0
	local canDo = false
	if condenseType == "3x3" then
		local rawCrafts = math.floor(amountFree/9)
		crafts = math.min(rawCrafts, maxBatch)
		canDo = freeToReserved(inputName, crafts*9)
	elseif condenseType == "2x2" then
		local rawCrafts = math.floor(amountFree/4)
		crafts = math.min(rawCrafts, maxBatch)
		canDo = freeToReserved(inputName, crafts*4)
	else
		error(condenseType.." is not a valid condense type!",2)
	end
	if crafts == 0 or canDo == false then
		return
	end
	if condenseType == "3x3" then
		local insertSlots = {1,2,3,5,6,7,9,10,11}
		for _, slot in ipairs(insertSlots) do
			fixedPushSpreader(self, slot, inputName, crafts)
		end
		addCraftErrand()
		addPullErrand(self, 16, crafts, outputName)
	elseif condenseType == "2x2" then
		local insertSlots = {1,2,5,6}
		for _, slot in ipairs(insertSlots) do
			fixedPushSpreader(self, slot, inputName, crafts)
		end
		addCraftErrand()
		addPullErrand(self, 16, crafts, outputName)
	end
end

--Looks through the list of condensable
--items and picks one of them to
--condense, but only if no craft is
--scheduled for this main loop
--iteration.
local function findCondense()
	if shouldCraft then
		return
	end
	for condenseTableKey, entry in ipairs(condenseTable) do
		local minItems = math.huge
		if entry[2] == "3x3" then
			minItems = 9
		elseif entry[2] == "2x2" then
			minItems = 4
		end
		if manifest[entry[1]] then
			if manifest[entry[1]]["free"] >= minItems then
				condenseTask(condenseTableKey)
				return
			end
		end
	end
end

local earlyScanTypes = {}
earlyScanTypes["output"] = true
earlyScanTypes["export"] = true
earlyScanTypes["import"] = true
earlyScanTypes["supply"] = true

--Interprets the early stage of a task.
--Also handles the removal of completed
--tasks from masterTaskList.
local function interpretTaskEarly(taskTable, taskIndex)
	--If an output or craft task has no
	--items left to go, delete it.
	local taskType = taskTable.taskType
	if taskType == "output" or taskType == "craft" then
		if taskTable["amount"] <= 0 then
			print("A "..taskType.." task for "..taskTable.eName.." is totally done")
			masterTaskList[taskIndex] = nil
			return
		end
	end
	--If a scan is needed, add it to
	--the scan list.
	if earlyScanTypes[taskType] == true then
		local target = taskTable["target"]
		addScanErrand(target)
	elseif taskType == "craft" then
		--TODO:
		--Make scanning for craft tasks
		--dependent on the craft type.
	end
end

--Interprets the main body of a task.
local function interpretTask(taskTable, taskIndex)
	local taskType = taskTable.taskType
	if taskType == "output" then
		local amountLeft = outputTask(taskTable)
		masterTaskList[taskIndex]["amount"] = amountLeft
	elseif taskType == "export" then
		exportTask(taskTable)
	elseif taskType == "import" then
		importTask(taskTable)
	elseif taskType == "supply" then
		supplyTask(taskTable)
	elseif taskType == "craft" then
		local amountLeft = craftTask(taskTable)
		masterTaskList[taskIndex]["amount"] = amountLeft
	else
		error(taskType.." is not a valid task type!")
	end
end

--Interprets the early stage of every
--task in masterTaskList.
local function interpretTaskListEarly()
	for index, task in pairs(masterTaskList) do
		interpretTaskEarly(task, index)
	end
end

--Interprets the main body of every
--task in masterTaskList.
local function interpretTaskList()
	for index, task in pairs(masterTaskList) do
		interpretTask(task, index)
	end
end

--Job Stuff

--Loads manifestFile into memory, then
--adds and removes keys to each entry
--as to have it ready for the stuff
--done in checkCraftViability().
local function prepareCraftManifest()
	local craftManifest = loadDataFromDM()
	for eName, data in pairs(craftManifest) do
		--A little bit of memory saving
		--can be done here.
		data["maxStack"] = nil
		data["displayName"] = nil
		--Subs in the recipe if it has
		--one, otherwise nils it out.
		if data["hasRecipe"] then
			data["hasRecipe"] = recipeList[eName]
		else
			data["hasRecipe"] = nil
		end
		data["amountToTake"] = 0
		data["amountToMake"] = 0
		data["wantedTotal"] = 0
	end
	return craftManifest
end

--Sets amountToTake and amountToMake
--based on amount and wantedTotal for a
--given eName in the craftManifest.
local function distributeWantedTotal(eName, craftManifest)
	local cmEntry = craftManifest[eName]
	if cmEntry["wantedTotal"] <= cmEntry["amount"] then
		cmEntry["amountToTake"] = cmEntry["wantedTotal"]
	else
		cmEntry["amountToTake"] = cmEntry["amount"]
		cmEntry["amountToMake"] = cmEntry["wantedTotal"] - cmEntry["amount"]
	end
end

--Takes in an amount of an item, and
--returns how many times the recipe
--needs to be used to get at least that
--many of the item.
local function amountOfTimesToCraft(eName, amount)
	local recipe = recipeList[eName]
	local productAmount = recipe[1]
	local timesToCraft = math.ceil(amount/productAmount)
	return timesToCraft
end

--Multiplies all of the ingredient
--amounts in a given item's recipe by
--mult.
local function multIngredients(eName, mult)
	local recipe = recipeList[eName]
	local ingredientsList = recipe[3]
	local outList = {}
	for ingIndex, ingData in pairs(ingredientsList) do
		outList[ingIndex] = {ingData[1], ingData[2]*mult}
	end
	return outList
end

--
local function checkCraftViabilityStep(eName, amount, craftManifest)
	craftManifest[eName]["wantedTotal"] = craftManifest[eName]["wantedTotal"] + amount
	distributeWantedTotal(eName, craftManifest)
	if craftManifest[eName]["amountToMake"] > 0 then
		--If no recipe exists and we
		--need to craft it, pass back
		--up that it isn't possible.
		if not recipeList[eName] then
			return false
		end
		local craftsNeeded = amountOfTimesToCraft(eName, craftManifest[eName]["amountToMake"])
		local ingredientsToCheck = multIngredients(eName, craftsNeeded)
		for _, ingToCheck in pairs(ingredientsToCheck) do
			local stillPossible = checkCraftViabilityStep(ingToCheck[1], ingToCheck[2], craftManifest)
			--Pass the failure on.
			if not stillPossible then
				return false
			end
		end
	end
	return true
end

--Checks to see how many of the item we
--have in storage versus how many need
--to be crafted. Any that need to be
--crafted will have their ingredients
--checked by checkCraftViabilityStep().
--Also creates an effective copy of the
--display manifest in-memory to do this
--work.
--Will additionally make all of the
--craft tasks/jobs for this request if
--it is doable.
local function checkCraftViability(eName, amount)
	--This can be used to effectively
	--make a deep copy of the "free"
	--part of the manifest.
	local craftManifest = prepareCraftManifest()
	--We know that we want this
	--specific item already.
	craftManifest[eName]["wantedTotal"] = amount
	distributeWantedTotal(eName, craftManifest)
	if craftManifest[eName]["amountToMake"] > 0 then
		--If no recipe exists and we
		--need to craft it, pass back
		--up that it isn't possible.
		if not recipeList[eName] then
			return false
		end
		local craftsNeeded = amountOfTimesToCraft(eName, craftManifest[eName]["amountToMake"])
		local ingredientsToCheck = multIngredients(eName, craftsNeeded)
		for _, ingToCheck in pairs(ingredientsToCheck) do
			local stillPossible = checkCraftViabilityStep(ingToCheck[1], ingToCheck[2], craftManifest)
			--Pass the failure on.
			if not stillPossible then
				return false
			end
		end
	end
	--By reaching here, we know that
	--the entire request is doable.
	
	--Because this is the "master" of
	--the checking chain, if it turns
	--out that the craft is doable,
	--then we need to update the saved
	--manifestFile in case another
	--craft request is due for this
	--main loop iteration.
	for itemName, itemData in pairs(craftManifest) do
		if itemData["wantedTotal"] > 0 then
			if itemData["amountToTake"] > 0 then
				freeToReserved(itemName, itemData["amountToTake"])
			end
			if itemData["amountToMake"] > 0 then
				manifest[itemName]["pending"] = manifest[itemName]["pending"] + itemData["amountToMake"]
				table.insert(masterTaskList, {["taskType"] = "craft", ["eName"] = itemName, ["amount"] = itemData["amountToMake"]})
			end
		end
	end
	table.insert(masterTaskList, {["taskType"] = "output", ["eName"] = eName, ["amount"] = amount, ["target"] = clientExportBuffer})
	saveDisplayManifest()
	return true
end

--Client Request Interpretation

--Takes a file name, reads the request
--with said name, checks how doable it
--is, possibly adds a job or task for
--it, and also deletes the file.
local function readRequest(fileName)
	--Read the request from the file.
	local targetLoc = fs.combine(requestsDir, fileName)
	local textReq = ""
	local file = fs.open(targetLoc, "r")
	local line = ""
	local count = 1
	while line ~= nil do
		count = count + 1
		textReq = textReq..line
		line = file.read()
	end
	file.close()
	local requestData = textutils.unserialise(textReq)
	--Deletes the file that was just
	--read in.
	fs.delete(targetLoc)
	--Identify the computer we need to
	--send a rednet message to.
	local sender = rednet.lookup("mssClient", fileName)
	--Checks to see if we can satisfy
	--the request.
	--Currently does not factor in the
	--ppssibility of crafting stuff.
	if manifest[requestData["item"]] then
		if ensureItem(requestData["item"], requestData["amount"]) then
			freeToReserved(requestData["item"], requestData["amount"])
			local requestTask = {}
			requestTask["taskType"] = "output"
			requestTask["eName"] = requestData["item"]
			requestTask["amount"] = requestData["amount"]
			requestTask["target"] = clientExportBuffer
			table.insert(masterTaskList, requestTask)
			rednet.send(sender, true, "mssClient")
		else
			local checkCraft = checkCraftViability(requestData["item"], requestData["amount"])
			if checkCraft == true then
				rednet.send(sender, true, "mssClient")
			else
				rednet.send(sender, false, "mssClient")
			end
		end
	else
		rednet.send(sender, false, "mssClient")
	end
end

--Calls readRequest() on every file in
--requestsDir.
local function readAllRequests()
	local requestNames = fs.list(requestsDir)
	for _, fileName in pairs(requestNames) do
		readRequest(fileName)
	end
end

--Default Tasks

--Can get away with this task being
--hard-coded in, as the system should
--always have an importBuffer present.
local clientDumpImportTask = {}
clientDumpImportTask["taskType"] = "import"
clientDumpImportTask["target"] = importBuffer
clientDumpImportTask["specificSlots"] = false
table.insert(masterTaskList, clientDumpImportTask)

--[[
local procSysDumpImportTask = {}
procSysDumpImportTask["taskType"] = "import"
procSysDumpImportTask["target"] = "expandedstorage:chest_5"
procSysDumpImportTask["specificSlots"] = false
table.insert(masterTaskList, procSysDumpImportTask)
]]

--Main Server Loop

turtle.select(16)
initialiseManifest()
local testTask = {}
testTask["taskType"] = "supply"
testTask["eName"] = "minecraft:iron_block"
testTask["amount"] = 8
testTask["target"] = "expandedstorage:chest_3"
--testTask["isDumb"] = true
--masterTaskList[1] = testTask

print("Ready to go!")

local flipper = true

while true do
	readAllRequests()
	interpretTaskListEarly()
	--Finally got scanErrands to be
	--executed in parallel!
	mssU.batchedParallel(scanErrands)
	postScanWork()
	interpretTaskList()
	if flipper then
		massCombine()
		flipper = false
	else
		findCondense()
		flipper = true
	end
	executeAllErrands()
	--Make sure that manifestFile is
	--up-to-date with the latest
	--changes!
	saveDisplayManifest()
	--Sleep function so that we do not
	--accidentally forget to yield.
	--It would be better still to only
	--run this if and only if we have
	--no functions in masterFuncList.
	sleep(0.05)
end