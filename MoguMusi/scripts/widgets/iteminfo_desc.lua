local UIAnim = require "widgets/uianim"
local Text = require "widgets/text"
local Image = require "widgets/image"
local Widget = require "widgets/widget"
local CacheItem = require "iteminfo_cacheitem"

local easing = require("easing")

local ItemInfoDesc = Class(Widget, function(self, slot)
    Widget._ctor(self, "ItemInfoDesc")
	
    self.slot = slot
	self.container = nil -- Set from containerwidget.Open, hooked from modmain
	
	self.width = 0
	self.height = 0
	
	self.relative_scale = 1
	
	self.num_rows = 0
	
	self.time_since_last_update = 0
	
	self.active = false
	
	self:SetClickable(false)
end)

local function Format1D(value)
	return math.floor(value * 10 + 0.5) / 10
end

local function FormatInt(value)
	return math.floor(value + 0.5)
end

local function FormatTime(t)
	if MOD_ITEMINFO.TIME_FORMAT == MOD_ITEMINFO.TIME_FORMATS.HOURS then
		if t == 0 then
			return "0"
		else
			local	hours = string.format("%01.f", math.floor(t/3600))
			local	mins = string.format("%02.f", math.floor(t/60 - (hours*60)))
			local	secs = string.format("%02.f", math.floor(t - hours*3600 - mins *60))
			
			if hours == "0" and mins == "00" then
				return secs
			elseif hours == "0" then
				return mins .. ":" .. secs
			else
				return hours .. ":" .. mins .. ":" .. secs
			end
			
		end
	elseif MOD_ITEMINFO.TIME_FORMAT == MOD_ITEMINFO.TIME_FORMATS.DAYS then
		if t == 0 then
			return "0d"
		else
			return Format1D(t/TUNING.TOTAL_DAY_TIME) .. "d"
		end
	end
	
	return "???"
end

function ItemInfoDesc:GetSpoilModifier(inst, owner)
	local modifier = 1.0
	
	if owner:HasTag("fridge") then
		modifier = TUNING.PERISH_FRIDGE_MULT
	elseif owner:HasTag("spoiler") then
		modifier = TUNING.PERISH_GROUND_MULT 
	end
	
	if owner:HasTag("saltbox") then
		modifier = TUNING.PERISH_SALTBOX_MULT
	elseif owner:HasTag("spoiler") then
		modifier = TUNING.PERISH_GROUND_MULT 
	end
	
	if owner:HasTag("fish_box") then
		modifier = TUNING.FISH_BOX_PRESERVER_RATE
	elseif owner:HasTag("spoiler") then
		modifier = TUNING.PERISH_GROUND_MULT 
	end
	
	if inst.replica.inventoryitem:IsWet() then
		modifier = modifier * TUNING.PERISH_WET_MULT
	end
	
	if TheWorld.state.temperature < 0 then
		modifier = modifier * TUNING.PERISH_WINTER_MULT
	elseif TheWorld.state.temperature > TUNING.OVERHEAT_TEMP then
		modifier = modifier * TUNING.PERISH_SUMMER_MULT
	end
	
	modifier = modifier * TUNING.PERISH_GLOBAL_MULT
	
	return modifier
end

function ItemInfoDesc:GetPerishFreshness(inst)
	return inst.replica.inventoryitem.classified.perish:value() / 62
end

function ItemInfoDesc:CalculateFinalPerishValues(base_inst, inst, owner)
	local freshness = self:GetPerishFreshness(inst)
	local perishtime = base_inst.components.perishable.perishtime
	local max_perishtime = perishtime
	
	local modifier = self:GetSpoilModifier(inst, owner)
	
	perishtime = perishtime * freshness / modifier
	max_perishtime = max_perishtime / modifier

	return freshness, perishtime, max_perishtime
end

function ItemInfoDesc:GetPerishValues(base_inst, inst)
	if self.container ~= nil then
		return self:CalculateFinalPerishValues(base_inst, inst, self.container)
	end
	
	return self:CalculateFinalPerishValues(base_inst, inst, ThePlayer)
end

function ItemInfoDesc:GetDappernessValue(base_inst, inst)
	return base_inst.components.equippable.dapperness * 60
end

function ItemInfoDesc:GetFuelValue(base_inst, inst)
	local maxfuel = base_inst.components.fueled.maxfuel
	local percentused = inst.replica.inventoryitem.classified.percentused:value() / 100
	
	local remaining_time = maxfuel * percentused
	
	if inst.prefab == "torch" then
		if TheWorld.state.israining then 
			remaining_time = remaining_time / (1 + TUNING.TORCH_RAIN_RATE * TheWorld.state.precipitationrate)
		end
	end
	
	local fueltype = base_inst.components.fueled.fueltype
	
	return remaining_time, fueltype
end

function ItemInfoDesc:CanEat(base_inst)
	local foodtype = base_inst.components.edible.foodtype
	
	if foodtype == FOODTYPE.GEARS then
		if ThePlayer:HasTag("GEARS_eater") then return true else return false end
	elseif foodtype == FOODTYPE.WOOD then
		if ThePlayer:HasTag("WOOD_eater") then return true else return false end
	elseif foodtype == FOODTYPE.ELEMENTAL then
		if ThePlayer:HasTag("ELEMENTAL_eater") then return true else return false end
	elseif foodtype == FOODTYPE.HORRIBLE then
		if ThePlayer:HasTag("HORRIBLE_eater") then return true else return false end
	elseif foodtype == FOODTYPE.BURNT then
		if ThePlayer:HasTag("BURNT_eater") then return true else return false end
	elseif foodtype == FOODTYPE.RAW then
		if ThePlayer:HasTag("RAW_eater") then return true else return false end
	elseif foodtype == FOODTYPE.ROUGHAGE then
		if ThePlayer:HasTag("ROUGHAGE_eater") then return true else return false end
	end
	return true
end

StrongStomachEaters =
{
	webber = true
}

IgnoreSpoilageEaters =
{
	wx78 = true
}

PickyEaters =
{
	wickerbottom = true
}

SoulEaters =
{
	wortox = true
}

NonDegradingFood =
{
	ice = true
}

function ItemInfoDesc:CanEatMonster()
	if StrongStomachEaters[ThePlayer.prefab] then
		return true
	end
end

function ItemInfoDesc:IgnoresSpoilage()
	if IgnoreSpoilageEaters[ThePlayer.prefab] then
		return true
	end
end

function ItemInfoDesc:IsPickyEater()
	if PickyEaters[ThePlayer.prefab] then
		return true
	end
end

function ItemInfoDesc:SoulEater()
	if SoulEaters[ThePlayer.prefab] then
		return true
	end
end

function ItemInfoDesc:IsNonDegradingFood(base_inst)
	if NonDegradingFood[base_inst.prefab] then
		return true
	end
end

local FOODSTATES = {FRESH = 1, STALE = 2, SPOILED = 3}

function ItemInfoDesc:GetEdibleValues(base_inst, inst)
	
	local foodtypes = base_inst.components.edible.foodtype
	local hunger = base_inst.components.edible.hunger
	local sanity = base_inst.components.edible.sanity
	local health = base_inst.components.edible.health
	local temperaturedelta = base_inst.components.edible.temperatureduration
	local nochilli = base_inst.components.edible.spice
	local spice = base_inst.components.edible.spice
	
	local freshness = self:GetPerishFreshness(inst)
	local state = nil
	
	if freshness >= .5 then
        state = FOODSTATES.FRESH
    elseif freshness > .2 then
        state = FOODSTATES.STALE
    else
		state = FOODSTATES.SPOILED
    end
	
	if self:CanEatMonster() and inst:HasTag("monstermeat") then
		if health < 0 then health = 0 end
		if sanity < 0 then sanity = 0 end
	end
	
	--Characters
			--Wortox
		if ThePlayer.prefab == "wortox" then 
			hunger = hunger * 0.5 
			sanity = sanity * 0.5
			health = health * 0.5
				if inst:HasTag("soul") then
					hunger = 18.75
					sanity = -5
					health = 0
				end
			end
			--Wormwood
		if ThePlayer.prefab == "wormwood" then
			if MOD_ITEMINFO.WORM_HEALTH == false then
				health = 0
			end
		end
			--Warly
		if ThePlayer.prefab == "warly" then
			--maybe some day
		end
			--Wurt
		if ThePlayer.prefab == "wurt" then
			if inst.prefab == ("durian") then
				hunger = (hunger * 1.66) /1.33
				sanity = 0
				health = 0
			end
		
			if inst.prefab == ("durian_cooked") then
				hunger = (hunger * 1.66) / 1.33
				sanity = 0
				health = 0
			end
		
			if foodtypes == "VEGGIE" then
				hunger = hunger * 1.33
			end
			
			if MOD_ITEMINFO.WURT_MEAT == false then
				if foodtypes == "MEAT" then
					hunger = 0
					sanity = 0
					health = 0
				end
			end
		end
		
		--Wigfrid
		if MOD_ITEMINFO.WIG_VEGGIE == false then
			if ThePlayer.prefab =="wathgrithr" then
				if foodtypes == "VEGGIE" then
					hunger = 0
					sanity = 0
					health = 0
				end
			end
		end
		
		
	--Dishes and Spiced dishes
		if inst:HasTag("spicedfood") then
			if spice == "SPICE_SALT" then
				health = health * 1.25
			end
		end
		
	-- Hunger
	if not(self:IsNonDegradingFood(base_inst) or hunger < 0 or self:IgnoresSpoilage()) then
		if state == FOODSTATES.STALE then
				hunger = hunger * (self:IsPickyEater() and TUNING.WICKERBOTTOM_STALE_FOOD_HUNGER or TUNING.STALE_FOOD_HUNGER)
		elseif state == FOODSTATES.SPOILED then
				hunger = hunger * (self:IsPickyEater() and TUNING.WICKERBOTTOM_SPOILED_FOOD_HUNGER or TUNING.SPOILED_FOOD_HUNGER)
		end
	end
	
	-- Sanity
	if not(self:IsNonDegradingFood(base_inst) or sanity < 0 or self:IgnoresSpoilage()) then
		if state == FOODSTATES.STALE then
			sanity = 0
		elseif state == FOODSTATES.SPOILED then
			sanity = -TUNING.SANITY_SMALL
		end
	end
	
	-- Health
	if not(self:IsNonDegradingFood(base_inst) or health < 0 or self:IgnoresSpoilage()) then
		if state == FOODSTATES.STALE then
			health = health * (self:IsPickyEater() and TUNING.WICKERBOTTOM_STALE_FOOD_HEALTH or TUNING.STALE_FOOD_HEALTH)
		elseif state == FOODSTATES.SPOILED then
			health = health * (self:IsPickyEater() and TUNING.WICKERBOTTOM_SPOILED_FOOD_HEALTH or TUNING.SPOILED_FOOD_HEALTH)
		end
	end
	
	
	return hunger, sanity, health
end

function ItemInfoDesc:GetPlayerDamageModifier()
	if ThePlayer.prefab == "wendy" then
		return TUNING.WENDY_DAMAGE_MULT
	elseif ThePlayer.prefab == "wathgrithr" then
		return TUNING.WATHGRITHR_DAMAGE_MULT
	elseif ThePlayer.prefab == "wolfgang" and ThePlayer.iteminfo then
		local percent = ThePlayer.replica.hunger:GetPercent()
		local hunger = ThePlayer.replica.hunger:GetCurrent()
		local damage_mult = TUNING.WOLFGANG_ATTACKMULT_NORMAL
		
		if ThePlayer.iteminfo.form == MOD_ITEMINFO.WOLFGANG_FORMS.MIGHTY then
			local mighty_start = (TUNING.WOLFGANG_START_MIGHTY_THRESH/TUNING.WOLFGANG_HUNGER)   
			local mighty_percent = math.max(0, (percent - mighty_start) / (1 - mighty_start))
			damage_mult = easing.linear(mighty_percent, TUNING.WOLFGANG_ATTACKMULT_MIGHTY_MIN, TUNING.WOLFGANG_ATTACKMULT_MIGHTY_MAX - TUNING.WOLFGANG_ATTACKMULT_MIGHTY_MIN, 1)
		elseif ThePlayer.iteminfo.form == MOD_ITEMINFO.WOLFGANG_FORMS.WIMPY then
			local wimpy_start = (TUNING.WOLFGANG_START_WIMPY_THRESH/TUNING.WOLFGANG_HUNGER) 
			local wimpy_percent = math.min(1, percent/wimpy_start )
			damage_mult = easing.linear(wimpy_percent, TUNING.WOLFGANG_ATTACKMULT_WIMPY_MIN, TUNING.WOLFGANG_ATTACKMULT_WIMPY_MAX - TUNING.WOLFGANG_ATTACKMULT_WIMPY_MIN, 1) 
		end

		return damage_mult
	elseif ThePlayer.prefab == "wes" then
		return 0.75
	else
		return 1
	end
end

--function ItemInfoDesc:GetBoatValue(base_inst, inst)
--local walkable = base_inst.components.walkableplatform
--end
--function ItemInfoDesc:CheckIfBoat(base_inst, inst)
--local platform = base_inst.components.walkableplatform
--end



function ItemInfoDesc:GetWeaponDamage(base_inst, inst)	
	local damage = 0
-- FOR ALL WEAPONS WITH OTHER DMG ON LAND THAN OCEAN
	local is_over_ground = TheWorld.Map:IsVisualGroundAtPoint(ThePlayer:GetPosition():Get())
	
		if inst.prefab ~= "hambat" then
			if inst.prefab == "trident" then
				if is_over_ground then
					damage = TUNING.TRIDENT.DAMAGE
				else
					damage = TUNING.TRIDENT.OCEAN_DAMAGE
				end
				else
					damage = base_inst.components.weapon.damage
			end
		else
			damage = TUNING.HAMBAT_DAMAGE * self:GetPerishFreshness(inst)
			damage = Remap(damage, 0, TUNING.HAMBAT_DAMAGE, TUNING.HAMBAT_MIN_DAMAGE_MODIFIER * TUNING.HAMBAT_DAMAGE, TUNING.HAMBAT_DAMAGE)
	end
	
	local damagemult = self:GetPlayerDamageModifier()
	if type(damage) == "number" and type(damagemult) == "number" then
		return damage * damagemult
	else
		print("出现了BUG：无法获取此武器伤害", inst and inst.prefab or "未知")
		return 0
	end
end

function ItemInfoDesc:GetFiniteUses(base_inst, inst)
	local consumption_per_use = 1
	for k,v in pairs(base_inst.components.finiteuses.consumption) do
		consumption_per_use = v
		break
	end

	local maxuses = base_inst.components.finiteuses.total / consumption_per_use
	local usesleft = inst.replica.inventoryitem.classified.percentused:value() / 100 * maxuses
	
	return usesleft, maxuses
end

function ItemInfoDesc:GetArmorValues(base_inst, inst)
	local absorb_percent = base_inst.components.armor.absorb_percent
	local hp = base_inst.components.armor.maxcondition  * inst.replica.inventoryitem.classified.percentused:value() / 100
	
	return absorb_percent, hp
end

function ItemInfoDesc:GetInsulationValues(base_inst, inst)
	local insulation = base_inst.components.insulator.insulation
	
	local insulation_type = base_inst.components.insulator.type
	
	return insulation, insulation_type
end

function ItemInfoDesc:GetWaterproofValue(base_inst, inst)
	return base_inst.components.waterproofer.effectiveness
end

function ItemInfoDesc:GetHealerValue(base_inst, inst)
	return base_inst.components.healer.health
end

-- Spacing between the image and the text
local Spacing = 5

-- Spacing between same row childs
local ChildSpacing = 10

local ImageWidth = 32
local RowHeight = 48

function ItemInfoDesc:AddChild1(img, txt)
	local pos_y = self.num_rows * RowHeight + RowHeight/2

	local txt_w = txt:GetRegionSize()
	
	local width = ImageWidth + txt_w + Spacing
	
	if width > self.width then
		self.width = width
	end
	self.height = self.height + RowHeight
	
	local left = width/2 * -1
	
	img:SetPosition(left + ImageWidth/2, pos_y)
	txt:SetPosition(left + ImageWidth + txt_w/2 + Spacing, pos_y )
	
	self:AddChild(img)
	self:AddChild(txt)
	
	self.num_rows = self.num_rows + 1
end

function ItemInfoDesc:AddChild2(img1, txt1, img2, txt2)
	local pos_y = self.num_rows * RowHeight + RowHeight/2

	local txt1_w = txt1:GetRegionSize()
	local txt2_w = txt2:GetRegionSize()
	
	local width = ImageWidth * 2 + txt1_w + txt2_w + Spacing * 2 + ChildSpacing
	
	if width > self.width then
		self.width = width
	end
	self.height = self.height + RowHeight
	
	local left = width/2 * -1
	
	img1:SetPosition(left + ImageWidth/2, pos_y)
	txt1:SetPosition(left + ImageWidth + txt1_w/2 + Spacing, pos_y )
	
	img2:SetPosition(left + ImageWidth * 1.5 + txt1_w + Spacing + ChildSpacing, pos_y)
	txt2:SetPosition(left + ImageWidth * 2 + txt1_w + txt2_w/2 + Spacing * 2 + ChildSpacing, pos_y )
	
	self:AddChild(img1)
	self:AddChild(txt1)
	self:AddChild(img2)
	self:AddChild(txt2)
	
	self.num_rows = self.num_rows + 1
end

function ItemInfoDesc:AddChild3(img1, txt1, img2, txt2, img3, txt3)
	local pos_y = self.num_rows * RowHeight + RowHeight/2

	local txt1_w = txt1:GetRegionSize()
	local txt2_w = txt2:GetRegionSize()
	local txt3_w = txt3:GetRegionSize()
	
	local width = ImageWidth * 3 + txt1_w + txt2_w + txt3_w + Spacing * 3 + ChildSpacing * 2
	
	if width > self.width then
		self.width = width
	end
	self.height = self.height + RowHeight
	
	local left = width/2 * -1
	
	img1:SetPosition(left + ImageWidth/2, pos_y)
	txt1:SetPosition(left + ImageWidth + txt1_w/2 + Spacing, pos_y )
	
	img2:SetPosition(left + ImageWidth * 1.5 + txt1_w + Spacing + ChildSpacing, pos_y)
	txt2:SetPosition(left + ImageWidth * 2 + txt1_w + txt2_w/2 + Spacing * 2 + ChildSpacing, pos_y )
	
	img3:SetPosition(left + ImageWidth * 2.5 + txt1_w + txt2_w + Spacing * 2 + ChildSpacing * 2, pos_y )
	txt3:SetPosition(left + ImageWidth * 3 + txt1_w + txt2_w + txt3_w/2 + Spacing * 3 + ChildSpacing * 2, pos_y )
	
	self:AddChild(img1)
	self:AddChild(txt1)
	self:AddChild(img2)
	self:AddChild(txt2)
	self:AddChild(img3)
	self:AddChild(txt3)
	
	self.num_rows = self.num_rows + 1
end

function ItemInfoDesc:AddPerishableRow(base_inst, inst)
	local freshness, perishtime, max_perishtime = self:GetPerishValues(base_inst, inst)
	
	local img1 = Image("images/iteminfo_images.xml", "freshness.tex")
	local txt1 = Text(NUMBERFONT, 42)
	txt1:SetString(Format1D(freshness * 100) .. "%" )
	
	if not base_inst.components.edible or MOD_ITEMINFO.PERISHABLE == MOD_ITEMINFO.PERISH_DISPLAY.PERISH_ONLY then
		local img2 = Image("images/iteminfo_images.xml", "spoiled.tex")
		local txt2 = Text(NUMBERFONT, 42)
		txt2:SetString(FormatTime(perishtime))
	
		self:AddChild2(img1, txt1, img2, txt2)
	elseif MOD_ITEMINFO.PERISHABLE == MOD_ITEMINFO.PERISH_DISPLAY.STALE_PERISH then
		local stale_time = perishtime - max_perishtime/2

		if stale_time > 0 then
			local img2 = Image("images/iteminfo_images.xml", "stale.tex")
			local txt2 = Text(NUMBERFONT, 42)
			txt2:SetString(FormatTime(stale_time))
			self:AddChild2(img1, txt1, img2, txt2)
		else
			local img2 = Image("images/iteminfo_images.xml", "spoiled.tex")
			local txt2 = Text(NUMBERFONT, 42)
			txt2:SetString(FormatTime(perishtime))
			self:AddChild2(img1, txt1, img2, txt2)
		end
	elseif MOD_ITEMINFO.PERISHABLE == MOD_ITEMINFO.PERISH_DISPLAY.BOTH then
		local img2 = Image("images/iteminfo_images.xml", "spoiled.tex")
		local txt2 = Text(NUMBERFONT, 42)
		txt2:SetString(FormatTime(perishtime))
	
		self:AddChild2(img1, txt1, img2, txt2)
		
		local stale_time = perishtime - max_perishtime/2
		
		if stale_time > 0 then
			local img3 = Image("images/iteminfo_images.xml", "stale.tex")
			local txt3 = Text(NUMBERFONT, 42)
			txt3:SetString(FormatTime(stale_time))
			
			self:AddChild1(img3, txt3)
		end
	end
end

function ItemInfoDesc:AddDappernessRow(base_inst, inst)
	local dapperness = self:GetDappernessValue(base_inst, inst)
	
	local img = Image("images/iteminfo_images.xml", "sanity.tex")
	local txt = Text(NUMBERFONT, 42)
	txt:SetString(Format1D(dapperness).. "/min")
	
	self:AddChild1(img, txt)
end

function ItemInfoDesc:AddInsulatorRow(base_inst, inst)
	local insulation, insulation_type = self:GetInsulationValues(base_inst, inst)
	
	local img = Image("images/iteminfo_images.xml", "insulation_" .. insulation_type .. ".tex")
	local txt = Text(NUMBERFONT, 42)
	txt:SetString(insulation)
	
	self:AddChild1(img, txt)
end

function ItemInfoDesc:AddFueledRow(base_inst, inst)
	local fueltime, fueltype = self:GetFuelValue(base_inst, inst)
	
	local img = Image("images/iteminfo_images.xml","fuel_" .. fueltype .. ".tex")
	local txt = Text(NUMBERFONT, 42)
	txt:SetString(FormatTime(fueltime))
	
	self:AddChild1(img, txt)
end

function ItemInfoDesc:AddWaterproofRow(base_inst, inst)

	local waterproof = self:GetWaterproofValue(base_inst, inst)
	
	local img = Image("images/iteminfo_images.xml", "waterproof.tex")
	local txt = Text(NUMBERFONT, 42)
	txt:SetString(FormatInt(waterproof * 100) .. "%")
	
	self:AddChild1(img, txt)
end

function ItemInfoDesc:AddWeaponRow(base_inst, inst)
	local damage = self:GetWeaponDamage(base_inst, self.item)
	
	local img = Image("images/iteminfo_images.xml", "weapon.tex")
	local txt = Text(NUMBERFONT, 42)
	txt:SetString(Format1D(damage))
	
	
	self:AddChild1(img, txt)
end

function ItemInfoDesc:AddFiniteUsesRow(base_inst, inst)
	local usesleft, maxuses = self:GetFiniteUses(base_inst, self.item)
	
	local img = Image("images/iteminfo_images.xml", "uses.tex")
	local txt = Text(NUMBERFONT, 42)
	txt:SetString(FormatInt(usesleft) .. "/" .. maxuses)
	
	self:AddChild1(img, txt)
end

function ItemInfoDesc:AddArmorRow(base_inst, inst)
	local absorb, hp = self:GetArmorValues(base_inst, inst)
	if not absorb then return end
	
	local img1 = Image("images/iteminfo_images.xml", "armor.tex")
	local txt1 = Text(NUMBERFONT, 42)
	txt1:SetString(FormatInt(absorb * 100) .. "%")
	
	local img2 = Image("images/iteminfo_images.xml", "health.tex")
	local txt2 = Text(NUMBERFONT, 42)
	txt2:SetString(FormatInt(hp))
	
	
	self:AddChild2(img1, txt1, img2, txt2)
end

function ItemInfoDesc:AddHealerRow(base_inst, inst)

	local health = self:GetHealerValue(base_inst, inst)
	
	local img = Image("images/iteminfo_images.xml", "health.tex")
	local txt = Text(NUMBERFONT, 42)
	txt:SetString(health)
	
	self:AddChild1(img, txt)
end

function ItemInfoDesc:AddEdibleRow(base_inst, inst)
	local hunger, sanity, health = self:GetEdibleValues(base_inst, inst)
	
	--[[local img1 = Image("images/iteminfo_images.xml", "hunger.tex")
	local txt1 = Text(NUMBERFONT, 42)
	txt1:SetString(Format1D(hunger))
	
	local img2 = Image("images/iteminfo_images.xml", "sanity.tex")
	local txt2 = Text(NUMBERFONT, 42)
	txt2:SetString(Format1D(sanity))
	
	local img3 = Image("images/iteminfo_images.xml", "health.tex")
	local txt3 = Text(NUMBERFONT, 42)
	txt3:SetString(Format1D(health))]]--
	--self:AddChild3(img1, txt1, img2, txt2, img3, txt3)
	
	if hunger ~= 0 and sanity ~= 0 and health ~= 0 then
		local img1 = Image("images/iteminfo_images.xml", "hunger.tex")
		local txt1 = Text(NUMBERFONT, 42)
		txt1:SetString(Format1D(hunger))
		
		local img2 = Image("images/iteminfo_images.xml", "sanity.tex")
		local txt2 = Text(NUMBERFONT, 42)
		txt2:SetString(Format1D(sanity))
		
		local img3 = Image("images/iteminfo_images.xml", "health.tex")
		local txt3 = Text(NUMBERFONT, 42)
		txt3:SetString(Format1D(health))
		
		self:AddChild3(img1, txt1, img2, txt2, img3, txt3)
	elseif hunger ~= 0 and sanity ~= 0 then
		local img1 = Image("images/iteminfo_images.xml", "hunger.tex")
		local txt1 = Text(NUMBERFONT, 42)
		txt1:SetString(Format1D(hunger))
		
		local img2 = Image("images/iteminfo_images.xml", "sanity.tex")
		local txt2 = Text(NUMBERFONT, 42)
		txt2:SetString(Format1D(sanity))
		
		self:AddChild2(img1, txt1, img2, txt2)
	elseif hunger ~= 0 and health ~= 0 then
		local img1 = Image("images/iteminfo_images.xml", "hunger.tex")
		local txt1 = Text(NUMBERFONT, 42)
		txt1:SetString(Format1D(hunger))
		
		local img3 = Image("images/iteminfo_images.xml", "health.tex")
		local txt3 = Text(NUMBERFONT, 42)
		txt3:SetString(Format1D(health))
		
		self:AddChild2(img1, txt1, img3, txt3)
	elseif sanity ~= 0 and health ~= 0 then
		local img2 = Image("images/iteminfo_images.xml", "sanity.tex")
		local txt2 = Text(NUMBERFONT, 42)
		txt2:SetString(Format1D(sanity))
		
		local img3 = Image("images/iteminfo_images.xml", "health.tex")
		local txt3 = Text(NUMBERFONT, 42)
		txt3:SetString(Format1D(health))
		
		self:AddChild2(img2, txt2, img3, txt3)
	elseif hunger ~= 0 then 
		local img1 = Image("images/iteminfo_images.xml", "hunger.tex")
		local txt1 = Text(NUMBERFONT, 42)
		txt1:SetString(Format1D(hunger))
		
		self:AddChild1(img1, txt1)
	elseif sanity ~= 0 then 
		local img2 = Image("images/iteminfo_images.xml", "sanity.tex")
		local txt2 = Text(NUMBERFONT, 42)
		txt2:SetString(Format1D(sanity))

		self:AddChild1(img2, txt2)
	elseif health ~= 0 then 
		local img3 = Image("images/iteminfo_images.xml", "health.tex")
		local txt3 = Text(NUMBERFONT, 42)
		txt3:SetString(Format1D(health))
		
		self:AddChild1(img3, txt3)
	end
end

function ItemInfoDesc:AddPrefabNameRow(inst)
	local name = inst.prefab
	
	local img = Image("images/iteminfo_images.xml", "label.tex")
	local txt = Text(NUMBERFONT, 42)
	txt:SetString(name)
	
	self:AddChild1(img, txt)
end

local IgnoredPrefabs =
{
	blueprint = true,
	heatrock = true,
	fireflies = true
}

function ItemInfoDesc:ShouldBeIgnored(inst)
	if IgnoredPrefabs[inst.prefab] then return true end
	return false
end

function ItemInfoDesc:UpdateInfo()
	self.num_rows = 0
	
	self.width = 0
	self.height = 0
	
	if not self.item or not self.item.replica or not self.item.replica.inventoryitem or not self.item.replica.inventoryitem.classified then return end
	
	if not self:ShouldBeIgnored(self.item) then
		
		if not MOD_ITEMINFO.CACHED_ITEMS[self.item.prefab] then

			local IsMasterSim = TheWorld.ismastersim
			TheWorld.ismastersim = true
			MOD_ITEMINFO.SPAWNING_ITEM = true
			
			local inst_copy = SpawnPrefab(self.item.prefab)
			
			MOD_ITEMINFO.CACHED_ITEMS[self.item.prefab] = CacheItem(inst_copy)
			--print("Added " .. MOD_ITEMINFO.CACHED_ITEMS[self.item.prefab].prefab .. " to cache")
			
			inst_copy:Remove()
			TheWorld.ismastersim = IsMasterSim
			MOD_ITEMINFO.SPAWNING_ITEM = false
		end
		
		local base_inst = MOD_ITEMINFO.CACHED_ITEMS[self.item.prefab]
		
		if base_inst.components.equippable and base_inst.components.equippable.dapperness and base_inst.components.equippable.dapperness ~= 0 then
			self:AddDappernessRow(base_inst, self.item)
		end
		
		if base_inst.components.perishable then
			self:AddPerishableRow(base_inst, self.item)
		end
		
		if base_inst.components.insulator then
			self:AddInsulatorRow(base_inst, self.item)
		end
		
		if base_inst.components.waterproofer then
			self:AddWaterproofRow(base_inst, self.item)
		end
	
		
		if base_inst.components.finiteuses then
			self:AddFiniteUsesRow(base_inst, self.item)
		end
		
		if base_inst.components.weapon then
			self:AddWeaponRow(base_inst, self.item)
		end
		
		if base_inst.components.fueled then
			self:AddFueledRow(base_inst, self.item)
		end
		
		if base_inst.components.armor then
			self:AddArmorRow(base_inst, self.item)
		end
		
		if base_inst.components.healer then
			self:AddHealerRow(base_inst, self.item)
		end
		
		if base_inst.components.edible then
			if 	self:CanEat(base_inst) then
				self:AddEdibleRow(base_inst, self.item)
			end
		end
		
		
	end
	
	if MOD_ITEMINFO.SHOW_PREFABNAME then
		self:AddPrefabNameRow(self.item)
	end
end

function ItemInfoDesc:GetSize()
	return self.width, self.height
end

function ItemInfoDesc:GetWorldSize()
	--local scale = self:GetLooseScale() -- We could use this, but when the widget plays the scale up anim the position is gonna get messed up.
	-- Instead, let's use the scale it's eventually going to have
	return self.width * MOD_ITEMINFO.INFO_SCALE, self.height * MOD_ITEMINFO.INFO_SCALE
end

function ItemInfoDesc:RefreshInfo()
	-- Killing all children and rebuilding the widget is cheaper than indexing the controls, checking if they're up to date and then updating them
	-- ... it's also a lot simpler
	-- Maybe try adding EventListeners for % change? Still rebuild, but only when there's actual change.
	-- And still update. Check if the item has changed/there's no item in the slot.
	-- We'd have to index all values though. And the item.
	-- Need to think about it...
	self:KillAllChildren()
	self:UpdateInfo()
	
	self:Show()
end

function ItemInfoDesc:DoShowAnim()
	if self.anim_done then return end
	
	self:SetScale(self.relative_scale/1.3)
	self:ScaleTo(self.relative_scale/1.3, self.relative_scale, .125)
	
	self.anim_done = true
end

function ItemInfoDesc:ShowInfo()
	if self.shown then return end

	self:KillAllChildren()
	self:UpdateInfo()
	self:UpdatePos()
	self:DoShowAnim()
	
	self:Show()
end

function ItemInfoDesc:HideInfo()
	self:Hide()
	
	self:KillAllChildren()
end

function ItemInfoDesc:UpdatePos()
	local pos = self.slot:GetWorldPosition()
	local width, height = self:GetWorldSize()
	
	
	local offsetx, offsety
	offsetx = 0
	offsety = 0
	
	if not TheInput:ControllerAttached() then
		local scale = ThePlayer.HUD.controls.bottom_root:GetScale()
		
		if not self.container then
			offsety = 96 * scale.y
		elseif self.container:HasTag("backpack") then
			offsety = 96 * scale.y
			
			local screen_width, screen_height = TheSim:GetScreenSize()
			
			if pos.x + width/2 >= screen_width then
				offsetx = (screen_width - pos.x) - width/2
			end
		else -- regular container (chest, icebox, package)
			offsety = height * -1 -16 * scale.y
		end
		
		self:UpdatePosition(pos.x + offsetx, pos.y + offsety)
	else
		local scale = ThePlayer.HUD.controls.inv:GetScale()

		if not self.container then
			offsetx = self.width/2 + 64 * scale.x
			offsety = 196 * scale.y
		else -- regular container (chest, icebox, package)
			offsety = pos.y + self.height * -1 -32 * scale.y
		end
		
		if not self.waspositioned then
			self:UpdatePosition(pos.x + offsetx, offsety)
			self.waspositioned = true
		end
		
		if not self.moving then
			self.moving = true
			self:MoveTo(self:GetPosition(), Vector3(pos.x + offsetx, offsety, 0), 0.125, function() self.moving = false end)
		end
	end
	
end

ItemInfoDesc._StartUpdating = ItemInfoDesc.StartUpdating
function ItemInfoDesc:StartUpdating()
	self:_StartUpdating()
	self.active = true
end

ItemInfoDesc._StopUpdating = ItemInfoDesc.StopUpdating
function ItemInfoDesc:StopUpdating()
	self:_StopUpdating()
	self.active = false
end

-- Kills all its children, hides itself and stops updating next time it updates
function ItemInfoDesc:SetInactive()
	self.active = false
end

function ItemInfoDesc:OnUpdate(dt)
	self.time_since_last_update = self.time_since_last_update + dt
	
	if not self.active then
		self.time_since_last_update = 0
		self:HideInfo()
		self.anim_done = false
		self:StopUpdating()
		return
	end
	
	if self.time_since_last_update > MOD_ITEMINFO.SLOT_UPDATE_TIME then
		self.time_since_last_update = 0
		
		if self.slot and self.slot.tile and self.slot.tile.item then
			self.item = self.slot.tile.item
			self:RefreshInfo()
			
			self:UpdatePos()
			
			if not self.anim_done then
				self:DoShowAnim()
			end
		else
			self.anim_done = false
			self:KillAllChildren()
		end
	end
end

return ItemInfoDesc