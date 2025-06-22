--Imports
local strLib = require("cc.strings")
local config = require("config")
local mssU = require("mssUtils")
local sh = require("allowedShorthands")

local batchSize = config.batchSize

local manifestFile = config.manifestFile
local requestsDir = config.requestsDir

local importBuffer = config.importBuffer
local clientExportBuffer = config.clientExportBuffer

--local self = "turtle_"..os.getComputerID()
local self = peripheral.find("modem").getNameLocal()

local selfRequestFile = fs.combine(requestsDir, self)

local modemSide = config.modemSide

--Set up this turtle for receiving
--rednet messages.
rednet.open(modemSide)
rednet.host("mssClient", self)

--TODO:
--Prettify the numbers for display
--purposes.

--Returns the input number to 3 sig.
--figures and the x10^(power) value
--needed to get back to the original
--input number.
--Only works for natural numbers!
--And zero doesn't count!
--Technically needs an input number
--that is at least 100 to work.
local function sfAndPow(natNum)
	local nStr = tostring(natNum)
	local power = #nStr - 1
	local sf = string.sub(nStr,1,3)
	return nStr, sf, power
end

local function makeCompactNotation(sf, power)
	local outStr = ""
	if power % 3 == 0 then
		outStr = string.sub(sf,1,1).."."..string.sub(sf,2,3)
	elseif power % 3 == 1 then
		outStr = string.sub(sf,1,2).."."..string.sub(sf,3,3)
	elseif power % 3 == 2 then
		outStr = sf
	end
	if power < 7 then
		outStr = outStr.."K"
	elseif power < 10 then
		outStr = outStr.."M"
	elseif power < 13 then
		outStr = outStr.."G"
	elseif power > 12 then
		term.clear()
		term.setCursorPos(1,1)
		error("Why do you have over 100 billion of an item?")
	end
	return outStr
end

--Adds suffixes like "K" and "M" to
--the supplied number as appropriate.
local function displayConverter(natNum)
	local nStr, sf, power = sfAndPow(natNum)
	if natNum < 1000 then
		return nStr
	else
		return makeCompactNotation(sf, power)
	end
end

--The manifest that gets shown in the
--UI of this program.
local displayManifest = {}

--Reads the display manifest from the
--shared disk drive and updates the
--displayManifest variable.
local function readDisplayManifest()
	--Load the file's data into memory.
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
	displayManifest = textutils.unserialise(dmSerial)
	--Add the missing maxStack and
	--hasRecipe values back in.
	for eName, data in pairs(displayManifest) do
		if data["maxStack"] == nil then
			data["maxStack"] = 64
		end
		if data["hasRecipe"] == nil then
			data["hasRecipe"] = false
		end
	end
end

--Goes through displayManifest and
--removes any entries with an amount of
--0 and lack an installed recipe.
local function removeEmptyManifestEntries()
	for eName, entry in pairs(displayManifest) do
		if entry["amount"] == 0 and entry["hasRecipe"] == false then
			displayManifest[eName] = nil
		end
	end
end

--An indexed list of encoded names in
--the manifest, ordered alphabetically
--by their display names.
local sortedNames = {}

--The substring to search for in the
--display names of items in the system.
local searchString = ""

--The text that should be shown in the
--search bar.
--NOT THE SAME AS searchString!!!!!!!!!
local searchBarText = ""

--A version of sortedNames that only
--contains entries for items with
--display names that match the current
--searchString.
local filteredSortedNames = {}

--
local filteredEntryCount = 0

--
local filteredHighestPage = 0

--The number of items to be shown per
--page of the item list.
local pageSize = 10

--The number of entries within the
--displayManifest.
local entryCount = 0

--The highest page number that can be
--reached with this current manifest.
local highestPage = 0

--The page of the item list that is
--being shown right now.
local currPage = 0

--The index in sortedNames that is
--currently selected.
local currSelIndex = false

--The amount of items this client will
--attempt to draw if commanded to right
--this moment.
--Is hard-coded to never go above 9999.
local drawAmount = 1

--Manifest-like table which has keys
--for the items that a request wants,
--and values for how many are left to
--take before it is satisfied.
local thingsToTake = {}

--The event ID of the currently-active
--timer event, which is used for things
--like auto-scrolling text displays.
local currTimerID = false

--Either contains the display name for
--the item that's in focus (if the
--item's name is 14 characters long or
--shorter) or the display name with
--"|    " appended to it so that it
--looks nicer when scrolled, as well as
--a second copy of the name as to allow
--for continuous scrolling.
local focusCardNameText = ""

--The first character of the variable
--focusCardNameText to show in the
--text readout at this point in time.
local focusCardNameScrollPos = 1

local function setFocusCardNameText()

end

--Fills and sorts sortedNames, as well
--as setting some key variables for
--later referencing.
local function sortDisplayNames()
	--Blank out sortedNames and fill it
	--with all the display names.
	sortedNames = {}
	for eName, entry in pairs(displayManifest) do
		entry["displayAmount"] = displayConverter(entry["amount"])
		table.insert(sortedNames, {entry["displayName"], eName, ""})
	end
	--Sort sortedNames alphabetically.
	table.sort(sortedNames, function(k1, k2) return k1[1] < k2[1] end)
	--Sets some key variables about the
	--manifest's size.
	entryCount = #sortedNames
	highestPage = math.ceil(entryCount / pageSize)
end

local function applySearchFilter()
	local lcSearch = string.lower(searchString)
	filteredSortedNames = {}
	for index, entry in ipairs(sortedNames) do
		local caselessDName = string.lower(entry[1])
		local caselessDNameShort = string.lower(entry[3])
		--Accounts for finding the
		--search string in either the
		--full display name or the
		--shortened display name.
		if string.find(caselessDName, lcSearch) or string.find(caselessDNameShort, lcSearch) then
			table.insert(filteredSortedNames, {entry[1], entry[2], entry[3]})
		end
	end
	filteredEntryCount = #filteredSortedNames
	filteredHighestPage = math.ceil(filteredEntryCount / pageSize)
	currPage = math.min(1, filteredHighestPage)
	currSelIndex = false
end

local function resetSearch()
	searchBarText = ""
	searchString = ""
	applySearchFilter()
end

--Calls readDisplayManifest() followed
--by sortDisplayNames().
local function readAndSort()
	readDisplayManifest()
	removeEmptyManifestEntries()
	sortDisplayNames()
	resetSearch()
end

--

--GUI Drawing Functions

--Renamed Shorthands
local function pos(...) return term.setCursorPos(...) end
local function cls(...) return term.clear() end
local function tCol(...) return term.setTextColour(...) end
local function bCol(...) return term.setBackgroundColour(...) end
local function box(...) return paintutils.drawFilledBox(...) end
local function line(...) return paintutils.drawLine(...) end 
local x,y = term.getSize()

--Button Stuff

--List of all buttons in this GUI.
--Used to help with input detection.
local masterButtonList = {}

--Convenience function that defines a
--button.
local function defButton(buttonName,topLeft,topRight,botLeft,botRight,colour,textX,textY,text,shouldDraw)
	masterButtonList[buttonName] = {topLeft,topRight,botLeft,botRight,colour,textX,textY,text,shouldDraw}
end

--Draws the box for a button and then
--puts the text in there for it.
local function drawButton(button)
	box(button[1],button[2],button[3],button[4],button[5])
	pos(button[6],button[7])
	write(button[8])
end

--Goes through tbe button list to find
--which button, if any, was pressed in
--a given mouse click event.
--Returns the name of the button that
--pressed, or false if no button was
--pressed.
local function findButtonPressed(mouseX, mouseY)
	for buttonName, buttonData in pairs(masterButtonList) do
		if mouseX >= buttonData[1] and mouseX <= buttonData[3] and mouseY >= buttonData[2] and mouseY <= buttonData[4] then
			return buttonName
		end
	end
	return false
end

--Define the stuff about each button.
defButton("previousPage",1,13,4,13,colours.grey,1,13,"Prev",true)
defButton("nextPage",22,13,25,13,colours.grey,22,13,"Next",true)
defButton("addOne",27,11,28,11,colours.grey,27,11,"++",true)
defButton("addTen",32,11,33,11,colours.grey,32,11,"++",true)
defButton("addStack",37,11,38,11,colours.grey,37,11,"++",true)
defButton("subOne",27,13,28,13,colours.grey,27,13,"--",true)
defButton("subTen",32,13,33,13,colours.grey,32,13,"--",true)
defButton("subStack",37,13,38,13,colours.grey,37,13,"--",true)
defButton("sendRequest",26,9,39,9,colours.grey,27,9,"SEND REQUEST",true)
defButton("select1",1,2,25,2,0,0,0,0,false)
defButton("select2",1,3,25,3,0,0,0,0,false)
defButton("select3",1,4,25,4,0,0,0,0,false)
defButton("select4",1,5,25,5,0,0,0,0,false)
defButton("select5",1,6,25,6,0,0,0,0,false)
defButton("select6",1,7,25,7,0,0,0,0,false)
defButton("select7",1,8,25,8,0,0,0,0,false)
defButton("select8",1,9,25,9,0,0,0,0,false)
defButton("select9",1,10,25,10,0,0,0,0,false)
defButton("select10",1,11,25,11,0,0,0,0,false)
defButton("refresh",33,7,39,7,colours.grey,33,7,"Refresh",true)
defButton("dump",9,13,17,13,colours.grey,9,13,"Dump Inv.",true)

--Item List Drawing Stuff

local function drawItemListBackground()
	--Make the text white.
	tCol(colours.white)
	--Draw the page count background.
	box(1,12,25,13,colours.lightGrey)
	--Draw the page count text.
	pos(9,12)
	write("Page "..currPage.."/"..filteredHighestPage)
	--Draw the item list background.
	box(1,2,25,11,colours.blue)
end

local function rightAlignItemListNumbers(inVal, column)
	local stringVal = tostring(inVal)
	if #stringVal < 6 then
		pos(26-#stringVal,column)
		write(stringVal)
	else
		cls()
		error("Item amount number (after shortening) was too long!")
	end
end

local function drawItemList()
	drawItemListBackground()
	--Make a special case for if there
	--are zero items present in the
	--storage system.
	if entryCount == 0 then
		pos(1,6)
		write("You have no items :(")
		return
	end
	--Another special case for if no
	--items fit the current search.
	if filteredEntryCount == 0 and searchString ~= "" then
		pos(1,6)
		write("No items fit your search")
		return
	end
	--Figure out the page offset and
	--how many items to show.
	local pageOffset = pageSize * (currPage - 1)
	local entriesToShow = pageSize
	if currPage == filteredHighestPage then
		entriesToShow = filteredEntryCount % pageSize
		if entriesToShow == 0 then
			entriesToShow = pageSize
		end
	end
	--Draw the text for the items on
	--this page.
	for cnt = 1, entriesToShow do
		local globalIndex = cnt + pageOffset
		local names = filteredSortedNames[globalIndex]
		local dName = names[1]
		--Stops the item name from
		--running over into other areas
		--of the GUI.
		if #dName > 19 then
			dName = string.sub(dName,1,19)
		end
		local amount = displayManifest[names[2]]["displayAmount"]
		--If this happens to be the
		--selected index, highlight it.
		if globalIndex == currSelIndex then
			box(1,1+cnt,25,1+cnt,colours.white)
			tCol(colours.black)
			bCol(colours.white)
		end
		pos(1,1+cnt)
		write(dName)
		pos(20,1+cnt)
		write("|")
		rightAlignItemListNumbers(amount, 1+cnt)
		tCol(colours.white)
		bCol(colours.blue)
	end
end

--Call this when trying to scroll below
--page 0 or above the page limit.
local function drawPageWarning(highLow)
	box(1,12,25,13,colours.black)
	tCol(colours.yellow)
	pos(7,12)
	write("!!WARNING!!")
	pos(1,13)
	write("Can't move to that page!")
	sleep(1)
	while true do
		local eventData = {os.pullEvent()}
		if eventData[1] == "mouse_click" or eventData[1] == "key" then
			break
		end
	end
end

local function drawFocusNameText(isNewText)
	if isNewText then
		os.cancelTimer(currTimerID)
		focusCardNameScrollPos = 1
	else
		
	end
end

local function drawFocusCardItem()
	--Draw the in-focus item card.
	--This depends on how many of the
	--selected item are in storage,
	--compared to the draw amount.
	local boxColour = colours.red
	local currSelAmount = "No Selection"
	if currSelIndex then
		currSelAmount = displayManifest[filteredSortedNames[currSelIndex][2]]["amount"]
		if drawAmount <= currSelAmount then
			boxColour = colours.green
		end
		
	end
	box(26,2,26,8,colours.lightGrey)
	box(27,2,39,8,boxColour)
	tCol(colours.white)
	--Writes the amount text.
	pos(27,4)
	write("Amount:")
	pos(27,5)
	write(currSelAmount)
	--Writes the name text.
	pos(27,2)
	write("Name:")
	drawFocusNameText(true)
	--Informs the user that this item
	--is craftable by the system.
	if currSelIndex then
		if displayManifest[filteredSortedNames[currSelIndex][2]]["hasRecipe"] then
			pos(26,8)
			write("Craftable!")
		end
	end
end

local function drawFocusCardAmount()
	--Draw the space where the amount
	--to draw will be shown, as well as
	--the amount changing buttons.
	box(26,10,39,13,colours.lightGrey)
	--Draw the draw amount text.
	pos(26,10)
	write("To get:")
	pos(36,10)
	--Pads the number with leading 0's.
	if drawAmount < 10 then
		write("000"..drawAmount)
	elseif drawAmount < 100 then
		write("00"..drawAmount)
	elseif drawAmount < 1000 then
		write("0"..drawAmount)
	else
		write(drawAmount)
	end
	--Draw the amount change texts.
	pos(28,12)
	write(1)
	pos(32,12)
	write(10)
	pos(37,12)
	write(64)
end

--Call this whenever drawAmount exceeds
--9999 or is below 0.
local function drawAmountWarning(highLow)
	box(26,11,39,13,colours.black)
	tCol(colours.yellow)
	pos(26,11)
	write("!!WARNING!!")
	pos(26,12)
	write("Amount is too")
	pos(26,13)
	if highLow == "high" then
		write("high! 9999 max")
		pos(36,10)
		tCol(colours.white)
		bCol(colours.lightGrey)
		write(9999)
		drawAmount = 9999
	elseif highLow == "low" then
		write("low! 0 minimum")
		pos(36,10)
		tCol(colours.white)
		bCol(colours.lightGrey)
		write("0000")
		drawAmount = 0
	end
	sleep(1)
	while true do
		local eventData = {os.pullEvent()}
		if eventData[1] == "mouse_click" or eventData[1] == "key" then
			break
		end
	end
end

local function drawFocusCard()
	drawFocusCardItem()
	drawFocusCardAmount()
end

--Writes the contents of searchBarText
--into the search bar.
local function writeSearchBarText()
	pos(8,1)
	tCol(colours.white)
	bCol(colours.grey)
	--Check to see how long the current
	--searchBarText is, so that we can
	--truncate it if it gets too long.
	if #searchBarText > 32 then
		write(string.sub(searchBarText, #searchBarText-31))
	else
		write(searchBarText)
	end
end

local function drawSearchBar()
	tCol(colours.white)
	box(1,1,7,1,colours.lightGrey)
	pos(1,1)
	write("Search:")
	box(8,1,x,1,colours.grey)
	--With the bar itself drawn, now we
	--can write the user-provided text.
	writeSearchBarText()
end

local function drawAllButtons()
	for _, button in pairs(masterButtonList) do
		if button[9] == true then
			drawButton(button)
		end
	end
end

--Call this when a request is attempted
--and there is no item selected.
local function requestNoSelectWarning()
	box(26,7,39,9,colours.black)
	pos(26,7)
	tCol(colours.yellow)
	write("!!WARNING!!")
	pos(26,8)
	write("No item is")
	pos(26,9)
	write("selected!")
	sleep(1)
	while true do
		local eventData = {os.pullEvent()}
		if eventData[1] == "mouse_click" or eventData[1] == "key" then
			break
		end
	end
end

--Draws the basic layout of the GUI.
--Literally draws the whole thing.
--It is suggested that this is only
--called when refreshing the state of
--displayManifest.
local function drawGUI()
	--Clears the screen and ensures
	--that the cursor is at the
	--top-left corner of the display.
	cls()
    pos(1,1)
	tCol(colours.white)
	drawSearchBar()
	drawItemList()
	drawFocusCard()
	
	drawAllButtons()
	pos(8,1)
end

--Tick Consuming Functions

--Dumps every item in the turtle's
--inventory into the designated dumping
--inventory.
local function dumpInventory()
	local doesTurtleHaveItems = true
	local selfContents = {}
	local funcs = {}
	local dumpInv =mssU.fastWrap(importBuffer)
	for cnt = 1,16 do
		table.insert(funcs, function() 
			dumpInv.pullItems(self, cnt)
		end)
		table.insert(funcs, function()
			selfContents[cnt] = turtle.getItemDetail(cnt)
		end)
	end
	--Keeps trying to push everything
	--out of this turtle until it is
	--actually empty.
	local iterCount = 0
	while doesTurtleHaveItems do
		iterCount = iterCount + 1
		doesTurtleHaveItems = false
		mssU.batchedParallel(funcs)
		for cnt, data in pairs(selfContents) do
			doesTurtleHaveItems = true
		end
		--Emergency break in case the
		--dumping inventory isn't being
		--emptied.
		if iterCount >= 100 then
			cls()
			error("Could not dump the client's inventory into the system!")
		end
	end
end

local exportPeri = mssU.fastWrap(clientExportBuffer)

--Is called by pullRequests() when a
--requested item is in the export
--buffer. Only updates thingsToTake
--after the items are moved.
local function pullForRequest(eName, slotNum)

end

--Will attempt to pull whatever items
--this client has requested when it is
--called, updating thingsToTake as it
--takes the items in.
local function pullRequests()
	for eName, quant in pairs(thingsToTake) do
		if quant == 0 then
			thingsToTake[eName] = nil
		end
	end
	local exportScan = exportPeri.list()
	for slotNum, iData in pairs(exportScan) do
		local eName = mssU.nameEncode(iData["name"], iData["nbt"])
		if thingsToTake[eName] then
			local movedAmount = exportPeri.pushItems(self, slotNum, thingsToTake[eName])
			thingsToTake[eName] = thingsToTake[eName] - movedAmount
			if thingsToTake[eName] == 0 then
				thingsToTake[eName] = nil
			end
			break
		end
	end
end

--Smart wrapper for pullRequests() that
--only calls pullRequests() if this
--client has any outstanding requests.
local function tryPullRequests()
	if thingsToTake ~= {} then
		pullRequests()
	else
		sleep(0.05)
	end
end

--Infinite loop of tryPullRequests().
local function permaTPR()
	while true do
		tryPullRequests()
	end
end

--Message box that appears while
--waiting for the server to interpret
--the last message that we sent.
local function makeRequestWaitingBox()
	box(10,5,29,9,colours.black)
	pos(11,6)
	tCol(colours.white)
	write("Waiting for")
	pos(11,7)
	write("a response...")
end

local function makeRequestSuccessBox()
	box(10,5,29,9,colours.black)
	pos(11,6)
	tCol(colours.white)
	write("The request was")
	pos(11,7)
	write("successful!")
	sleep(0.2)
	while true do
		local eventData = {os.pullEvent()}
		if eventData[1] == "mouse_click" or eventData[1] == "key" then
			break
		end
	end
end

local function makeRequestFailBox()
	box(10,5,29,9,colours.black)
	pos(11,6)
	tCol(colours.white)
	write("The request was")
	pos(11,7)
	write("unsuccessful...")
	sleep(0.2)
	while true do
		local eventData = {os.pullEvent()}
		if eventData[1] == "mouse_click" or eventData[1] == "key" then
			break
		end
	end
end

--Function that handles when a new
--search needs to be done.
local function evalNewSearch()
	searchString = searchBarText
	applySearchFilter()
	drawGUI()
end

--Button Stuff Part 2

local function evalPreviousPage()
	--Prevents underflows.
	if currPage <= 1 then
		drawPageWarning("low")
		return
	end
	currPage = currPage - 1
end

local function evalNextPage()
	--Prevents overflows.
	if currPage == filteredHighestPage then
		drawPageWarning("high")
		return
	end
	currPage = currPage + 1
end

local function evalAddOne()
	drawAmount = drawAmount + 1
	--Prevents it going past 9999.
	if drawAmount > 9999 then
		drawAmountWarning("high")
	end
end

local function evalAddTen()
	drawAmount = drawAmount + 10
	--Prevents it going past 9999.
	if drawAmount > 9999 then
		drawAmountWarning("high")
	end
end

local function evalAddStack()
	drawAmount = drawAmount + 64
	--Prevents it going past 9999.
	if drawAmount > 9999 then
		drawAmountWarning("high")
	end
end

local function evalSubOne()
	drawAmount = drawAmount - 1
	--Prevents it going below 0.
	if drawAmount < 0 then
		drawAmountWarning("low")
	end
end

local function evalSubTen()
	drawAmount = drawAmount - 10
	--Prevents it going below 0.
	if drawAmount < 0 then
		drawAmountWarning("low")
	end
end

local function evalSubStack()
	drawAmount = drawAmount - 64
	--Prevents it going below 0.
	if drawAmount < 0 then
		drawAmountWarning("low")
	end
end

local function evalSelect(slot)
	local tryIndex = slot + (currPage - 1) * 10
	if tryIndex <= filteredEntryCount then
		currSelIndex = tryIndex
		--setFocusCardNameText(currSelIndex)
	end
end

local function evalRefresh()
	readAndSort()
	drawGUI()
	pos(8,1)
end

local function evalDump()
	dumpInventory()
end

local function evalSendRequest()
	--Stops things early if you've not
	--selected an item.
	if currSelIndex == false then
		requestNoSelectWarning()
		return
	end
	--Makes a file that contains the
	--data of the request.
	local eName = filteredSortedNames[currSelIndex][2]
	local requestTable = {}
	requestTable["item"] = eName
	requestTable["amount"] = drawAmount
	local textReq = textutils.serialise(requestTable)
	local file = fs.open(selfRequestFile, "w")
	file.write(textReq)
	file.close()
	
	makeRequestWaitingBox()
	--Waits for the server to respond,
	--saying that it has received the
	--request, and if it can be done or
	--not.
	local id, message = rednet.receive("mssClient", 5)
	if message == true then
		
		if thingsToTake[eName] then
			thingsToTake[eName] = thingsToTake[eName] + drawAmount
		else
			thingsToTake[eName] = drawAmount
		end
		makeRequestSuccessBox()
	elseif message == false then
		makeRequestFailBox()
	else
		error("An invalid message was received!")
	end
	
	--Now refresh the whole UI and
	--stuff because we've just changed
	--the manifest on the server.
	readAndSort()
end

--If a button in the GUI is pressed,
--identify which one it was and then
--execute its associated function.
local function evaluateButtonPress(button)
	if button == "previousPage" then
		evalPreviousPage()
	elseif button == "nextPage" then
		evalNextPage()
	elseif button == "addOne" then
		evalAddOne()
	elseif button == "addTen" then
		evalAddTen()
	elseif button == "addStack" then
		evalAddStack()
	elseif button == "subOne" then
		evalSubOne()
	elseif button == "subTen" then
		evalSubTen()
	elseif button == "subStack" then
		evalSubStack()
	elseif button == "sendRequest" then
		evalSendRequest()
	elseif button == "select1" then
		evalSelect(1)
	elseif button == "select2" then
		evalSelect(2)
	elseif button == "select3" then
		evalSelect(3)
	elseif button == "select4" then
		evalSelect(4)
	elseif button == "select5" then
		evalSelect(5)
	elseif button == "select6" then
		evalSelect(6)
	elseif button == "select7" then
		evalSelect(7)
	elseif button == "select8" then
		evalSelect(8)
	elseif button == "select9" then
		evalSelect(9)
	elseif button == "select10" then
		evalSelect(10)
	elseif button == "refresh" then
		evalRefresh()
	elseif button == "dump" then
		evalDump()
	end
	--Redraw the entire GUI just to be
	--on the safe side.
	drawGUI()
end

--Main Functions
local escapeTrigger = false

local function mainLoop()
	--Get the events as they come in.
	local eventData = {os.pullEvent()}
    local event = eventData[1]
	
    if event == "mouse_click" then
        --print("Button", eventData[2], "was clicked at", eventData[3], ",", eventData[4])
		if eventData[2] == 1 then
			local pressedButton = findButtonPressed(eventData[3], eventData[4])
			evaluateButtonPress(pressedButton)
		end
	elseif event == "key" and keys.getName(eventData[2]) == "enter" then
		evalNewSearch()
	elseif event == "key" and keys.getName(eventData[2]) == "backspace" then
		if searchBarText ~= "" then
			searchBarText = string.sub(searchBarText, 1, #searchBarText-1)
		end
		drawSearchBar()
    elseif event == "char" then
		local charPressed = eventData[2]
		searchBarText = searchBarText..charPressed
		writeSearchBarText()
	elseif event == "timer"
		
    end
end

--Shortcut function that runs all of
--the "main" functions in parallel.
local function mainLoopParalleliser()
	local mainFuncs = {}
	table.insert(mainFuncs, function()
		while escapeTrigger == false do
			mainLoop()
		end
	end)
	table.insert(mainFuncs, function()
		while escapeTrigger == false do
			tryPullRequests()
		end
	end)
	parallel.waitForAll(table.unpack(mainFuncs))
end

local function main()
	--Initialise everything.
	readAndSort()
	drawGUI()
	--Run the main loop.
	mainLoopParalleliser()
end

main()