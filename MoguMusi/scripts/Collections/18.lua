local G = GLOBAL
local numvalue = GetModConfigData("sw_unequip")
local taitavalue = GetModConfigData("sw_taila")

local function isTaila(name)
	return name == "eyemaskhat" or name == "shieldofterror"
end

-- 兼容老版本鸡尾酒
if type(numvalue) == "boolean" then
	numvalue = 1
end


G.NONREFILLABLE = {
	armor_sanity		=	true,
	armordragonfly		=	true,
	armorgrass			=	true,
	armormarble			=	true,
	armorruins			=	true,
	armorskeleton		=	true,
	armorsnurtleshell	=	true,
	armorwood			=	true,
	beehat				=	true,
	blue_mushroomhat	=	true,
	blueamulet			=	true,
	bushhat				=	true,
	flowerhat			=	true,
	footballhat			=	true,
	green_mushroomhat	=	true,
	greenamulet			=	true,
	hawaiianshirt		=	true,
	minerhat			=	true,
	onemanband			=	true,
	orangeamulet		=	true,
	purpleamulet		=	true,
	red_mushroomhat		=	true,
	ruinshat			=	true,
	sansundertalehat	=	true,
	slurper				=	true,
	slurtlehat			=	true,
	spiderhat			=	true,
	watermelonhat		=	true,
	wathgrithrhat		=	true,
	nz_damask			=	true,				-- 神话哪吒混天绫
	armor_blue_crystal	=	true,				-- 能力勋章蓝耀甲
	armor_medal_obsidian=	true,				-- 能力勋章黑耀甲
	hivehat				=   true,				-- 蜂王冠
	armorvortexcloak = true,					-- 三合一
	piratepack = true,							-- 三合一
	armor_bramble		=	true,				-- 荆棘外壳
	ndnr_armorvortexcloak = true,				-- 富贵险中求漩涡斗篷
}

local musha_table1 = {"phoenixspear", "mushasword_frost", "mushasword4", "frosthammer", "bowm", "hat_mphoenix",
                      "armor_mushab", "broken_frosthammer", "hat_mbunnya", "hat_mwildcat","pirateback"}

local function isCertificate(name)
	if string.match(name,"_certificate") then return true else return false end
end


local function Unequip (inst)

	if inst.replica.equippable:IsEquipped() then
		G.ThePlayer.replica.inventory:ControllerUseItemOnSelfFromInvTile(inst)
	end

	if not inst.replica.equippable:IsEquipped()
		and inst.unequiptask ~= nil
	then
		inst.unequiptask:Cancel()
		inst.unequiptask = nil
	end

end


local function AutoUnequip (inst)

	local item = inst.entity:GetParent()
	
	local slot = item.replica.equippable and item.replica.equippable:EquipSlot()
	if not slot then return end

	if (not item.replica.inventoryitem:IsHeldBy(G.ThePlayer))
		or (not item.replica.equippable:IsEquipped())
		or (slot == G.EQUIPSLOTS.HANDS and not isTaila(item.prefab))		-- 手上的装备是泰拉就不会自动脱落
		or G.NONREFILLABLE[item.prefab]
		or isCertificate(item.prefab)										-- 能力勋章不会自动脱落
		or (inst.percentused:value() > numvalue and not isTaila(item.prefab))	-- 不是眼面具, 大于1% 不会自动脱落
		or (isTaila(item.prefab) and inst.percentused:value() > taitavalue)			-- 是眼面具, 大于6% 不会自动脱落
		or  string.find(item.prefab,"musha_") == 1									-- 适配musha
		or table.contains(musha_table1, item.prefab)
	then
		return
	end

	item.unequiptask = item:DoPeriodicTask(0, function ()
		Unequip(item)
	end)

	Unequip(item)

	
	TIP("自动脱落", "blue", item.name or slot..' 脱落')


end


local function PostInit (inst)

	local item = inst.entity:GetParent()

	if item == nil or item.replica.equippable == nil then
		return
	end

	inst:ListenForEvent('percentuseddirty', function ()
		AutoUnequip(inst)
	end)

end


AddPrefabPostInit('inventoryitem_classified', function (inst)
	if not G.TheNet:IsDedicated() then
		inst:DoTaskInTime(0, function ()
			PostInit(inst)
		end)
	end
end)
