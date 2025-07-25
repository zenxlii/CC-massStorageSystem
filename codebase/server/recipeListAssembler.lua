local config = require("configFiles.config")

local dir = "recipes"

local masterRecipeList = {}

local recipeFiles = fs.list(dir)

--Add decondensing recipes based off of
--the condensing recipes.
--Can be overwritten later if needs be.
local cond = require(config.commonCodeDisk..".configFiles.condenseList")

for _, cData in ipairs(cond.condenseTable) do
	--Write the recipe data in manually
	--to avoid any risks of pass-by-
	--reference screwing things up.
	if cData[2] == "3x3" then
		masterRecipeList[cData[1]] = {9, cData[4], {{cData[3], 1}}, "craftingTable"}
	elseif cData[2] == "2x2" then
		masterRecipeList[cData[1]] = {4, cData[4], {{cData[3], 1}}, "craftingTable"}
	else
		error("The condensing recipe for "..cData[1].." into "..cData[3].." has the unaccounted for recipe type of "..cData[2])
	end
end

--Add the contents of every file in the
--recipes/ directory to the
--masterRecipeList.
if recipeFiles ~= {} then
	--Extract the recipeList table
	--contents from each recipe library
	--and disconnect them from their
	--source library.
	for index, fileName in ipairs(recipeFiles) do
		print(fileName)
		local l = require(dir.."."..string.sub(fileName,1,-5))
		local recipeList = textutils.unserialise(textutils.serialise(l.recipeList))
		--Tricky little memory saving?
		l = nil
		
		for eName, recipeData in pairs(recipeList) do
			masterRecipeList[eName] = textutils.unserialise(textutils.serialise(recipeData))
		end
	end
end

return{
masterRecipeList = masterRecipeList
}