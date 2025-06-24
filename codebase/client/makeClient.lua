local config = require("configFiles.config")
local commonCodeDisk = config.commonCodeDisk
local inString = ""

--A function that takes user input then
--lowercases it all.
local function getInput()
	return string.lower(io.read())
end

local shouldWrite = false
while not shouldWrite do
	print("Do you want to replace the startup.lua")
	print("file for this Advanced Turtle so that")
	print("it runs mssClient.lua automatically?")
	print("[Y]es or [N]o?")
	inString = getInput()
		if inString == "y" then
			shouldWrite = "yes"
		elseif inString == "n" then
			shouldWrite = "no"
		else
			print("Not a valid value!")
		end
end

if shouldWrite == "yes" then
	local newFile = io.open("startup.lua", "w")
	newFile:write("shell.run(\""..commonCodeDisk.."/mssClient.lua\")")
	io.close(newFile)
	print("Restarting...")
	sleep(5)
	os.reboot()
elseif shouldWrite == "no" then
	print("Cancelling...")
	return
end