
local prefabs =
{
    "spoiled_food",
}

local function MakePreparedFood(data)
    local realname = data.basename or data.name
    local foodassets =
	{
		Asset("ANIM", "anim/"..realname..".zip"),
		Asset("INV_IMAGE", data.name),
	}
	

	
    table.insert(foodassets, Asset("ANIM", "anim/"..realname..".zip"))
    table.insert(foodassets, Asset("ATLAS", "images/"..realname..".xml"))
    table.insert(foodassets, Asset("IMAGE", "images/"..realname..".tex"))
    table.insert(foodassets, Asset("ATLAS_BUILD", "images/"..realname..".xml", 256))
	

	local spicename = data.spice ~= nil and string.lower(data.spice) or nil
    if spicename ~= nil then
        --table.insert(foodassets, Asset("ANIM", "anim/"..data.overridebuild..".zip"))
        
        table.insert(foodassets, Asset("ANIM", "anim/spices.zip"))
        table.insert(foodassets, Asset("ANIM", "anim/plate_food.zip"))
        table.insert(foodassets, Asset("INV_IMAGE", spicename.."_over"))
    end

    local foodprefabs = prefabs
    if data.prefabs ~= nil then
        foodprefabs = shallowcopy(prefabs)
        for i, v in ipairs(data.prefabs) do
            if not table.contains(foodprefabs, v) then
                table.insert(foodprefabs, v)
            end
        end
    end

    local function DisplayNameFn(inst)
        return subfmt(STRINGS.NAMES[data.spice.."_FOOD"], { food = STRINGS.NAMES[string.upper(data.basename)] })
    end

    local function OnUpgrade(item, doer, target, result)
        if result.SoundEmitter ~= nil then
            result.SoundEmitter:PlaySound("dontstarve/common/place_structure_straw")
        end

        --将原箱子中的物品转移到新箱子中
        if target.components.container ~= nil and result.components.container ~= nil then
            target.components.container:Close() --强制关闭使用中的箱子
            target.components.container.canbeopened = false
            local allitems = target.components.container:RemoveAllItems()
            for i,v in ipairs(allitems) do
                result.components.container:GiveItem(v)
            end
        end
    
        item:Remove() --该道具是一次性的
    end

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

		--local food_symbol_build = nil
        if spicename ~= nil then
            inst.AnimState:SetBuild("plate_food")
            inst.AnimState:SetBank("plate_food")
            inst.AnimState:OverrideSymbol("swap_garnish", "spices", spicename)

            inst:AddTag("spicedfood")
            inst.drawnameoverride = STRINGS.NAMES[string.upper(realname)]
            inst.inv_image_bg = { atlas = "images/"..realname..".xml", image = realname..".tex" }
            

			--food_symbol_build = data.overridebuild or realname
        else
			inst.AnimState:SetBuild(realname)
			inst.AnimState:SetBank(realname)
        end

        inst.AnimState:PlayAnimation("idle")
        inst.AnimState:OverrideSymbol("swap_food", realname, realname)

        inst:AddTag("preparedfood")
        if data.tags ~= nil then
            for i,v in pairs(data.tags) do
                inst:AddTag(v)
            end
        end

        if data.basename ~= nil then
            inst:SetPrefabNameOverride(data.basename)
            if data.spice ~= nil then
                inst.displaynamefn = DisplayNameFn
            end
        end

        if data.floater ~= nil then
            MakeInventoryFloatable(inst, data.floater[1], data.floater[2], data.floater[3])
        else
            MakeInventoryFloatable(inst)
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

		--inst.food_symbol_build = data.overridebuild or realname

        inst:AddComponent("edible")
        inst.components.edible.healthvalue = data.health
        inst.components.edible.hungervalue = data.hunger
        inst.components.edible.foodtype = data.foodtype or FOODTYPE.GENERIC
        inst.components.edible.secondaryfoodtype = data.secondaryfoodtype or nil
        inst.components.edible.sanityvalue = data.sanity or 0
        inst.components.edible.temperaturedelta = data.temperature or 0
        inst.components.edible.temperatureduration = data.temperatureduration or 0
        inst.components.edible.nochill = data.nochill or nil
        inst.components.edible.spice = data.spice
        inst.components.edible:SetOnEatenFn(data.oneatenfn)

        inst:AddComponent("inspectable")
        inst.wet_prefix = data.wet_prefix

        inst:AddComponent("inventoryitem")
        

        if spicename ~= nil then
            inst.components.inventoryitem:ChangeImageName(spicename.."_over")
        elseif data.basename ~= nil then
            inst.components.inventoryitem:ChangeImageName(data.basename)
        else
            inst.components.inventoryitem.atlasname = "images/"..realname..".xml"
            inst.components.inventoryitem.imagename = realname
        end

        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

        if data.perishtime ~= nil and data.perishtime > 0 then
            inst:AddComponent("perishable")
            inst.components.perishable:SetPerishTime(data.perishtime)
            inst.components.perishable:StartPerishing()
            inst.components.perishable.onperishreplacement = "spoiled_food"
        end

        inst:AddComponent("upgradekit")
        inst.components.upgradekit:SetData({
            backcub =
            {
                prefabresult = "backcub_plus",
                onupgradefn = OnUpgrade,
            }
        })

        MakeSmallBurnable(inst)
        MakeSmallPropagator(inst)
        MakeHauntableLaunchAndPerish(inst)
        ---------------------

        inst:AddComponent("bait")

        ------------------------------------------------
        inst:AddComponent("tradable")

        ------------------------------------------------

        return inst
    end

    return Prefab(data.name, fn, foodassets, foodprefabs)
end

local prefs = {}

for k, v in pairs(require("foods")) do
    table.insert(prefs, MakePreparedFood(v))
end

for k, v in pairs(require("foodspicer")) do
    table.insert(prefs, MakePreparedFood(v))
end

return unpack(prefs)
