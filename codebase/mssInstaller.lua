local inString = ""

--A function that takes user input then
--lowercases it all.
local function getInput()
	return string.lower(io.read())
end

--Replaces whatever is at lineNumber in
--filePath with newContents.
--Probably not efficient for replacing
--many lines in the same file, but it
--would work.
--Not tested with appending whatsoever!
local function replaceLineInFile(filePath, lineNumber, newContents)
	--Read in the line-by-line data of
	--the file to be altered.
	local file = io.open(filePath, "r")
	local fileData = {}
	for line in file:lines() do
		table.insert(fileData, line)
	end
	io.close(file)
	--Now add in the substituted line.
	fileData[lineNumber] = newContents
	--Overwrite the file with the new
	--data.
	local file = io.open(filePath, "w")
	for index, value in ipairs(fileData) do
		file:write(value.."\n")
	end
	io.close(file)
end

--Takes in a string and wraps it in
--"'s.
local function stringWrap(inString)
	return "\""..inString.."\""
end

--Start by checking the directory
--structure of this computer.
--If it has massStorageSystem at the
--root of its local storage, then we
--have a prior install.
local installMode = false
if fs.exists("mssServer.lua") then
	while installMode == false do
		print("It seems that you have installed")
		print("massStorageSystem previously.")
		print("Would you like to:")
		print("Make a [F]resh install?")
		print("[U]pdate the existing installation?")
		print("[C]ancel this script's execution?")
		inString = getInput()
		if inString == "f" then
			
		elseif inString == "u" then
			installMode = "update"
		elseif inString == "c" then
			installMode = "cancel"
		else
			print("Not a valid value!")
		end
	end
else
	while installMode == false do
		print("Would you like to install")
		print("massStorageSystem? [Y]es or [N]o?")
		inString = getInput()
		if inString == "y" then
			installMode = "install"
		elseif inString == "n" then
			installMode = "cancel"
		else
			print("Not a valid value!")
		end
	end
end

local repo = "https://raw.githubusercontent.com/zenxlii/CC-massStorageSystem/refs/heads/main/codebase/"

--Returns true if this is an Advanced
--Crafty Turtle, and false otherwise.
local function checkIsAdvancedCraftyTurtle()
	--Turtle check.
	if not turtle then
		print("This is not a turtle!")
		return false
	end
	--Crafty check.
	if not turtle.craft then
		print("This is not crafty!")
		return false
	end
	--Advanced check.
	--NO IDEA YET.
	return true
end

--Looks for a Wired Modem next to this
--machine, returning the side of this
--modem if one is found.
--Returns false otherwise.
local function lookForWiredModem()
	local modemSide = false
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
	return modemSide
end

--Modified from the installer.lua file
--of CC-MISC.
--Downloads a file from the Internet
--and saves it to a specified location.
local function downloadFile(path, url)
	--print(string.format("Installing %s to %s", repo..url, path))
	local response = assert(http.get(repo..url, nil, true), "Failed to get " .. repo..url)
	local f = assert(fs.open(path, "wb"), "Cannot open file " .. path)
	f.write(response.readAll())
	f.close()
	response.close()
end

local function installMSS()
	term.clear()
	print("Thank you for choosing the")
	print("massStorageSystem for your base's")
	print("logistics and storage management needs!")
	--Check to see if the user has
	--installed this on the right kind
	--of turtle.
	local isACT = false
	while not isACT do
		print("")
		print("First, is this an Advanced Crafty")
		print("Turtle, and are you willing for this")
		print("machine to be the server turtle for")
		print("your massStorageSystem (MSS)?")
		print("[Y]es or [N]o.")
		inString = getInput()
		if inString == "y" then
			isACT = "yes"
		elseif inString == "n" then
			isACT = "no"
		else
			print("Not a valid value!")
		end
	end
	if isACT == "yes" then
		local continueInstall = checkIsAdvancedCraftyTurtle()
		if not continueInstall then
			term.clear()
			print("Installation process cancelled.")
			return
		end
	elseif isACT == "no" then
		term.clear()
		print("Installation process cancelled.")
		return
	else
		error("An invalid isACT of "..isACT.." was passed through somehow!")
	end
	--Ask the user to have a Wired
	--Modem hooked up to the ACT.
	local serverModemSide = false
	term.clear()
	print("Please place down a Wired Modem that is")
	print("adjacent to this turtle, and then right")
	print("click it to connect this turtle to the")
	print("network.")
	while not serverModemSide do
		serverModemSide = lookForWiredModem()
		--Modem open/closed check.
		if not peripheral.wrap(serverModemSide).getNameLocal() then
			serverModemSide = false
		end
		if serverModemSide then
			print("")
			print("Wired Modem found on the "..serverModemSide.." of this")
			print("computer! Would you like to use this")
			print("Wired Modem? [Y]es or [N]o.")
			inString = getInput()
			if inString == "n" then
				serverModemSide = false
			elseif inString ~= "y" then
				print("Not a valid value!")
			end
		end
		sleep(0.05)
	end
	term.clear()
	local mRef = peripheral.wrap(serverModemSide)
	local self = mRef.getNameLocal()
	--Ask the user to hook up a Disk
	--Drive (with storage) to the wired
	--network to use as the common code
	--storage disk.
	local commonCodeDrive = false
	while not commonCodeDrive do
		print("")
		print("Please connect a Disk Drive, with an")
		print("empty Floppy Disk inside.")
		print("Type in the peripheral name of this")
		print("Disk Drive.")
		print("This will be the common code storage")
		print("drive.")
		inString = getInput()
		if mRef.isPresentRemote(inString) then
			if mRef.getTypeRemote(inString) == "drive" then
				print("")
				print("Do you want to make the Disk Drive")
				print(inString)
				print("the common code storage drive?")
				print("[Y]es or [N]o.")
				commonCodeDrive = inString
				inString = getInput()
				if inString == "n" then
					commonCodeDrive = false
				elseif inString ~= "y" then
					commonCodeDrive = false
					print("Not a valid value!")
				end
			else
				print(inString)
				print("is not a disk drive!")
			end
		else
			print(inString)
			print("is not a present peripheral!")
		end
	end
	term.clear()
	local commonCodePath = false
	while not commonCodePath do
		print("")
		if not peripheral.wrap(commonCodeDrive).isDiskPresent() then
			print("No disk is inserted.")
			print("Please insert a blank Floppy Disk into")
			print(commonCodeDrive..".")
			print("Press enter to proceed.")
			getInput()
		elseif not peripheral.wrap(commonCodeDrive).getMountPath() then
			print("Something other than a data storage")
			print("device is inserted inside of")
			print(commonCodeDrive..".")
			print("Please insert a blank Floppy Disk into")
			print("this Disk Drive instead.")
			print("Press enter to proceed.")
			getInput()
		else
			commonCodePath = peripheral.wrap(commonCodeDrive).getMountPath()
			if fs.getCapacity(commonCodePath) == fs.getFreeSpace(commonCodePath) then
				print(commonCodePath)
				print("is now the common code storage disk!")
			else
				print("This Floppy Disk is not empty. Do you")
				print("still want to use this as the common")
				print("code storage disk? [Y]es or [N]o.")
				inString = getInput()
				if inString == "n" then
					commonCodePath = false
				elseif inString ~= "y" then
					print("Not a valid value!")
					commonCodePath = false
				else
					print(commonCodePath)
					print("is now the common code storage disk!")
				end
			end
		end
	end
	term.clear()
	--Ask the user to hook up a Disk
	--Drive (with storage) to the wired
	--network to use as the standard
	--manifest storage disk.
	local manifestDrive = false
	while not manifestDrive do
		print("")
		print("Please connect a Disk Drive, with an")
		print("empty Floppy Disk inside.")
		print("Type in the peripheral name of this")
		print("Disk Drive.")
		print("This will be the manifest file storage")
		print("drive.")
		inString = getInput()
		if mRef.isPresentRemote(inString) then
			if mRef.getTypeRemote(inString) == "drive" then
				print("")
				print("Do you want to make the Disk Drive")
				print(inString)
				print("the manifest file storage drive?")
				print("[Y]es or [N]o.")
				manifestDrive = inString
				inString = getInput()
				if inString == "n" then
					manifestDrive = false
				elseif inString ~= "y" then
					manifestDrive = false
					print("Not a valid value!")
				end
			else
				print(inString)
				print("is not a disk drive!")
			end
		else
			print(inString)
			print("is not a present peripheral!")
		end
	end
	term.clear()
	local manifestPath = false
	while not manifestPath do
		print("")
		if not peripheral.wrap(manifestDrive).isDiskPresent() then
			print("No disk is inserted.")
			print("Please insert a blank Floppy Disk into")
			print(manifestDrive..".")
			print("Press enter to proceed.")
			getInput()
		elseif not peripheral.wrap(manifestDrive).getMountPath() then
			print("Something other than a data storage")
			print("device is inserted inside of")
			print(manifestDrive..".")
			print("Please insert a blank Floppy Disk into")
			print("this Disk Drive instead.")
			print("Press enter to proceed.")
			getInput()
		else
			manifestPath = peripheral.wrap(manifestDrive).getMountPath()
			if fs.getCapacity(manifestPath) == fs.getFreeSpace(manifestPath) then
				print(manifestPath)
				print("is now the manifest file storage disk!")
			else
				print("This Floppy Disk is not empty. Do you")
				print("still want to use this as the manifest")
				print("file storage disk? [Y]es or [N]o.")
				inString = getInput()
				if inString == "n" then
					manifestPath = false
				elseif inString ~= "y" then
					print("Not a valid value!")
					manifestPath = false
				else
					print(manifestPath)
					print("is now the manifest file storage disk!")
				end
			end
		end
	end
	term.clear()
	--Ask the user to identify which
	--inventory they want to use as the
	--client import buffer.
	local importBuffer = false
	while not importBuffer do
		print("")
		print("Please connect a chest-like inventory")
		print("to this turtle's wired network, and")
		print("then type in the peripheral name of it.")
		print("This will be the client item import")
		print("buffer inventory.")
		inString = getInput()
		if mRef.isPresentRemote(inString) then
			if mRef.hasTypeRemote(inString, "inventory") then
				print("")
				print("Do you want to make the inventory")
				print(inString)
				print("the import buffer inventory?")
				print("[Y]es or [N]o.")
				importBuffer = inString
				inString = getInput()
				if inString == "n" then
					importBuffer = false
				elseif inString ~= "y" then
					importBuffer = false
					print("Not a valid value!")
				end
			else
				print(inString)
				print("is not an inventory!")
			end
		else
			print(inString)
			print("is not a present peripheral!")
		end
	end
	term.clear()
	--Ask the user to identify which
	--inventory they want to use as the
	--client export buffer.
	local exportBuffer = false
	while not exportBuffer do
		print("")
		print("Please connect a chest-like inventory")
		print("to this turtle's wired network, and")
		print("then type in the peripheral name of it.")
		print("This will be the client item export")
		print("buffer inventory.")
		inString = getInput()
		--Special case to prevent the
		--import and export buffers
		--from being the exact same
		--inventory.
		if inString == importBuffer then
			print("")
			print("The import and export buffers cannot be")
			print("the same inventory!")
		elseif mRef.isPresentRemote(inString) then
			if mRef.hasTypeRemote(inString, "inventory") then
				print("")
				print("Do you want to make the inventory")
				print(inString)
				print("the export buffer inventory?")
				print("[Y]es or [N]o.")
				exportBuffer = inString
				inString = getInput()
				if inString == "n" then
					exportBuffer = false
				elseif inString ~= "y" then
					exportBuffer = false
					print("Not a valid value!")
				end
			else
				print(inString)
				print("is not an inventory!")
			end
		else
			print(inString)
			print("is not a present peripheral!")
		end
	end
	term.clear()
	--Ask the user to identify which
	--inventory they want to use as
	--their system's first general
	--storage inventory.
	local startingGenStorage = false
	while not startingGenStorage do
		print("")
		print("Please connect a chest-like inventory")
		print("to this turtle's wired network, and")
		print("then type in the peripheral name of it.")
		print("This will be the initial general item")
		print("storage inventory.")
		inString = getInput()
		--Special case to prevent the
		--import and export buffers
		--from being the exact same
		--inventory.
		if inString == importBuffer then
			print("")
			print("The import buffer and general storage")
			print("cannot be the same inventory!")
		elseif inString == exportBuffer then
			print("")
			print("The export buffer and general storage")
			print("cannot be the same inventory!")
		elseif mRef.isPresentRemote(inString) then
			if mRef.hasTypeRemote(inString, "inventory") then
				print("")
				print("Do you want to make the inventory")
				print(inString)
				print("the first general storage inventory?")
				print("[Y]es or [N]o.")
				startingGenStorage = inString
				inString = getInput()
				if inString == "n" then
					startingGenStorage = false
				elseif inString ~= "y" then
					startingGenStorage = false
					print("Not a valid value!")
				end
			else
				print(inString)
				print("is not an inventory!")
			end
		else
			print(inString)
			print("is not a present peripheral!")
		end
	end
	term.clear()
	--This should be all of the
	--initial peripherals defined by
	--now, so next we can create the
	--directory structure.
	fs.makeDir("configFiles/")
	fs.makeDir("recipes/")
	fs.makeDir(commonCodePath.."/configFiles/")
	fs.makeDir(commonCodePath.."/requests/")
	--Next, download the actual files.
	print("Downloading files now...")
	downloadFile("configFiles/config.lua", "defaultConfigs/defaultConfig.lua")
	downloadFile("mssServer.lua", "server/mssServer.lua")
	downloadFile("recipeListLoader.lua", "server/recipeListLoader.lua")
	downloadFile("configFiles/storageList.lua", "defaultConfigs/defaultStorageList.lua")
	downloadFile("configFiles/bussin.lua", "defaultConfigs/defaultBussin.lua")
	downloadFile(commonCodePath.."/mssClient.lua", "client/mssClient.lua")
	downloadFile(commonCodePath.."/configFiles/allowedShorthands.lua", "defaultConfigs/defaultAllowedShorthands.lua")
	downloadFile(commonCodePath.."/mssUtils.lua", "common/mssUtils.lua")
	downloadFile(commonCodePath.."/configFiles/condenseList.lua", "defaultConfigs/defaultCondenseList.lua")
	downloadFile(commonCodePath.."/configFiles/config.lua", "defaultConfigs/defaultConfig.lua")
	downloadFile(commonCodePath.."/makeClient.lua", "client/makeClient.lua")
	--In-Development Stuff:
	downloadFile("recipeCoreDefs.lua", "server/recipeCoreDefs.lua")
	downloadFile("recipeListAssembler.lua", "server/recipeListAssembler.lua")
	downloadFile("recipes/craftingTable.lua", "server/craftingTable.lua")
	print("File download is done!")
	--Also need to construct a config
	--file or two.
	replaceLineInFile("configFiles/storageList.lua", 5, stringWrap(startingGenStorage))
	replaceLineInFile(commonCodePath.."/configFiles/config.lua", 9, "local manifestDisk = "..stringWrap(manifestPath))
	replaceLineInFile(commonCodePath.."/configFiles/config.lua", 14, "local commonCodeDisk = "..stringWrap(commonCodePath))
	replaceLineInFile(commonCodePath.."/configFiles/config.lua", 22, "local importBuffer = "..stringWrap(importBuffer))
	replaceLineInFile(commonCodePath.."/configFiles/config.lua", 31, "local clientExportBuffer = "..stringWrap(exportBuffer))
	replaceLineInFile("configFiles/config.lua", 9, "local manifestDisk = "..stringWrap(manifestPath))
	replaceLineInFile("configFiles/config.lua", 14, "local commonCodeDisk = "..stringWrap(commonCodePath))
	replaceLineInFile("configFiles/config.lua", 22, "local importBuffer = "..stringWrap(importBuffer))
	replaceLineInFile("configFiles/config.lua", 31, "local clientExportBuffer = "..stringWrap(exportBuffer))
	print("Line replacement is done!")
	--Make a startup.lua file for the
	--server turtle.
	local newFile = io.open("startup.lua", "w")
	newFile:write("shell.run(\"mssServer.lua\")")
	io.close(newFile)
	print("Restarting...")
	sleep(5)
	os.reboot()
end

--Basically a cut-down version of
--installMSS(), as this only installs
--the non-config files.
local function updateMSS()
	term.clear()
	local confirmCheck = false
	while not confirmCheck do
		print("Would you like to update your")
		print("installation of massStorageSystem?")
		print("This will delete and re-download the")
		print("main code files (but not config files).")
		print("[Y]es or [N]o.")
		inString = getInput()
		if inString == "y" then
			confirmCheck = "yes"
		elseif inString == "n" then
			confirmCheck = "no"
		else
			print("Not a valid value!")
		end
	end
	if confirmCheck == "no" then
		print("Cancelling...")
		return
	elseif confirmCheck ~= "yes" then
		error("An invalid confirmCheck of "..confirmCheck.." was passed through!")
	end
	--With confirmation now known, we
	--can delete the old code files.
	--But first, we need to find which
	--disk is which.
	local config = require("configFiles.config")
	local commonCodePath = config.commonCodeDisk
	--Now actually delete the files.
	fs.delete("mssServer.lua")
	fs.delete("recipeListLoader.lua")
	fs.delete(commonCodePath.."/mssClient.lua")
	fs.delete(commonCodePath.."/mssUtils.lua")
	--Download fresh files now.
	downloadFile("mssServer.lua", "server/mssServer.lua")
	downloadFile("recipeListLoader.lua", "server/recipeListLoader.lua")
	downloadFile(commonCodePath.."/mssClient.lua", "client/mssClient.lua")
	downloadFile(commonCodePath.."/mssUtils.lua", "common/mssUtils.lua")
	print("Update complete!")
	print("Please restart the client turtles.")
end

if installMode == "cancel" then
	print("Cancelling...")
	return
elseif installMode == "install" then
	installMSS()
elseif installMode == "update" then
	updateMSS()
	--error("Updating hasn't been implemented yet!")
elseif installMode == "remove" then
	error("Uninstallation hasn't been implemented yet!")
elseif installMode == "makeClient" then
	error("Easy client setup hasn't been implemented yet!")
else
	error("An invalid installMode of "..installMode.." was passed through somehow!")
end






