--金手指：自动钓鱼
local Afishingrod

local flag = false

-- 金手指系列之判定是否为鱼竿
local fishingrodlist = {"medal_fishingrod", "soratele", "sora2sword", "xe_writingbrush", "fishingrod", "windyknife", "tool_magic_wand","almightyradish","kemomiminewknife"}
if HasModName("佩奇宝宝的神奇手杖") then
	table.insert(fishingrodlist, "cane")
	table.insert(fishingrodlist, "orangestaff")
end

local function StopFishThread()
    if GLOBAL.ThePlayer.gzlevel_fishing_thread then
		GLOBAL.ThePlayer.gzlevel_fishing_thread:SetList(nil)
		GLOBAL.ThePlayer.gzlevel_fishing_thread = nil
		TIP("金手指：自动钓鱼", "red", "停止")
		flag = false
	end
end

local function equip_fishing_god()
	local handsthing = GetEquippedItemFrom("hands")
	local fishingrod
	if handsthing and table.contains(fishingrodlist, handsthing.prefab) then
		-- 手持鱼竿
		fishingrod = handsthing
	else
		-- 从身上找
		for k,v in pairs(fishingrodlist)do
			fishingrod = GetItemFromAll(v)
			if fishingrod then
				UseItemOnSelf(fishingrod)
				break
			end
		end
	end
	return fishingrod
end


local function fn()
	
	if not InGame() then
		return
	end

	if GLOBAL.ThePlayer.gzlevel_fishing_thread then
		StopFishThread()
		return
	end

	local fishing_god = equip_fishing_god()
	if not fishing_god then
		TIP("自动钓鱼", "red", "缺少鱼竿")
		return
	end
	
	Afishingrod = fishing_god.prefab


	local fish_pos = GLOBAL.ThePlayer:GetPosition()

	-- 自动搓鱼竿
	local rpc_id = nil
	for k,v in pairs(GLOBAL.AllRecipes) do
		if table.contains(fishingrodlist,v.name) then
			rpc_id = v.rpc_id
		end
	end
	if rpc_id == nil then
		TIP("自动钓鱼", "red", "缺少鱼竿")
		return
	end
	local gzlazy_controller = GLOBAL.ThePlayer.components.playercontroller
	
	local gzlazy_fishing_ponds = GLOBAL.TheSim:FindEntities(fish_pos.x, 0, fish_pos.z, 20, { "watersource" }, { "locomotor", "INLIMBO" })

	local oasis_pond = GLOBAL.FindEntity(GLOBAL.ThePlayer, 40, function(guy)
		return guy:HasTag("fishable") and guy:GetDistanceSqToPoint(fish_pos:Get()) < 14 * 14
	end, nil, {"INLIMBO", "noauradamage"})

	if oasis_pond ~= nil then
		gzlazy_fishing_ponds = {oasis_pond}
	end


	local gzlazy_delay_time = 0.1
	local gzlazy_pond_index = 1
	local gzlazy_reel_count = 0


	if not gzlazy_fishing_ponds or not gzlazy_fishing_ponds[gzlazy_pond_index] then
		TIP("自动钓鱼","red" ,"现在周围哪有鱼？")
		return
	end

	GLOBAL.ThePlayer.gzlevel_fishing_thread = GLOBAL.ThePlayer:StartThread(function()

		while true do
			local now_pond = gzlazy_fishing_ponds[gzlazy_pond_index]
			local gzlazy_inventory = GLOBAL.ThePlayer.replica.inventory

			-- 钓鱼期间鱼竿用完再做
			local gzlazy_fishingrod = GLOBAL.ThePlayer.replica.inventory:GetEquippedItem("hands")
			if not gzlazy_fishingrod or not table.contains(fishingrodlist, gzlazy_fishingrod.prefab)then
				local fishingrod = equip_fishing_god()
				if not fishingrod and GLOBAL.ThePlayer.replica.builder:CanBuild("fishingrod") then
					TIP("自动钓鱼","green","尝试做个鱼竿")
					GLOBAL.SendRPCToServer(GLOBAL.RPC.MakeRecipeFromMenu, rpc_id, nil)
					GLOBAL.Sleep(3)
				end
				-- 再次装备仍然未装备则退出
				gzlazy_fishingrod = GLOBAL.ThePlayer.replica.inventory:GetEquippedItem("hands")
				if not gzlazy_fishingrod or not table.contains(fishingrodlist, gzlazy_fishingrod.prefab) then
					fishingrod = equip_fishing_god()
					if not fishingrod then
						TIP("自动钓鱼", "red", "没鱼竿, 停止钓鱼")
						flag = false
						return
					end
					gzlazy_inventory:ControllerUseItemOnSelfFromInvTile(fishingrod)
					GLOBAL.Sleep(0.3)
				end
			end

			if gzlazy_fishing_ponds and now_pond then
				if not flag then
					TIP("自动钓鱼", "green", "启动")
					flag = true
				end 
				local now_pond_position = now_pond:GetPosition()
				local controlmods = gzlazy_controller:EncodeControlMods()
				local lmb, rmb = GLOBAL.ThePlayer.components.playeractionpicker:DoGetMouseActions(now_pond_position, now_pond)
				if lmb then
					local action_string = lmb and lmb:GetActionString() or ""
					if action_string == GLOBAL.STRINGS.ACTIONS.REEL.REEL then
						GLOBAL.Sleep(0.1)
						gzlazy_reel_count = gzlazy_reel_count + 1
						if gzlazy_reel_count >= 2 then
							gzlazy_reel_count = 0
							gzlazy_pond_index = gzlazy_pond_index + 1
							if gzlazy_pond_index > #gzlazy_fishing_ponds then
								gzlazy_pond_index = 1
							end
						end
					end
					if action_string ~= GLOBAL.STRINGS.ACTIONS.REEL.CANCEL then
						gzlazy_controller:DoAction(lmb)
						GLOBAL.Sleep(0.1)
						GLOBAL.SendRPCToServer(GLOBAL.RPC.LeftClick, lmb.action.code, now_pond_position.x, now_pond_position.z, now_pond, false, controlmods, false, lmb.action.mod_name)
					end
				end
			else
				StopFishThread()
				TIP("自动钓鱼","red" ,"现在周围哪有鱼？")
				flag = false
			end
			GLOBAL.Sleep(gzlazy_delay_time)
		end
	end)
end


local function get_thread()
	return GLOBAL.ThePlayer.gzlevel_fishing_thread
end

InterruptedByMobile(get_thread, StopFishThread)

if GetModConfigData("sw_autofish") == "biubiu" then
DEAR_BTNS:AddDearBtn(GLOBAL.GetInventoryItemAtlas("fishingrod.tex"), "fishingrod.tex", "自动池钓", "钓池塘里的鱼", false, fn)
end

AddBindBtn("sw_autofish", fn)