local assets = {
	Asset("ANIM", "anim/pocketwatchpack.zip"),
	Asset("ATLAS", "images/inventoryimages/pocketwatchpack.xml") 
}

local prefabs = {}

local function onopen(inst)
end

local function onclose(inst)
	local owner = inst and inst.components and inst.components.inventoryitem and inst.components.inventoryitem.owner or nil
	local container = owner and owner.components and owner.components.inventory and owner.components.inventory:GetOverflowContainer() or nil
	if container ~= nil then
		container:Open(owner)
	end
end

local function ondropped(inst)
	if inst.components.container ~= nil then
		inst.components.container:Close()
	end
end

local function RestoreWatchs(inst)
	for k, v in pairs(inst.components.container.slots) do
		if v.components.pocketwatch then
			if v:HasTag("pocketwatch") and not v.components.pocketwatch.inactive and v.GetActionVerb_CAST_POCKETWATCH ~= "WARP"
				and not v.components.weapon then
				print("start restore cooldown watch ")
				local percent = v.components.rechargeable:GetPercent()
				print(percent)
				if percent < 1 then
					if (v.GetActionVerb_CAST_POCKETWATCH == "REVIVER") then
						percent = math.min(1, percent + 0.5 / (TUNING.POCKETWATCH_REVIVE_COOLDOWN / TUNING.BOOKSTATION_RESTORE_TIME / 2))
						print("reviver watch start set percent")
						print(percent)
						v.components.rechargeable:SetPercent(percent)
					else if (v:HasTag("recall_unmarked") and "RECALL_MARK" or "RECALL") then
							percent = math.min(1, percent + 0.5 / (TUNING.POCKETWATCH_RECALL_COOLDOWN / TUNING.BOOKSTATION_RESTORE_TIME / 2))
							print("recall watch start set percent")
							print(percent)
							v.components.rechargeable:SetPercent(percent)
						else if (v.GetActionVerb_CAST_POCKETWATCH == "COOLDOWN") then
								percent = math.min(1, percent + 0.5 / (TUNING.POCKETWATCH_RECALL_COOLDOWN / TUNING.BOOKSTATION_RESTORE_TIME / 2))
								print("coolddown watch start set percent")
								print(percent)
								v.components.rechargeable:SetPercent(percent)
							else
								percent = math.min(1, percent + 0.5 / (TUNING.POCKETWATCH_HEAL_COOLDOWN / TUNING.BOOKSTATION_RESTORE_TIME / 2))
								print("heal watch start set percent")
								print(percent)
								v.components.rechargeable:SetPercent(percent)
							end
						end

					end
				end
			end
		end
	end
end

local function ItemGet(inst)
    if inst.RestoreTask == nil then
        if inst.components.container:HasItemWithTag("pocketwatch", 1) then
			print("jian ting item get success")
            inst.RestoreTask = inst:DoPeriodicTask(TUNING.BOOKSTATION_RESTORE_TIME, RestoreWatchs)
        end
    end
end

local function ItemLose(inst)
    if not inst.components.container:HasItemWithTag("pocketwatch", 1) then
		print("jian ting item  lose success")
        if inst.RestoreTask ~= nil then
            inst.RestoreTask:Cancel()
            inst.RestoreTask = nil
        end
    end
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("pocketwatchpack")
	inst.AnimState:SetBuild("pocketwatchpack")
	inst.AnimState:PlayAnimation("idle")

	MakeInventoryFloatable(inst)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")
	
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.imagename = "pocketwatchpack"
	inst.components.inventoryitem.atlasname = "images/inventoryimages/pocketwatchpack.xml"
	inst.components.inventoryitem.canonlygoinpocket = true -- can't store a pocket watch bag into a backpack etc
	inst.components.inventoryitem.keepondeath = true
	inst.components.inventoryitem.keepondrown = true
	inst.components.inventoryitem:SetOnDroppedFn(ondropped)

	inst:AddComponent("container")
	inst.components.container:WidgetSetup("pocketwatchpack")
	--inst.components.container.onopenfn = onopen
	inst.components.container.onclosefn = onclose

	inst:ListenForEvent("itemget", ItemGet)
    inst:ListenForEvent("itemlose", ItemLose)
	
	MakeHauntableLaunchAndDropFirstItem(inst)

	return inst
end

return Prefab("pocketwatchpack", fn, assets, prefabs)