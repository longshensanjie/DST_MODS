local assets =
{
    Asset("ANIM", "anim/backcub.zip"),
    Asset("ANIM", "anim/swap_backcub.zip"),
    Asset("ATLAS", "images/inventoryimages/backcub.xml"),
    Asset("IMAGE", "images/inventoryimages/backcub.tex"),
}

local prefabs =
{
    "cookedsmallmeat",
    "furtuft",
}

local function toground(inst)
    -- inst.AnimState:PlayAnimation("anim", true)

    if inst.SoundEmitter then
        if inst.soundtask == nil then
            inst.soundtask = inst:DoPeriodicTask(4, function()
                inst.SoundEmitter:KillSound("sleep")
                inst.SoundEmitter:PlaySound("dontstarve/creatures/monkey/sleep", "sleep")
            end, 0)
        end
    end
end

local function onwork(owner)
    local x, y, z = owner.Transform:GetWorldPosition()
    print("获得人物坐标..x..y..z")
    local ents = TheSim:FindEntities(x, y, z, 20, { "harvestable" })
    local isHarvested = false
    -- local isPicked = false
    for k, obj in pairs(ents) do
        if obj:HasTag("beebox") then -- or obj:HasTag("honeyed")
            print("存在封箱")
            if obj.components.harvestable ~= nil and
                obj.components.harvestable.produce >= obj.components.harvestable.maxproduce then
                print("开始收获")
                obj.components.harvestable:Harvest(owner)
                isHarvested = true
            end 
        end
    end
    return isHarvested     
end

local function onequip(inst, owner)
    local symbol = owner.prefab == "webber" and "swap_body_tall" or "swap_body"
    owner.AnimState:OverrideSymbol(symbol, "swap_backcub", "swap_body")

    if inst.components.container ~= nil then
        inst.components.container:Open(owner)

        if inst.eattask == nil then
            inst.eattask = inst:DoPeriodicTask(60, function()
                local needwork = onwork(owner)
                if needwork then
                    local inv = owner and owner.components.inventory
                    local pack = inv:GetEquippedItem(EQUIPSLOTS.BODY)
                    if pack ~= nil and not pack.components.container:IsFull() and
                        inv ~= nil then
                        for k = 1, inv.maxslots do
                            local item = inv.itemslots[k]
                            if item and item.prefab == "honey" then
                                print("给到容器中")
                                local item2 = inv:RemoveItemBySlot(k)
                                pack.components.container:GiveItem(item2)
                            end
                        end
                    end
                else
                    if not TheWorld.state.isfullmoon then
                        if math.random() < 0.7 then
                            local finalitem = nil

                            inst.components.container:FindItem(function(item)
                                --只吃有新鲜度、食用组件的东西，防止吃掉糖豆、蜂巢、猪皮、眼球等
                                if item.components.edible ~= nil and item.components.perishable ~= nil then
                                    if item:HasTag("honeyed") then --带蜂蜜标签的食物优先度更高
                                        finalitem = item
                                        return true
                                    elseif finalitem == nil then --没有赋值过的才能赋值
                                        finalitem = item
                                        --这里不返回是为了在没找到蜂蜜类食物前继续找下去
                                    end
                                end
                                return false
                            end)

                            if finalitem ~= nil then
                                if finalitem.components.stackable ~= nil then
                                    finalitem.components.stackable:Get():Remove()
                                else
                                    finalitem:Remove()
                                end
                                if inst.SoundEmitter then
                                    inst.SoundEmitter:PlaySound("dontstarve/HUD/feed")
                                end

                                if math.random() < 0.15 then
                                    local fur = SpawnPrefab("furtuft")
                                    if fur ~= nil then
                                        fur.Transform:SetPosition(owner.Transform:GetWorldPosition())
                                        if fur.components.inventoryitem ~= nil then
                                            fur.components.inventoryitem:OnDropped(true)
                                        end
                                    end
                                end
                            end
                        end
                    else
                        local x1, y1, z1 = owner.Transform:GetWorldPosition()
                        local ents = TheSim:FindEntities(x1, y1, z1, 25, { "player" },
                            { "DECOR", "NOCLICK", "FX", "shadow", "playerghost", "INLIMBO" })

                        for i, ent in pairs(ents) do
                            if ent ~= owner and ent:IsValid() and ent.entity:IsVisible() and
                                ent.components.inventory ~= nil 
                            then
                                print("玩家存在")
                                local sugar = ent.components.inventory:FindItem(function(item)
                                    return item.components.edible ~= nil and
                                    item.components.edible.foodtype == FOODTYPE.GOODIES
                                end)

                                if sugar ~= nil then
                                    print("食物存在")
                                    local inv = owner and owner.components.inventory
                                    local pack = inv:GetEquippedItem(EQUIPSLOTS.BODY)
                                    local smallsugar = ent.components.inventory:DropItem(sugar, false)
                                    if smallsugar ~= nil then
                                        if pack.components.container:IsFull() then
                                            inv:GiveItem(smallsugar)
                                        else
                                            pack.components.container:GiveItem(smallsugar)
                                        end
                                    end

                                    if ent.components.talker ~= nil then
                                        ent.components.talker:Say("给你糖果就是了。")
                                    end
                                else
                                    owner.components.talker:Say("小熊只是想要甜甜的蜜心糖果。")   
                                end
                            end
                        end
                    end
                end
            end, 30)
        end
    end

    if inst.soundtask ~= nil then
        inst.soundtask:Cancel()
        inst.soundtask = nil
    end
    if inst.SoundEmitter then
        inst.SoundEmitter:KillSound("sleep")
    end
end

local function onunequip(inst, owner)
    if owner.prefab == "webber" then
        owner.AnimState:ClearOverrideSymbol("swap_body_tall")
    else
        owner.AnimState:ClearOverrideSymbol("swap_body")
    end

    if inst.components.container ~= nil then
        inst.components.container:Close(owner)
    end

    if inst.eattask ~= nil then
        inst.eattask:Cancel()
        inst.eattask = nil
    end

    -- if inst.harvesttask ~= nil then
    --     inst.harvesttask:Cancel()
    --     -- inst.harvesttask = nil
    -- end
end

-- local function onburnt(inst)
--     if inst.components.container ~= nil then
--         inst.components.container:DropEverything()
--         inst.components.container:Close()
--     end

--     SpawnPrefab("cookedsmallmeat").Transform:SetPosition(inst.Transform:GetWorldPosition())

--     inst:Remove()
-- end

-- local function onignite(inst)
--     if inst.components.container ~= nil then
--         inst.components.container.canbeopened = false
--     end
-- end

-- local function onextinguish(inst)
--     if inst.components.container ~= nil then
--         inst.components.container.canbeopened = true
--     end
-- end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    -- inst.Transform:SetScale(0.5, 0.5, 0.5)   --一旦这里改变动画大小，会导致火焰燃烧特效也跟着变化

    inst.MiniMapEntity:SetIcon("krampus_sack.png")

    inst.AnimState:SetBank("backcub")
    inst.AnimState:SetBuild("backcub")
    -- inst.AnimState:PlayAnimation("anim_water", true) --在海难的水里就用这个动画
    inst.AnimState:PlayAnimation("anim", true)

    inst:AddTag("backpack")
    inst:AddTag("fridge")
    inst:AddTag("waterproofer")
    inst:AddTag("NORATCHECK") --mod兼容：永不妥协。该道具不算鼠潮分

    --inst.foleysound = "dontstarve/movement/foley/backpack"

    --漂浮动画与地面动画的修改
    -- MakeInventoryFloatable(inst, "small", 0, nil, false, -9)
    -- inst.components.floater.OnLandedClient = function(self) --取消掉进海里时生成的波纹特效
    --     self.showing_effect = true
    -- end
    -- local OnLandedServer_old = inst.components.floater.OnLandedServer
    -- inst.components.floater.OnLandedServer = function(self) --掉进海里时使用自己的水面动画
    --     OnLandedServer_old(self)
    --     inst.AnimState:PlayAnimation(self:IsFloating() and "anim_water" or "anim", true)
    -- end
    -- local OnNoLongerLandedServer_old = inst.components.floater.OnNoLongerLandedServer
    -- inst.components.floater.OnNoLongerLandedServer = function(self) --非待在海里时使用自己的陆地动画
    --     OnNoLongerLandedServer_old(self)
    --     inst.AnimState:PlayAnimation(self:IsFloating() and "anim_water" or "anim", true)
    -- end

    -- inst:AddComponent("skinedlegion")
    -- inst.components.skinedlegion:InitWithFloater("backcub")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        inst.OnEntityReplicated = function(inst) inst.replica.container:WidgetSetup("krampus_sack") end     --直接用官方的slot需要主客机都申明一遍
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "backcub"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/backcub.xml"
    inst.components.inventoryitem.cangoincontainer = false

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BACK or EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("insulator")
    inst.components.insulator:SetInsulation(TUNING.INSULATION_LARGE)    --保暖达到牛帽的数值

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("krampus_sack")


    -- MakeSmallBurnable(inst)
    -- MakeSmallPropagator(inst)
    -- inst.components.burnable:SetOnBurntFn(onburnt)
    -- inst.components.burnable:SetOnIgniteFn(onignite)
    -- inst.components.burnable:SetOnExtinguishFn(onextinguish)

    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(0)

    inst:ListenForEvent("ondropped", toground)
    toground(inst)

    -- MakeHauntableLaunchAndDropFirstItem(inst)    --不能被作祟

    -- inst.components.skinedlegion:SetOnPreLoad()

    return inst
end

return Prefab("backcub_plus", fn, assets, prefabs)
