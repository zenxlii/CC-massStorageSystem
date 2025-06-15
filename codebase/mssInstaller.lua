local inString = ""

--A function that takes user input then
--lowercases it all.
local function getInput()
	return string.lower(io.read())
end

--Start by checking the directory
--structure of this computer.
--If it has massStorageSystem at the
--root of its local storage, then we
--have a prior install.
local installMode = false
if fs.exists("massStorageSystem") then
	while installMode == false then
		print("It seems that you have installed")
		print("massStorageSystem previously.")
		print("Would you like to:")
		print("Make a [F]resh install?")
		print("[U]pdate the existing installation?")
		print("[C]ancel this script's execution?")
		inString = getInput()
		if inString == "f" then
			
		elseif inString == "u" then
			
		elseif inString == "c" then
			installMode = "cancel"
		else
			print("Not a valid value!")
		end
	end
else
	while installMode == false then
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

local function installMSS()
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
			print("Installation process cancelled."
			return
		end
	elseif isACT == "no" then
		print("Installation process cancelled.")
		return
	else
		error("An invalid isACT of "..isACT.." was passed through somehow!")
	end
	--Ask the user to have a Wired
	--Modem hooked up to the ACT.
	local serverModemSide = false
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
	--Ask the user to identify which
	--inventory they want to use as the
	--client import buffer.
	local importBuffer = false
	while not importBuffer do
		print("")
		print("Please connect a chest-like inventory")
		print("to this turtle's wired network, and")
		print("then type in the peripheral name of it.")
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
	--Ask the user to identify which
	--inventory they want to use as the
	--client export buffer.
	local exportBuffer = false
	while not exportBuffer do
		print("")
		print("Please connect a chest-like inventory")
		print("to this turtle's wired network, and")
		print("then type in the peripheral name of it.")
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
end

if installMode == "cancel" then
	print("Cancelling...")
	return
elseif installMode == "install" then
	installMSS()
elseif installMode == "update" then
	error("Updating hasn't been implemented yet!")
else
	error("An invalid installMode of "..installMode.." was passed through somehow!")
end






