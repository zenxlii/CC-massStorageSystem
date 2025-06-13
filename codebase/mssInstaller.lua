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

if installMode == "cancel" then
	return
end






local repo = "https://raw.githubusercontent.com/zenxlii/CC-massStorageSystem/refs/heads/main/codebase/"


local installType = false
while not installType do
	print("What would you like to install?")
	print("Input 'C' for the client.")
	print("Input 'S' for the server.")
	print("Input 'B' for the basic, shared configuration files.")
	print("Input 'A' to just download it all.")
	inString = string.lower(io.read())
	if inString == "c" then
		installType = "client"
	elseif inString == "s" then
		installType = "server"
	elseif inString == "b" then
		installType = "basic"
	elseif inString == "a" then
		installType = "all"
	else
		inString = false
		print(inString.." is not a valid response.")
	end
end

local filesToDownload = {}
if installType == "client" then
	filesToDownload["mssClient.lua"] = repo.."client/mssClient.lua"
	filesToDownload["allowedShorthands.lua"] = repo.."client/allowedShorthands.lua"
elseif installType == "server" then
	filesToDownload["mssServer.lua"] = repo.."server/mssServer.lua"
	filesToDownload["mssServerConfig.lua"] = repo.."server/mssServerConfigBlank.lua"
elseif installType == "basic" then
	
elseif installType == "all" then
	
else
	error("Picked an invalid installType somehow")
end