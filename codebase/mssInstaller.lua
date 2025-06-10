







local repo = "https://raw.githubusercontent.com/zenxlii/CC-massStorageSystem/refs/heads/main/codebase/"

local inString = ""
local installType = false
while not installType do
	print("What would you like to install?")
	print("Input 'C' for the client.")
	print("Input 'S' for the server.")
	print("Input 'A' to just download it all.")
	inString = string.lower(io.read())
	if inString == "c" then
		installType = "client"
	elseif inString == "s" then
		installType = "server"
	elseif inString == "a" then
		installType = "all"
	else
		inString = false
		print(inString.." is not a valid response.")
	end
end
