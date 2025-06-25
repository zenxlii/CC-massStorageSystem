local dir = "recipes"

local masterRecipeList = {}

local recipeFiles = fs.list(dir)

if recipeFiles ~= {} then
	--Extract the recipeList table
	--contents from each recipe library
	--and disconnect them from their
	--source library.
	for index, fileName in ipairs(recipeFiles) do
		local l = require(dir.."."..fileName)
	end
end