local assets = {
	Asset("ANIM", "anim/pocketwatch_shifting.zip"),

	Asset("ATLAS", "images/inventoryimages/pocketwatch_shifting.xml"),
	Asset("IMAGE", "images/inventoryimages/pocketwatch_shifting.tex"),
}

local prefabs =
{
	"pocketwatch_cast_fx",
	"pocketwatch_cast_fx_mount",
}

local MOUNTED_CAST_TAGS = { "pocketwatch_mountedcast" }

local function OnCharged(inst)
	if inst.components.pocketwatch ~= nil then
		inst.components.pocketwatch.inactive = true
		inst.AnimState:PlayAnimation("idle")
	end
end

local function GetStatus(inst)
	return (inst.components.rechargeable ~= nil and not inst.components.rechargeable:IsCharged()) and "RECHARGING" or nil
end

local function OnDropped(inst)
	inst.AnimState:PlayAnimation("idle")
	local rechargeable = inst.components.rechargeable
	if rechargeable ~= nil and not rechargeable:IsCharged() then
		inst.AnimState:PlayAnimation(rechargeable.chargetime > 4 and "cooldown_long" or "cooldown_short")
		local anim_length = inst.AnimState:GetCurrentAnimationLength()
		inst.AnimState:SetTime(anim_length * rechargeable:GetPercent())
		inst.AnimState:SetDeltaTimeMultiplier(anim_length / rechargeable.chargetime)
	end
end

local function OnDischarged(inst)
	if inst.components.pocketwatch ~= nil then
		inst.components.pocketwatch.inactive = false
	end
	OnDropped(inst)
end

local function DoCastSpell(inst)
	local count = 0
	local owner = inst.components.inventoryitem.owner
	local inv = owner and owner.components.inventory
	if not inv then
		print("backpack")
		owner = inst.components.inventoryitem:GetGrandOwner()
		inv = owner and owner.components.inventory
	end
	local table = {}
	if inv then
		for k = 1, inv.maxslots do
			local item = inv.itemslots[k]
			if item and item.components.pocketwatch and not item.components.pocketwatch.inactive then
				print("正在cd的表存在")
				if item.components.pocketwatch_cooldown or item.GetActionVerb_CAST_POCKETWATCH == "WARP" or item.components.weapon then
				else
					count = count + 1
					if count == 1 then
						table[count] = item
					end
				end
			end
		end

		local pack = inv:GetEquippedItem(EQUIPSLOTS.BODY)
		print("inv 存在")

		if pack and pack.components.container then
			print("pack 存在")
			for k = 1, pack.components.container.numslots do
				local item = pack.components.container.slots[k]
				if item and item.components.pocketwatch and not item.components.pocketwatch.inactive then
					print("正在cd的表存在")
					if item.components.pocketwatch_cooldown or item.GetActionVerb_CAST_POCKETWATCH == "WARP" or item.components.weapon then
					else
						count = count + 1
						if count == 1 then
							table[count] = item
						end
					end
				end
			end
		end
	end

	print(TUNING.OPEN_CHEST_POCKETWATCH_NUM)
	print(count)

	if TUNING.OPEN_CHEST_POCKETWATCH_NUM == 1 and TUNING.OPEN_CHEST_POCKETWATCH and not TUNING.OPEN_CHEST_POCKETWATCH[1].inactive and count < 1 then
		print("打开的箱子里存在一个满足条件的表")
		TUNING.OPEN_CHEST_POCKETWATCH[1].components.pocketwatch.inactive = true
		TUNING.OPEN_CHEST_POCKETWATCH[1].components.rechargeable:Discharge(0)
		inst.components.rechargeable:Discharge(TUNING.POCKETWATCH_RECALL_COOLDOWN)
		return true
	end


	if  TUNING.IS_OPEN_CHEST then
		if TUNING.OPEN_CHEST and TUNING.OPEN_CHEST.components.container then
			for k = 1, TUNING.OPEN_CHEST.components.container:GetNumSlots() do
				local item = TUNING.OPEN_CHEST.components.container.slots[k]
				if item and item.components.pocketwatch and not item.components.pocketwatch.inactive then
					print("正在cd的表存在")
					if item.components.pocketwatch_cooldown or item.GetActionVerb_CAST_POCKETWATCH == "WARP" or item.components.weapon then
						print("当前表不是可以冷切的表类型")
					else
						print("当前表是可以冷切的表类型")
						count = count + 1
						if count == 1 then
							table[count] = item
						end
					end
				end
			end
		end
	end

	if count == 1 and table[count] then
		print("只存在一个满足条件的表")
		print(TUNING.OPEN_CHEST_POCKETWATCH_NUM)
		table[count].components.pocketwatch.inactive = true
		table[count].components.rechargeable:Discharge(0)
		inst.components.rechargeable:Discharge(TUNING.POCKETWATCH_RECALL_COOLDOWN)
		return true
	end


	count = 0
	table = nil
	-- We return true regardless of the result so that we don't do a generic fail line.
	return false
end

local function OnCoolDown(doer)
	print("冷切动作回调函数触发")
end

local function shiftfn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("pocketwatch_shifting")
	inst.AnimState:SetBuild("pocketwatch_shifting")
	inst.AnimState:PlayAnimation("idle")

	MakeInventoryFloatable(inst, "small", 0.05, { 1.2, 0.75, 1.2 })

	inst:AddTag("pocketwatch")
	inst:AddTag("cattoy")

	inst:AddTag("pocketwatch_castfrominventory")
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end
	inst:AddComponent("lootdropper")

	inst.AnimState:SetBank("pocketwatch_shifting")
	inst.AnimState:SetBuild("pocketwatch_shifting")
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem:SetOnDroppedFn(OnDropped)
	inst.components.inventoryitem.imagename = "pocketwatch_shifting"
	inst.components.inventoryitem.atlasname = "images/inventoryimages/pocketwatch_shifting.xml"

	inst:AddComponent("rechargeable")
	inst.components.rechargeable:SetOnDischargedFn(OnDischarged)
	inst.components.rechargeable:SetOnChargedFn(OnCharged)

	inst:AddComponent("pocketwatch")
	inst.components.pocketwatch.DoCastSpell = DoCastSpell

	inst:AddComponent("inspectable")
	inst.components.inspectable.getstatus = GetStatus

	inst:AddComponent("pocketwatch_cooldown")
	print("加载组件完成")
	inst.components.pocketwatch_cooldown:SetOnCoolDownFn(OnCoolDown)


	inst.components.inventoryitem:SetSinks(true)

	inst.castfxcolour = { 2 / 3, 1, 2 / 3 }

	inst.GetActionVerb_CAST_POCKETWATCH = "COOLDOWN"

	MakeHauntableLaunch(inst)
	return inst
end

return Prefab("common/inventory/pocketwatch_shifting", shiftfn, assets, prefabs)
