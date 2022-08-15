modimport("languages/Gardeneer_cn.lua")
local Backpackmode = GLOBAL.Profile:GetIntegratedBackpack()
local Increased_height = 10
if Backpackmode and GetModConfigData("boas_BUTTON_SHOW") then Increased_height = 60 end
local _S = GLOBAL.STRINGS.GARDENEER_CLIENT.MODSTRINGS

local nutrient_buttons = {"Formula","Compost","Manure","Water","Soil"}
local nutrient_numbers = {"0", "1-24","25-49","50-99","100"}
local nutrient_names = {_S.formula,_S.compost,_S.manure,"H2O",_S.overcrowd}

local period_groundstatus = 0.1
local period_plants = 1.0

for k,v in pairs(nutrient_buttons) do
	local str = "images/"..v
	local amount = v == "Soil" and 5 or 4
	for i = 1,amount do
		table.insert(Assets,Asset("ATLAS", str..i..".xml"))
		table.insert(Assets,Asset("IMAGE", str..i..".tex"))
	end
end

local _G = GLOBAL

local require = _G.require
local TheSim = _G.TheSim
local TheWorld = _G.TheWorld
local TUNING = _G.TUNING
local bit = _G.bit

local buttons = require("widgets/buttonsGardeneer")
local RegisterHUD = buttons[1]
local NutrientHUD = buttons[2]
local DisplayHUD  = buttons[3]
local DisplayHUDsHidden = true

local PLANT_DEFS = require("prefabs/farm_plant_defs").PLANT_DEFS
local WEED_DEFS  = require("prefabs/weed_defs").WEED_DEFS
local FERTILIZER_DEFS = require("prefabs/fertilizer_nutrient_defs").FERTILIZER_DEFS

local cropMarkerColors
cropMarkerAdd = {
	["killjoy"]  = {0.25,   0,   0},
	["tendable"] = { 0.6, 0.4,   0},
	["thirsty"]  = {   0,   0,0.25},
	["hungry"]   = {   0,   0,   0},
--	["alone"]    = { 0.1,   0,   0}, -- Purple looks too much like red
	["alone"]    = {0.25, 0.5,0.75},
	["both"]     = {   1,   1,0.75}, -- tendable & alone
}
cropMarkerMult = {
	["killjoy"]  = {   1,   0,   0},
	["tendable"] = {   1,   1,   1},
	["thirsty"]  = {0.25,0.25,0.75},
	["hungry"]   = {   0,   1,   0},
--	["alone"]    = {0.75,   0,   1},
	["alone"]    = { 0.5,0.75,   1},
	["both"]     = {   1,   1,   1},
}

local function adjustButtons(self)
	local x, y, x2, y2
	local width, height = TheSim:GetScreenSize()
	local scale = self.top_root:GetScale()
	width  = width  / scale.x / 2
	height = height / scale.y / 2
	local allign = {}
	local location = GetModConfigData("gardeneer_location") or 8
	local sizeb = 64 -- Button Size
	local sized = 10 -- Distance between buttons

	if location == 1 then -- Bottom Right 1
		x = width - 29
		y = -2*height + 102 + sized
		x2 = x
		y2 = y + sizeb + sized
		allign = {-1,1}
	elseif location == 2 then -- Bottom Right 2
		x = width - 123 - sized
		y = -2*height + sized
		x2 = x - sizeb - sized
		y2 = y
		allign = {-1,1}
	elseif location == 3 then -- Bottom Left
		x = -width + sized
		y = -2*height + sized
		x2 = x + sizeb + sized
		y2 = y
		allign = {1,1}
	elseif location == 4 then -- Top Left
		x = -width + sized
		y = -sized
		x2 = x + sizeb + sized
		y2 = y
		allign = {1,-1}
	elseif location == 5 then -- Top
		x = (-sizeb - sized)/2
		y = -sized
		x2 = -x
		y2 = y
		allign = {0,-1}
	elseif location == 6 then -- Top Right
		x = width - 198 - sized
		y = -sized
		x2 = x - sizeb - sized
		y2 = y
		allign = {-1,-1}
	elseif location == 7 then -- Right
		x = width - sized
		x2 = x
		y = -height - (sizeb + sized)/2 - sizeb - sized
		y2 = y + sizeb + sized
		allign = {-1,1}
	else
		-- 功能面板
		if self.buttonRegister then
			self.buttonRegister:Hide()
		end
		if self.buttonNutrient then
			self.buttonNutrient:Hide()
		end
	end
	if self.buttonRegister and self.buttonRegister:IsVisible() then
		self.buttonRegister:SetPosition(x + self.buttonRegister.width*allign[1]/2,
							  y + self.buttonRegister.height*allign[2]/2, 0)
	end
	if self.buttonNutrient and self.buttonNutrient:IsVisible() then
		self.buttonNutrient:SetPosition(x2+ self.buttonNutrient.width*allign[1]/2,
							  y2+ self.buttonNutrient.height*allign[2]/2, 0)
	end

	x = -((#nutrient_buttons-1) * sizeb)/2
	y = -2*height + 100
	allign = {0,1}
	for i = 1,#nutrient_buttons do
		local display = self["display"..nutrient_buttons[i]]
		if display then
			display:SetPosition(x + display.width*allign[1]/2,
						  y + display.height*allign[2]/2+Increased_height, 0)
		end
		x = x + sizeb
	end
end

local function WidgetControlsPostInit(self)
	local display = GetModConfigData("gardeneer_location") == 8
	self.buttonRegister = self.top_root:AddChild(RegisterHUD(display, DEAR_BTNS))
	self.buttonNutrient = self.top_root:AddChild(NutrientHUD(display, DEAR_BTNS))
	for i = 1,#nutrient_buttons do
		local display = "display"..nutrient_buttons[i]
		self[display] = self.top_root:AddChild(DisplayHUD())
		self[display]:SetName(_S[string.lower(nutrient_buttons[i])])
		if i == 1 then
			self[display]:AddKeywords()
		end
		self[display]:Hide()
	end
	DisplayHUDsHidden = true
	adjustButtons(self)
	self.owner.HUD.inst:ListenForEvent("refreshhudsize", function(_self, scale) adjustButtons(self) end)
end
AddClassPostConstruct("widgets/controls", WidgetControlsPostInit)

if GetModConfigData("gardeneer_knowallplants") then
	local function PlantRegistryPostInit(self)
		function self:KnowsSeed(plant, plantregistryinfo) return true end
		function self:KnowsPlantName(plant, plantregistryinfo, research_stage) return true end
		if GetModConfigData("gardeneer_knowallplants") ~= "seeds" then
			function self:IsAnyPlantStageKnown(plant) return true end
			function self:KnowsPlantStage(plant, stage) return true end
			function self:KnowsFertilizer(fertilizer) return true end
		end
	end
	AddClassPostConstruct("plantregistrydata", PlantRegistryPostInit)
end

local function GroundMoisture(ground)
	if not ground or ground.prefab ~= "nutrients_overlay" then return 1.0 end -- Actually wrong, but you can't water regular ground
	return ground.AnimState:GetCurrentAnimationTime()
end

local function GroundNutrients(ground, nutrient) -- nutrient: 1 - Growth Formula, 2 - Compost, 3 - Manure
	if not ground or ground.prefab ~= "nutrients_overlay" then return nil end
	local nutrientlevels = ground.nutrientlevels:value()
	if not nutrient then
		return {bit.band(nutrientlevels,7), bit.band(bit.rshift(nutrientlevels,3),7), bit.band(bit.rshift(nutrientlevels,6),7)}
	end
	return bit.band(bit.rshift(nutrientlevels,(nutrient-1)*3),7)
end

local function GetGround(inst)
	local pos = inst:GetPosition()
	for k,v in pairs(_G.TheWorld.Map:GetEntitiesOnTileAtPoint(pos.x,0,pos.z)) do
		if v.prefab == "nutrients_overlay" then
			return v
		end
	end
	return nil
end

local function NutrientsFulfilled(plant)
	if not plant.plant_def or not plant.plant_def.product then return true end -- Doesn't need nutrients
	local ground = GetGround(plant)
	if not ground then return true end -- Actually not, but the player won't be able to change anything anyway
	local nutrients = GroundNutrients(ground, nil)
	local requirements = PLANT_DEFS[plant.plant_def.product].nutrient_consumption
	if not requirements then return true end -- Not a plant
	for i = 1,3 do
		if requirements[i] ~= nil and requirements[i] > 0 and nutrients[i] == 0 then
			return false
		end
	end
	return true
end

local function HideDisplayHUDs()
	if DisplayHUDsHidden then return false end
	for i = 1,#nutrient_buttons do
		_G.ThePlayer.HUD.controls["display"..nutrient_buttons[i]]:Hide()
	end
	DisplayHUDsHidden = true
	return true
end

local function ShowDisplayHUDs()
	if not DisplayHUDsHidden then return false end
	for i = 1,#nutrient_buttons do
		_G.ThePlayer.HUD.controls["display"..nutrient_buttons[i]]:Show()
	end
	DisplayHUDsHidden = false
	return true
end

--[[
local water_ground = -1
local water_saved, water_time, water_drain, water_timerFound

local function toTimer(seconds)
	seconds = math.floor(math.max(seconds,0.0)+0.5)
	local hours = seconds > 3600 and tostring(math.floor(seconds/3600))..":" or ""
	return hours..string.format("%02.f", math.floor(math.mod(seconds,3600)/60))..":"..string.format("%02.f", math.mod(seconds,60))
end

local function toDays(seconds)
	seconds = math.floor(math.max(seconds,0.0)+0.5)
	return string.format("%.1f", seconds/TUNING.TOTAL_DAY_TIME)
end
]]

local function StagesRemaining(plant)
	if not plant or not plant.AnimState then return nil end
	local AnimState = plant.AnimState
	return   (AnimState:IsCurrentAnimation("grow_seed")   or AnimState:IsCurrentAnimation("crop_seed"))   and 4
		or (AnimState:IsCurrentAnimation("grow_sprout") or AnimState:IsCurrentAnimation("crop_sprout")) and 3
		or (AnimState:IsCurrentAnimation("grow_small")  or AnimState:IsCurrentAnimation("crop_small"))  and 2
		or (AnimState:IsCurrentAnimation("grow_med")    or AnimState:IsCurrentAnimation("crop_med"))    and 1
		or 0
end

local function UpdateNutrientsInfo(invert)
	local ThePlayer = _G.ThePlayer
	if not ThePlayer then return end
	if (not ThePlayer.HUD.nutrientsover.shown) == (not invert) then
		water_ground = -1
		water_drain = nil
		return HideDisplayHUDs()
	end
	local ground = GetGround(ThePlayer)
	if DisplayHUDsHidden then ShowDisplayHUDs() end
	local nutrients = nil
	local perStage = {}
	local total = {}
	local water
	local plantcount = 0
	local pos = ThePlayer:GetPosition()
	for k,plant in pairs(_G.TheWorld.Map:GetEntitiesOnTileAtPoint(pos.x,0,pos.z)) do
		if plant:HasTag("farm_plant") then
			plantcount = plantcount+1
		end
	end
	if ground then
		nutrients = GroundNutrients(ground, nil)
		local pos = ground:GetPosition()
		for k,plant in pairs(_G.TheWorld.Map:GetEntitiesOnTileAtPoint(pos.x,0,pos.z)) do
			if plant:HasTag("farm_plant") and not plant:HasTag("pickable") then
				if plant.plant_def and plant.plant_def.product then
					local toRestore, div = 0, 0
					local seasonMult = PLANT_DEFS[plant.plant_def.product].good_seasons[_G.TheWorld.state.season] and 1 or 0.5
					local stageMult  = StagesRemaining(plant)
					local values = PLANT_DEFS[plant.plant_def.product].nutrient_consumption
					local restores = PLANT_DEFS[plant.plant_def.product].nutrient_restoration
					for i = 1,#values do
						perStage[i] = (perStage[i] or 0) - values[i]*seasonMult
						total[i]    = (total[i]    or 0) - values[i]*stageMult
						toRestore = toRestore + values[i]
						if restores and restores[i] then
							div = div + 1
						end
					end
					div = div > 0 and div or 1
					for i = 1,#values do
						if restores and restores[i] then
							perStage[i] = (perStage[i] or 0) + toRestore*seasonMult/div
							total[i]    = (total[i]    or 0) + toRestore*stageMult/div
						end
					end
--[[
				elseif plant.weed_def and WEED_DEFS[plant.prefab] then
					local values = WEED_DEFS[plant.prefab].nutrient_consumption
					for i = 1,#values do
						requirements[i] = (requirements[i] or 0) + values[i]/2
					end
]]
				end
			end
		end
		water = ground.AnimState:GetCurrentAnimationTime()
	else
		water = _G.TheWorld.state.wetness
		if water then water = water/100.0 end
	end
	if nutrients then
		for i = 1,3 do
			local widget = ThePlayer.HUD.controls["display"..nutrient_buttons[i]]
			widget:UpdateTextures(nutrients[i] == 0 and "Empty" or nutrient_buttons[i]..tostring(nutrients[i]))
			widget:AddValues({perStage[i] or "-",total[i] or "-",nutrient_numbers[nutrients[i]+1] or "-"})
			widget:SetAnnounce("nutrients"..nutrients[i],nutrient_numbers[nutrients[i]+1])
		end
	else
		for i = 1,3 do
			local widget = ThePlayer.HUD.controls["display"..nutrient_buttons[i]]
			widget:UpdateTextures("Empty")
			widget:AddValues({"-","-","-"})
			widget:SetAnnounce()
		end
	end
	local widget = ThePlayer.HUD.controls.displaySoil
	local num = plantcount == 0 and 0 or plantcount > TUNING.FARM_PANT_OVERCROWDING_MAX_PLANTS and 5 or math.max(math.floor(plantcount*4/TUNING.FARM_PANT_OVERCROWDING_MAX_PLANTS),1)
	if num > 5 then num = 5 end
	widget:UpdateTextures(num == 0 and "Empty" or "Soil"..tostring(num))
	local text = tostring(plantcount).."/"..tostring(TUNING.FARM_PANT_OVERCROWDING_MAX_PLANTS)
	widget:AddValues({" "..text})
	if ground then
		widget:SetAnnounce("soil"..num,text)
	else
		widget:SetAnnounce()
	end
	local widget = ThePlayer.HUD.controls.displayWater
	local num = (water == 0.0 or not water) and 0 or math.ceil(water*4)
	if num > 4 then
		num = 4
	end
	widget:UpdateTextures(num == 0 and "Empty" or "Water"..tostring(num))
	widget:AddValues({water and "  "..string.format("%.1f",water*100.0).."%" or "-"})
	if ground then
		widget:SetAnnounce("water"..tostring(num),tostring(math.floor(water*100.0+0.5)).."%")
	else
		widget:SetAnnounce()
	end
	return
end

local function UpdateActiveItemInfo(item)
	if item then
		if item.plant_def then
			local product = item.plant_def.product
			if product then
				local perStage = {}
				local total = {}
				local toRestore, div = 0, 0
				if not PLANT_DEFS[product] then return end -- to make it compatible with other mods
				local seasonMult = PLANT_DEFS[product].good_seasons[_G.TheWorld.state.season] and 1 or 0.5
				local values     = PLANT_DEFS[product].nutrient_consumption
				local restores   = PLANT_DEFS[product].nutrient_restoration
				if not seasonMult or not values or not restores then return end -- "
				for i = 1,#values do
					perStage[i] = (perStage[i] or 0) - values[i]*seasonMult
					total[i]    = (total[i]    or 0) - values[i]*4
					toRestore   = toRestore + values[i]
					if restores[i] then
						div = div + 1
					end
				end
				div = div > 0 and div or 1
				for i = 1,#values do
					if restores[i] then
						perStage[i] = (perStage[i] or 0) + toRestore*seasonMult/div
						total[i]    = (total[i]    or 0) + toRestore*4/div
					end
					local widget = _G.ThePlayer.HUD.controls["display"..nutrient_buttons[i]]
					widget:AddChangeValues({perStage[i],total[i],0})
				end
				local widget = _G.ThePlayer.HUD.controls.displaySoil
				widget:AddChangeValues({1})
				return
			end
		end
		local key = item.GetFertilizerKey and item:GetFertilizerKey() or item.prefab
		if key and FERTILIZER_DEFS[key] then
			local nutrients = FERTILIZER_DEFS[key].nutrients
			if nutrients then
				for i = 1,3 do
					local widget = _G.ThePlayer.HUD.controls["display"..nutrient_buttons[i]]
					widget:AddChangeValues({nutrients[i]})
				end
				return
			end
		end
	end
	for i = 1,5 do
		local widget = _G.ThePlayer.HUD.controls["display"..nutrient_buttons[i]]
		widget:AddChangeValues({0})
	end
end

local function markCropAs(inst, state)
	if not state or not cropMarkerAdd[state] then
		inst.AnimState:SetAddColour(0,0,0,0)
		inst.AnimState:SetMultColour(1,1,1,1)
		inst.cropMarkedAs = nil
		return
	end
	local r,g,b
	r,g,b = _G.unpack(cropMarkerAdd[state])
	inst.AnimState:SetAddColour(r,g,b,1)
	r,g,b = _G.unpack(cropMarkerMult[state])
	inst.AnimState:SetMultColour(r,g,b,1)
	inst.cropMarkedAs = state
	return
end

local KILLJOY_PLANT_MUST_TAGS = {"farm_plant_killjoy"}
local POLLEN_SOURCE_NOT_TAGS = {"farm_plant_killjoy"}
local OVERCROWDING_TAGS = {"farm_plant"}

local function KillJoyStressTest(inst)
	if not inst or not inst.plant_def then return end
	local x,y,z = inst.Transform:GetWorldPosition()
	return #TheSim:FindEntities(x,y,z, TUNING.FARM_PLANT_KILLJOY_RADIUS, KILLJOY_PLANT_MUST_TAGS) > inst.plant_def.max_killjoys_tolerance
end

local function FamilyStressTest(inst)
	if not inst or not inst.plant_def then return end
	local x,y,z = inst.Transform:GetWorldPosition()
	local num_plants = inst.plant_def.family_min_count > 0 and #TheSim:FindEntities(x,y,z, inst.plant_def.family_check_dist, {inst.plant_def.plant_type_tag}, POLLEN_SOURCE_NOT_TAGS) or 0 -- family_min_count includes self
	return num_plants < inst.plant_def.family_min_count
end

local function UpdateCropColor(inst, invert)
	if not inst.AnimState then return end
	if not _G.ThePlayer then return end
	if (not _G.ThePlayer.HUD.nutrientsover.shown) == (not invert) or (inst:HasTag("pickable") and not inst:HasTag("farm_plant_killjoy")) then
		if inst.cropMarkedAs ~= nil then
			markCropAs(inst, nil)
		end
		return
	end
	local state = nil
	if inst:HasTag("farm_plant_killjoy") then
		state = "killjoy"
	elseif inst:HasTag("planted_seed") and FamilyStressTest(inst) then
		state = inst:HasTag("tendable_farmplant") and "both" or "alone"
	elseif inst:HasTag("tendable_farmplant") then
		state = "tendable"
	elseif GroundMoisture(GetGround(inst)) <= 0.0 then
		state = "thirsty"
	elseif not NutrientsFulfilled(inst) then
		state = "hungry"
	end
	if inst.cropMarkedAs ~= state then
		markCropAs(inst, state)
	end
end

AddClassPostConstruct("widgets/nutrientsover", function(self)
	function self:ToggleNutrients(show)
		self.shown = show
	end
end)

AddPrefabPostInitAny(function(inst)
	if inst == _G.TheWorld then
		inst:ListenForEvent("nutrientsvision", function(owner, data)
			if _G.ThePlayer then
				
				local pos = _G.ThePlayer:GetPosition()
				for k,v in pairs(TheSim:FindEntities(pos.x,0,pos.z,40,nil,nil,{"farm_plant","farm_debris"})) do
					UpdateCropColor(v, true)
				end
				UpdateNutrientsInfo(true)
				if not _G.ThePlayer.HUD.nutrientsover.shown then
					_G.StartThread(function()
						while true do
							_G.Sleep(0.2)
							UpdateNutrientsInfo()
						end
					end, "updateNutrients")
				else
					_G.KillThreadsWithID("updateNutrients")
				end
			end
		end)
	elseif inst:HasTag("farm_plant") or inst:HasTag("farm_debris") then
		if inst.plantupdate == nil then
			inst.plantupdate = function() UpdateCropColor(inst) end
			inst:DoPeriodicTask(period_plants, inst.plantupdate, nil, 1)
			inst:DoTaskInTime(0, function() -- Wait for short since the plant gets spawned at 0,0,0 and thus its coordinates are wrong
				inst.plantupdate()
			end)
		end
	end
end)

AddPlayerPostInit(function(inst)
	inst:DoTaskInTime(1, function()
		if inst ~= _G.ThePlayer then return end
		inst:ListenForEvent("newactiveitem", function(owner, data)
			UpdateActiveItemInfo(data.item)
		end)
		if 75 and inst.HUD and inst.HUD.nutrientsover and inst.HUD.nutrientsover.bg then
			inst.HUD.nutrientsover.bg:SetTint(1,1,1,75/100)
		end
	end)
end)