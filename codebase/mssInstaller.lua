







local repo = "https://raw.githubusercontent.com/zenxlii/CC-massStorageSystem/refs/heads/main/codebase/"

local inString = ""
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