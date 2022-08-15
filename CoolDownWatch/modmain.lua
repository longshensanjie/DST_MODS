PrefabFiles = {
	"pocketwatch_shifting",
}

Assets = {
}

local Recipe = GLOBAL.Recipe

local level = GetModConfigData("CRAFT_COST")

local ingredients = {}

if level == 1 then
    ingredients = {
        Ingredient("pocketwatch_parts", 2),
        Ingredient("greengem", 1),
        Ingredient("walrus_tusk", 1),
    }
elseif level == 2 then
    ingredients = {
        Ingredient("pocketwatch_parts", 2),
        Ingredient("thulecite", 2),
        Ingredient("minotaurhorn", 1),
    }
else
    ingredients = {
        Ingredient("pocketwatch_parts", 2),
        Ingredient("moonglass", 2),
        Ingredient("steelwool", 4),
    }
end

local shifting_watch_recipe = AddRecipe("pocketwatch_shifting",
    ingredients,
	GLOBAL.CUSTOM_RECIPETABS.CLOCKMAKER, GLOBAL.TECH.MAGIC_TWO,
	{no_deconstruction = pocketwatch_no_deconstruction_fn}, nil, nil, nil, "clockmaker",
	"images/inventoryimages/pocketwatch_shifting.xml")
shifting_watch_recipe.sortkey = 99

local PocketWatch_CoolDown = GLOBAL.Action({ priority=0, mount_valid=true })
PocketWatch_CoolDown.id = "PocketWatch_CoolDown"
PocketWatch_CoolDown.str = "冷切"
PocketWatch_CoolDown.fn = function(act)
    local can_cooldown, reason = act.invobject.components.pocketwatch_cooldown:CanCoolDown(act.target, act.doer, act.invobject)
    if can_cooldown then
        print("判断是否能进行冷切成功")
        act.invobject.components.pocketwatch_cooldown:CoolDown(act.target, act.doer)
    end

    return can_cooldown, reason

end

AddAction(PocketWatch_CoolDown)

AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(PocketWatch_CoolDown, "dolongaction"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(PocketWatch_CoolDown, "dolongaction"))

AddComponentAction("USEITEM", "pocketwatch_cooldown", function(inst, doer, target, actions)
    if doer:HasTag("clockmaker") and target:HasTag("pocketwatch") then
        print("判断动作条件成功")
        table.insert(actions, GLOBAL.ACTIONS.PocketWatch_CoolDown)
    end
end)

local old_open = nil
local function onopen(inst)
    print("打开箱子")
    TUNING.IS_OPEN_CHEST = true
    if inst and inst.components.container then
        TUNING.OPEN_CHEST = inst
    end    
	if old_open then old_open(inst) end
end

AddPrefabPostInit("treasurechest", function(inst)
    if not GLOBAL.TheWorld.ismastersim then return inst end
	old_open = inst.components.container.onopenfn
	inst.components.container.onopenfn = onopen
end)
AddPrefabPostInit("dragonflychest", function(inst)
    if not GLOBAL.TheWorld.ismastersim then return inst end
	old_open = inst.components.container.onopenfn
	inst.components.container.onopenfn = onopen
end)
AddPrefabPostInit("pocketwatchpack", function(inst)
    if not GLOBAL.TheWorld.ismastersim then return inst end
	old_open = inst.components.container.onopenfn
	inst.components.container.onopenfn = onopen
end)

local old_close = nil
local function onclose(inst)
    print("关闭箱子")
    if inst and inst.components.container then
        TUNING.IS_OPEN_CHEST = false
    end
    if old_close then old_close(inst) end
end

AddPrefabPostInit("treasurechest", function(inst)
    if not GLOBAL.TheWorld.ismastersim then return inst end
	old_close = inst.components.container.onclosefn
	inst.components.container.onclosefn = onclose
end)
AddPrefabPostInit("dragonflychest", function(inst)
    if not GLOBAL.TheWorld.ismastersim then return inst end
	old_close = inst.components.container.onclosefn
	inst.components.container.onclosefn = onclose
end)
AddPrefabPostInit("pocketwatchpack", function(inst)
    if not GLOBAL.TheWorld.ismastersim then return inst end
	old_close = inst.components.container.onclosefn
	inst.components.container.onclosefn = onclose
end)


modimport("scripts/strings.lua")