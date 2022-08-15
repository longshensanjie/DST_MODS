GetTime = GLOBAL.GetTime
local start = GetTime()

local interval = 5
local startAttack = 0
local lastAttack = 0
local count = 0
local ALLOW = false


local function playTheSound (inst)
	local item = inst.entity:GetParent()
	local slot = item.replica.equippable:EquipSlot()
	if (slot == GLOBAL.EQUIPSLOTS.HANDS) then
        item:DoTaskInTime(0, function (inst)
			local name = item:GetBasicDisplayName()
			local valuE = item.replica._.inventoryitem.classified.percentused:value()
			if not valuE then return end
            print(name,valuE, GetTime())
			if GetTime()-lastAttack > interval then
				startAttack = GetTime()
                lastAttack = startAttack
                count = 1
				TIP("攻速测试", "green", "开始计时", "chat")
            else
                count = count + 1
                lastAttack = GetTime()
                ALLOW = true
			end
        end)
	end
end


local function ok(inst)
	local item = inst.entity:GetParent()
	if item == nil or item.replica.equippable == nil then
		return
	end
	inst:ListenForEvent('percentuseddirty', function ()
		playTheSound(inst)
	end)
end

local function cal()
    if lastAttack == 0 then return end
    if GetTime() - lastAttack > interval and ALLOW then
        ALLOW = false
        local speed = count/(lastAttack - startAttack)        -- 次每秒
        speed = string.format("%.4f次/秒, 共%d刀", speed, count)
        TIP("攻速测试","red",speed,"chat")
    end
end


AddPrefabPostInit('inventoryitem_classified', function (inst)
	if not GLOBAL.TheNet:IsDedicated() then
		inst:DoTaskInTime(0, function()
			ok(inst)
		end)
	end
end)
local flag = true
AddPlayerPostInit(function(inst)
    if inst and flag then
	    inst:DoPeriodicTask(1,cal)
    end
    flag = false
end)
