local config = require("configFiles.config")

local dir = "recipes"

local masterRecipeList = {}

local recipeFiles = fs.list(dir)

--Add decondensing recipes based off of
--the condensing recipes.
--Can be overwritten later if needs be.
local cond = require(config.commonCodeDisk..".configFiles.condenseList")

if recipeFiles ~= {} then
	--Extract the recipeList table
	--contents from each recipe library
	--and disconnect them from their
	--source library.
	for index, fileName in ipairs(recipeFiles) do
		local l = require(dir.."."..fileName)
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