GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})
local G = GLOBAL

PrefabFiles = { "pocketwatchpack" }
Assets = {
	Asset("ATLAS", "images/inventoryimages/pocketwatchpack.xml")
}

local level = GetModConfigData("CRAFT_COST")

local ingredients = {}

if level == 1 then
    ingredients = {
        Ingredient("pocketwatch_dismantler", 1),
        Ingredient("greengem", 2),
        Ingredient("slurper_pelt", 6),
    }
elseif level == 2 then
    ingredients = {
        Ingredient("pocketwatch_dismantler", 1),
        Ingredient("opalpreciousgem", 1),
        Ingredient("bearger_fur", 1),
    }
else
    ingredients = {
        Ingredient("pocketwatch_dismantler", 1),
        Ingredient("shadowheart", 1),
        Ingredient("krampus_sack", 1),
    }
end

modimport("scripts/main/watch_container.lua")
AddRecipe("pocketwatchpack",
	ingredients,
	GLOBAL.CUSTOM_RECIPETABS.CLOCKMAKER,
	GLOBAL.TECH.MAGIC_TWO,
	nil, nil, nil, nil,
	"clockmaker",
	"images/inventoryimages/pocketwatchpack.xml", 
	"pocketwatchpack.tex"
)

STRINGS.NAMES.POCKETWATCHPACK = "怀表工具袋"
STRINGS.RECIPE_DESC.POCKETWATCHPACK = "收纳时间"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.POCKETWATCHPACK = "蕴含暗影的力量"
