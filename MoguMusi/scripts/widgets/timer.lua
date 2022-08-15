local Widget = require "widgets/widget"
local Text = require "widgets/text"
local enemies = require("enemies")
local ex_fns = require "prefabs/player_common_extensions"
local modname = "Timer"

local function GetModInfo(name)
	return GetModConfigData(name,modname) or GetModConfigData(name,KnownModIndex:GetModActualName(modname))
end

local text_size = tonumber("22")
--local scalesize = tonumber(GetModInfo("scalesize") or "1")
local scaletext = true
local hidecdup = false
local seedarkness = false
local colour_attack = true
local colour_cooldown = true
local tick_rate = TheSim:GetTickTime()
local _line_offset = 14
local current_time,line_offset

local function G_col(r,g,b)
	return {r,g,b,1}
end

local colours = {
	G_col(1,1,1),--White
	G_col(0,0,0),--Black
	G_col(1,0,0),--Red
	G_col(0,1,0),--Green
	G_col(0,0,1),--Blue
	G_col(0,1,1),--Cyan
	G_col(1,0,1),--Magenta
	G_col(1,1,0),--Yellow
	G_col(1,0.6,1),--Pink
	G_col(1,0.5,0),--Orange
	G_col(0.2,0,0),--Dark Red
	G_col(1,0.2,0),--Dark Green
	G_col(0,0,0.2),--Dark Blue
	}
local colour_danger = colours[3]--Shouldn't crash with nil values, I think.
local colour_warning = colours[8]
local colour_safe = colours[4]




local Timer =  Class(Widget, function(self, owner)
    self.owner = owner
    Widget._ctor(self, "Timer")
	
	self.last_attack_time = 0
	self.will_attack_again = 0
	self.min_attack_period = 0
	
	self.stage = 0 --An attempt at keeping track of Bee Queen's Stage for her Spawn Bees timer.
	self.stage_cooldown = false
	
	--These values will need to be updated if for some reason the Timer widget gets moved onto another entity//
	local data = enemies[self.owner.prefab]
	self.varying_attack_period = data and data["attack_period_special"] ~= nil
	self.special_period_table = data and data["attack_period_special"]
	self.normal_attack_period = data and data["attack_period"]
	
	self.int_timers = data["int_timers"]
	self.cooldown_text = {}
	--\\
	
	self.text = self:AddChild(Text(NUMBERFONT, text_size))-- Only for attacking, other timers are seperated via text and will be grouped.
	for k,cooldown in pairs(self.int_timers or {}) do 
		local name = "CD_"..k
		self[name] = self:AddChild(Text(NUMBERFONT,text_size))
		self[name.."_time"] = 0
		self[name.."_left"] = 0
		self[name.."_again"] = 0
		self[name]:Show()
		self[name].shown = true
		table.insert(self.cooldown_text,k,self["CD_"..k])
	end
	self.cd_text = ""
    self.isattacking_fn = self:CheckMobTable(self.owner,self)
	
	--Add cooldowns here, group them into a table, use that table as a pointer for modifying and updating all cooldowns for something.
	owner:ListenForEvent("onremove", function() self:Kill() end)
	self:StartUpdating()
end)

function Timer:GetNewFontSizeWithCamera(self)
    local cam = TheCamera
    local new_size = cam and cam.distancetarget > 0 and (30/cam.distancetarget)*text_size or text_size
    if cam and cam.distancetarget > 70 then 
        new_size = new_size * 1.5
    end
		
    local minmax = text_size < 10 and text_size or 10
    local size = (new_size > minmax and new_size) or (new_size <= minmax and 10) or 16
    line_offset = _line_offset*size/16
    self.text:SetSize(size)
    for k,cd in pairs(self.cooldown_text) do
        cd:SetSize(size)
    end
end

local function GetNearbyCountOfEnt(prefab)--Not too keen on looking through all ents as it might cause performance issues, but I do need to keep track of some entity count like spore trees and shadow hands.
	--local ents = {}
	local counter = 0
	local pos = ThePlayer:GetPosition()
	for k,v in pairs(TheSim:FindEntities(pos.x,0,pos.z,70,{},{"INLIMBO"})) do
		if v and v:IsValid() and v.prefab == prefab then
			--table.insert(ents,#ents+1,v)--Don't see a reason why I should add it into a table?
			counter = counter+1
		end
	end
	return counter
end
local function GetOffCooldownTriggerWithMissingEnt(prefab) --This condition should trigger when the entity goes missing, aka dies. If we want to know if there aren't any of those entities, then we just use the function GetNearbyCountOfEnt.
	
	local pos = ThePlayer:GetPosition()--Lol, this was in front of the fw conditions.
	if not pos then return nil end
	
	local function CheckForFuelweaverMinion(ent_prefab)
		return ent_prefab == "stalker_minion1" or ent_prefab == "stalker_minion2"
	end
	
	local fw_minion_cond = prefab == "stalker_minion" and #TheSim:FindEntities(pos.x,0,pos.z,70,{"stalkerminion"},{"INLIMBO"}) == 1
	local fw_dead_minion_cond = prefab == "stalker_minion" --and (ent.prefab == "stalker_minion1" or ent.prefab == "stalker_minion2") and ent.replica.health and ent.replica.health:IsDead()--Ent ain't declared here, that'd be another crash.

	if GetNearbyCountOfEnt(prefab) == 1 or fw_minion_cond then
		for _,ent in pairs(TheSim:FindEntities(pos.x,0,pos.z,70,{},{"INLIMBO"},{"_combat","_health","fx"})) do
			if (ent.prefab == prefab or (fw_dead_minion_cond and CheckForFuelweaverMinion(ent.prefab))) and ent.replica.health and ent.replica.health:IsDead() then
				return true
            elseif ent.prefab == prefab and ent:HasTag("fx") and ent:GetTimeAlive() <= 1 then
               return true 
			end
		end
	end
	return false
end
--/////////
--///Basic condition checker functions:
--/////////

--The functions should support an infinite amonut of conditions(Check through the table and each category).
--Not sure why I only added a check for 2.

local function CheckAnimState(ent,animstate)
	if type(animstate) == "table" then
		return CheckAnimState(ent,animstate[1]) or CheckAnimState(ent,animstate[2])
	end
	if ent and ent.AnimState and ent.AnimState:IsCurrentAnimation(animstate) and ent.AnimState:GetCurrentAnimationTime() == TheSim:GetTickTime() then	
		return true	
	end
end
local function CheckTag(ent,tag)
	if type(tag) == "table" then
		return CheckTag(ent,tag[1]) or CheckTag(ent,tag[2])
	end
	if ent and ent:HasTag(tag) then	
		return true	
	end
end

local function CheckBuild(ent,build)
	--print("Input:"..build)
	--print("Entitystate:"..ent.AnimState:GetBuild())
	if ent and ent.AnimState:GetBuild() == build then
		--print("Input successful")
		return true
	end
end
local function CheckScale(ent,scale)
	local ent_scale = (ent and ent.Transform:GetScale()) or nil
	--print("Input:"..scale)
	--print("Entityscale"..ent_scale)
	if ent and tostring(ent_scale) == scale then
		--print("Input Successful")
		return true
	end
end

local function CheckStage(ent,stage,self)
	if stage == ">0" then
		if self.stage > 0 then
			return true
		end
	else
		if tostring(self.stage) == stage then
			return true
		end
	end
	return false
end

--\\\\\\\\\
--\\\End of basic condition checker functions
--\\\\\\\\\

local function ReturnConditionFromString(_string,ent,self)
	if type(_string) == "table" then
		return ReturnConditionFromString(_string[1],ent,self) or ReturnConditionFromString(_string[2],ent,self)
	end
	local _condition = string.match(_string,"%w+")
	local s,sEnd = string.find(_string,"%w+")
	local value = string.sub(_string,sEnd+2,#_string)--One input condition only, I don't think lots of inputs are needed but only time will tell.
	if _condition == "TAG" then
		--print("Chose to check TAG")
		return	CheckTag(ent,value)
	elseif _condition == "BUILD" then
		--print("Chose to check BUILD")
		return CheckBuild(ent,value)
	elseif _condition == "ANIM" then
		--print("Chose to check ANIM")
		return CheckAnimState(ent,value)
	elseif _condition == "SCALE" then
		--print("Chose to check SCALE")
		return CheckScale(ent,value)
	elseif _condition == "MISSING" then
		return GetOffCooldownTriggerWithMissingEnt(value)
	elseif _condition == "STAGE" then
		return CheckStage(ent,value,self)
	end
end

function Timer:AddStageIfCondition(self,condition,prefab,cooldown)
    if (self.owner.prefab == prefab) or not prefab then
		if ReturnConditionFromString(condition,self.owner,self) or (CheckTag(self.owner,condition) or (CheckAnimState(self.owner,condition) and self.owner.AnimState:GetCurrentAnimationTime() <= tick_rate)) and not self.stage_cooldown then
			self.stage = self.stage + 1
			self.stage_cooldown = true
			self.owner:DoTaskInTime(cooldown or 2,function() self.stage_cooldown = false end )
		end
	end
end

function Timer:ResetStageIfCondition(self,condition,prefab)
	if ReturnConditionFromString(condition,self.owner,self) or (CheckTag(self.owner,condition) or (CheckAnimState(self.owner,condition) and self.owner.AnimState:GetCurrentAnimationTime() <= tick_rate)) then
		if (self.owner.prefab == prefab) or not prefab then --To either trigger on specific entities or just the anim.
			self.stage = 0
			self.stage_cooldown = false
		end
	end
end
function Timer:SetStageIfCondition(stage,self,condition,prefab)
	if ReturnConditionFromString(condition,self.owner,self) or (CheckTag(self.owner,condition) or (CheckAnimState(self.owner,condition) and self.owner.AnimState:GetCurrentAnimationTime() <= tick_rate)) then
		if (self.owner.prefab == prefab) or not prefab then --To either trigger on specific entities or just the anim.
			self.stage = stage or self.stage
		end
	end
end

local function isanim(anim,entity)
    return entity and entity.AnimState and entity.AnimState:IsCurrentAnimation(anim)
end

local function SearchForAnim(anims,entity,self)
	if type(anims) == "table" then
		for _,anim in pairs(anims) do
			if isanim(anim,entity) then
				return true
			end
		end
	else--Should be a string
		return isanim(anims,entity)
	end
	
	return false
end

function Timer:CheckMobTable(entity,self)
	local anim = entity and entity.AnimState
	local prefab = (entity and entity.prefab)
	
	local Anims = function(anims)
		return function() return SearchForAnim(anims,entity,self) end
	end
	
	local mob_table = {
		["default"] = anim and Anims({"atk","gore","were_atk_pre","attack"}),
		["tentacle"] = anim and Anims("atk_loop"),
		["tentacle_pillar_arm"] = anim and Anims("atk_loop"),
		["deerclops"] = anim and Anims({"atk","atk2"}),
		["ghost"] = anim and Anims("angry"),
		["walrus"] = anim and Anims("atk_dart"),
		["little_walrus"] = anim and Anims("abandon"),
		["krampus"] = anim and Anims("atk_pre"),
		["hound"] = anim and Anims("atk_pre"),
		["icehound"] = anim and Anims("atk_pre"),
		["firehound"] = anim and Anims("atk_pre"),
		["moonhound"] = anim and Anims("atk_pre"),
		["koalefant_summer"] = anim and Anims("atk_pre"),
		["koalefant_winter"] = anim and Anims("atk_pre"),
		["shadow_knight"] = anim and Anims({"atk","atk_plus"}), --Knight has atk_plus anim for when he misses his attack.
		["shadow_rook"] = anim and Anims("teleport_pre"),
		["shadow_bishop"] = anim and Anims("atk_side_pre"),
		["toadstool"] = anim and Anims({"attack_basic","attack_infection"}),
		["toadstool_dark"] = anim and Anims({"attack_basic","attack_infection"}),
		["cookiecutter"] = anim and Anims("attack_loop"),
		["klaus"] = anim and Anims("attack_doubleclaw"),
		["spat"] = anim and Anims("strike"),
		["monkey"] = anim and Anims({"throw","atk"}),
		["antlion"] = anim and Anims("cast_pre"),
		["gnarwail"] = anim and Anims("attack_2"),
		["crabking"] = anim and Anims({"cast_purple_pst","cast_blue_pst","frozen"}),
		["spider_warrior"] = anim and Anims({"warrior_atk","atk"}),
		["spider_dropper"] = anim and Anims({"warrior_atk","atk"}),
		["spider_spitter"] = anim and Anims({"spit","atk"}),
		["spider_moon"] = anim and Anims({"hide","atk"}),
		["minotaur"] = anim and Anims("gore"),
		["rook"] = anim and Anims("gore"),
		["rook_nightmare"] = anim and Anims("gore"),
		["tallbird"] = anim and Anims("atk_pre"),
        ["alterguardian_phase1"] = anim and Anims({"tantrum_pre","roll_pre"}),
        ["alterguardian_phase2"] = anim and Anims({"attk_chop","attk_stab_pre"}),
        ["alterguardian_phase3"] = anim and Anims({"attk_swipe","attk_stab2_pre","attk_skybeam","attk_beam","attk_stab"}),
		-------The Forge-------
		["pitpig"] = anim and Anims({"attack1","attack2"}),
		--["crocommander_rapidfire"] uses "attack" anim
		["snortoise"] = anim and Anims("attack1"),
		["scorpeon"] = anim and Anims("attack_pre"),
		["boarilla"] = anim and Anims("attack2"),
		--["rhinocebro"] uses "attack" anim
		--["rhinocebro2"] uses "attack" anim
		["boarrior"] = anim and Anims({"attack1","attack5","attack4"}), --"attack1" his normal melee attack. "attack5" his ground fissure attack, called slam probably. "attack4" I'll try spinning, that's a good trick. "attack2" and "attack3" are follow-up attacks to "attack1". His dash only works when his attack is ready and doesn't really have a cooldown.
		["swineclops"] = anim and (Anims({"block_counter","attack1","attack1b","attack3"}) or (Anims("attack2") and self.stage == 1)),
		-----------------------
        -----Hallowed Forge-----
        ["pitpig_zombie"] =anim and Anims({"attack1","attack2"}),
        ["pitpig_zombie_armored"] = anim and Anims({"attack1","attack2"}),
        ["cursed_mummy"] = anim and Anims("whip_pre"), 
        ["roach_beetle"] = anim and Anims("bite"),
        ["snortoise_ghost"] = anim and Anims("attack1"),
        ["boarilla_skeleton"] = anim and Anims("attack2"),
        ["boarrior_skeleton"] = anim and Anims({"attack1","attack5","attack4"}),
        ["swineclops_mummy"] = anim and (Anims({"block_counter","attack1","attack1b","attack3"}) or (Anims("attack2") and self.stage == 1)),
        ["cursed_helmet"] = anim and Anims({"shoot","attack_slam_pre","attack_blackhole_pre"}),
        ------------------------
	}
	return (anim and mob_table[prefab] ~= nil and mob_table[prefab]) or (anim and mob_table[prefab] == nil and mob_table["default"])
end

function Timer:SpecialTuneCooldown(cooldown,prefab,ent,self)
	local tuner
	if prefab == "toadstool" then
		local links = GetNearbyCountOfEnt("mushroomsprout")
		local level = (links < 1 and 0) or (links < 5 and 1) or (links <8 and 2) or 3
		if cooldown and cooldown.name == "[TS] Mushroom Bomb" then
			cooldown.time = TUNING.TOADSTOOL_ATTACK_PERIOD_LVL[level]
		elseif cooldown and cooldown.name == "[TS] Spore Bomb" then
			cooldown.time = TUNING.TOADSTOOL_SPOREBOMB_CD_PHASE[level] or TUNING.TOADSTOOL_SPOREBOMB_CD_PHASE[1]
		end
	elseif prefab == "toadstool_dark" then
		local links = GetNearbyCountOfEnt("mushroomsprout_dark")
		local level = (links < 1 and 0) or (links < 5 and 1) or (links <8 and 2) or 3
		if cooldown and cooldown.name == "[TS] Mushroom Bomb" then
			cooldown.time = TUNING.TOADSTOOL_ATTACK_PERIOD_LVL[level]
		elseif cooldown and cooldown.name == "[TS] Spore Bomb" then
			cooldown.time = TUNING.TOADSTOOL_SPOREBOMB_CD_PHASE[level] or TUNING.TOADSTOOL_SPOREBOMB_CD_PHASE[1]
		end
	elseif prefab == "klaus" then
		if CheckScale(ent,"1.6799999475479") then
			if cooldown and cooldown.name == "[Klaus] Chomp" then
				cooldown.time = TUNING.KLAUS_CHOMP_CD/TUNING.KLAUS_ENRAGE_SCALE
			end
		elseif CheckScale(ent,"1.2000000476837") and cooldown and cooldown.name == "[Klaus] Chomp" then
			cooldown.time = TUNING.KLAUS_CHOMP_CD
		end
	elseif prefab == "beequeen" then
		if cooldown and cooldown.name == "[BQ] Spawn Bees" then
			cooldown.time = TUNING.BEEQUEEN_SPAWNGUARDS_CD[self.stage] or TUNING.BEEQUEEN_SPAWNGUARDS_CD[1]
		end
		if cooldown and cooldown.name == "[BQ] Focus Target" then
			cooldown.time = TUNING.BEEQUEEN_FOCUSTARGET_CD[self.stage] or TUNING.BEEQUEEN_FOCUSTARGET_CD[1]
		end
	end
end

function Timer:BossStageCheck()
	Timer:AddStageIfCondition(self,"screech","beequeen")--Beequeen
	-------The Forge-------
	Timer:AddStageIfCondition(self,"spit","scorpeon",9999)--No need to retrigger once we know he has entered a new "stage"
	Timer:AddStageIfCondition(self,"MISSING reforged_meteor_splashbase","scorpeon_cultist",9999)--No need to retrigger once we know he has entered a new "stage"
	Timer:SetStageIfCondition(0,self,"block_counter","swineclops")
    Timer:SetStageIfCondition(0,self,"block_counter","swineclops_mummy")
	Timer:SetStageIfCondition(1,self,"attack1","swineclops")
	Timer:SetStageIfCondition(1,self,"attack1","swineclops_mummy")
	Timer:SetStageIfCondition(2,self,"attack1b","swineclops")
	Timer:SetStageIfCondition(2,self,"attack1b","swineclops_mummy")
	-----------------------
end

function Timer:AttackConditions(self,prefab)

	local antlion_speedup = TUNING.ANTLION_SPEED_UP/2--Still not sure why this value triggers twice or gets doubled in my code
	local antlion_min_attack_period = TUNING.ANTLION_MIN_ATTACK_PERIOD
	local antlion_max_attack_period = TUNING.ANTLION_MAX_ATTACK_PERIOD
	local antlion_slow_down = TUNING.ANTLION_SLOW_DOWN/2--Still not sure why this value triggers twice or gets doubled in my code
	
	local ent = self.owner
	local anim = ent.AnimState
	
	local atk_conditions = {
		["antlion"] = function() 
			local current_anim_time = anim:GetCurrentAnimationTime()
			local new_attack_speed = (self.min_attack_period ~= 0 and self.min_attack_period)
			if current_anim_time == tick_rate then
				if SearchForAnim("cast_pre",ent,self) then
					new_attack_speed = math.max(antlion_min_attack_period,self.min_attack_period+antlion_speedup)
				elseif SearchForAnim("eat",ent,self) then
					new_attack_speed = math.min(antlion_max_attack_period,self.min_attack_period+antlion_slow_down)
				end
			end
			
			return new_attack_speed
			
			
			end,
		["waterplant"] = function()
			local yellow_waterplant_atk_period = TUNING.WATERPLANT.YELLOW_ATTACK_PERIOD
			if SearchForAnim("attack",ent,self) and ((self.will_attack_again - current_time) > 2 and (self.will_attack_again - current_time) < 3) then
				self.stage = 1
			end
			
			return self.stage == 1 and yellow_waterplant_atk_period or (self.stage == 0 and nil)
			
			
			end,
		}
		return atk_conditions[prefab] ~= nil and atk_conditions[prefab]()
end

function Timer:CheckSpecialAttackChangeConditions(self)
	local prefabs = {"antlion","waterplant"}
	local ent = self.owner
	local valid_prefab
	for k,name in pairs(prefabs) do
		if ent.prefab == name then
			valid_prefab = true
			break
		end
	end
	if not valid_prefab then --Screw your function! Your prefab ain't gonna change.
        Timer.CheckSpecialAttackChangeConditions = function() return false end
    end
	return self:AttackConditions(self,ent.prefab)
end


function Timer:SetAttackPeriod()
	if self.varying_attack_period then
		for _,period_table in pairs(self.special_period_table) do
			if ReturnConditionFromString(period_table.condition,self.owner,self) then
				self.min_attack_period = period_table.value
				break
			else
				self.min_attack_period = self.normal_attack_period
			end
		end
	else
		self.min_attack_period = Timer:CheckSpecialAttackChangeConditions(self) or self.normal_attack_period
	end
end

function Timer:DisplayTimerInDark()
    if not seedarkness then
       local is_invisible = self.owner:HasTag("invisible")
       local pos = self.owner:GetPosition()
       local is_indarkness = not CanEntitySeePoint(ThePlayer,pos.x,pos.y,pos.z)
       if is_invisible or is_indarkness then
          return false 
       end
    end
    return true
end

function Timer:UpdateAttackTime()
	local anim_time = self.owner and self.owner.AnimState and self.owner.AnimState:GetCurrentAnimationTime()
	if self.isattacking_fn() and ((anim_time <= tick_rate) or self.will_attack_again - current_time <= 0) then--if (Mob in attack animation) and ((It's the first frame of the attack animation) or (Mob should definitely be able to attack)) then [...]
		self.last_attack_time = current_time-tick_rate
		self.will_attack_again = self.last_attack_time + self.min_attack_period
	end
	if self.normal_attack_period == nil then
		self.text:Hide()
		return
	end
	
	if (self.will_attack_again - current_time >= 0) then
		self.text:SetString(string.format("Attack: %.2fs",self.will_attack_again - current_time))
        if self:DisplayTimerInDark() then
            self.text:Show()
        else
            self.text:Hide()
        end
	elseif self.will_attack_again - current_time < 0 then
		self.text:SetString("Attack: Ready")
		if hidecdup or (not self:DisplayTimerInDark()) then
			self.text:Hide()
		end
	end
	if colour_attack then
		self:ApplyColourBasedOnTime(self.text,self.will_attack_again - current_time, self.min_attack_period,true)
	end
end

function Timer:UpdateCooldownTimes()
    -- There seems to be a lot of string concatenation here.
    -- Due to the names not changing, I don't think concatenation is needed here.
    -- I also believe it may cause performance issues considering strings are being concatenated every frame for every mob...
    if not self.int_timers then return end -- Don't let the program go further!
	if self.int_timers then
		for k,v in pairs(self.cooldown_text) do 
			local name = "CD_"..k
			local info = self.int_timers[k]
            local str_time = string.format("%s_time",name)
            local str_again = string.format("%s_again",name)
            local str_left = string.format("%s_left",name)
			local _time = tonumber(self[string.format("%s_time",name)]) -- When the cooldown was triggered(Time taken via GetTime function)
			local _again = tonumber(self[string.format("%s_again",name)]) -- When it should trigger again(_time + cooldown time)
			local _left = tonumber(self[string.format("%s_left",name)]) -- How much time is left for cooldown to be over(_again - current_time)
			
			local off_cooldown_able = info.canoffcooldown and _time+info.time*0.99>current_time--Condition for if it should trigger when the cooldown isn't up. info.canoffcooldown is a special case timer for some mobs.
			local is_anim = info.condition and CheckAnimState(self.owner,info.condition)--Checks the anim state, self explanatory
			local is_tag = info.condition and CheckTag(self.owner,info.condition)--Checks if mob has the tag, also self explanatory
			local cooldown_over = _time+info.time>=current_time --Checks if the cooldown has already expired
			local other_conditions_trigger = ReturnConditionFromString(info.condition,self.owner,self)--Checks for other conditions such as boss stage, mob size, missing an entity, etc.
			
			if info and info.condition and not (off_cooldown_able) and (is_anim or (is_tag and not (cooldown_over) or other_conditions_trigger)) then
				self:SpecialTuneCooldown(info,self.owner.prefab,self.owner,self)
				self[str_time] = current_time; _time = tonumber(self[str_time])-- _time variable won't change if I change the self[name.."_time"] variabl.
				self[str_again] = (is_anim and (_time + info.time - tick_rate)) or (_time + info.time); _again = tonumber(self[str_again])
			end
			if info and info.condition and info.constant and not is_tag and not is_anim then
				self[str_again] = current_time; _time = tonumber(self[str_time])
				self[str_again] = self[str_time] + info.time; _again = tonumber(self[str_again])
			end
			
			self[str_left] = string.format("%.2f",_again - current_time); _left = tonumber(self[str_left])
			local text = ""
			if _left < 0 then
				text = info.name..": ".."Ready"
				
				if info.alwayshidden or hidecdup or (not self:DisplayTimerInDark()) then
					self[name].shown = false
				else
					self[name].shown = true
				end
				
			elseif _left >= 0 then
				text = string.format("%s: %ss",info.name,self[str_left])
				if (info.alwayshidden or hidecdup) and ((_left) > (info.time-tick_rate)) or (not self:DisplayTimerInDark()) then
					self[name].shown = false
				else
					self[name].shown = true
				end
				
			end
			self[name]:SetString(text)
			if colour_cooldown then
				self:ApplyColourBasedOnTime(self[name],_left,info.time)
			end
			if self[name].shown then
				self[name]:Show()
			else
				self[name]:Hide()
			end
		end
	end
end


local function GetPlayerSpeed()
	if not ThePlayer then return nil end
	local player = ThePlayer
	--Locomotor method is bad: it causes issues with other mods thinking lag comp is on and it sometimes causes a random crash.
	return player._playerspeed
end

local function GetAttackRange(self)
	if not self then return nil end
	local mob = self.owner
	return mob and mob.replica and mob.replica.combat and mob.replica.combat._attackrange and mob.replica.combat._attackrange:value()
    -- Mob attack may change. Can't quite assume it will be constant, however, I should set up a listener event for when it changes.
end

local function GetPhysicsRadius(self)
   local mob =  self.owner
   return mob and mob:GetPhysicsRadius()
end

function Timer:ApplyColourBasedOnTime(cd,time,total_time,attack)
	local player_speed = GetPlayerSpeed()
	local attack_range = GetAttackRange(self)
    local physics_radius = GetPhysicsRadius(self)
	if player_speed and attack_range and physics_radius and attack then--Just for the basic attack, inform player of when they have to run.
		local dodge_time = (attack_range-physics_radius)/player_speed
        --Future reference: The time it will take for you to get hit can be predicted:
        --require ("stategraphs/SG"..(MOB_NAME)).states.attack.timeline --This is a table with all functions and times that will be used when the mob attacks
        --timeline.time will return a number value of during which time it will be triggered
        --timeline.fn is the function that will be triggered during the time timeline.time
        --the timeline.fn takes the mob itself as the input. It will do combat to the components.combat.target entity.
        --If I create a copy of any entity that has health and check its health before the function and after the function, I can find the function triggering the attack, i.e. I can find the time the entity will be hit!
        --Though this may generally be resource-heavy and due to human reaction, it cannot be used 100% effectively.
		if time <= dodge_time then
			cd:SetColour(unpack(colour_danger or {1,0,0,1}))--Go!
		elseif time > dodge_time and time-0.3 <= dodge_time then
			cd:SetColour(unpack(colour_warning or {1,1,0,1}))--Set!
		else--
			cd:SetColour(unpack(colour_safe or {0,1,0,1}))--Ready!
		end
	end
	if not attack then
		if time/total_time > 0.67 then--% method
			cd:SetColour(unpack(colour_safe or {0,1,0,1}))
		elseif time/total_time >= 0.33 then
			cd:SetColour(unpack(colour_warning or {1,1,0,1}))
		else
			cd:SetColour(unpack(colour_danger or {1,0,0,1}))
		end
	end
end


function Timer:UpdateTextPositions()
	local offset = 0
	line_offset = line_offset or _line_offset
	for k,cd in pairs(self.cooldown_text) do
		if cd.shown then
			cd:Show()--Just in case
			offset = offset + line_offset
			cd:SetPosition(0,-offset,0)
		end
	end
end

function Timer:OnUpdate(dt)
	if self.owner == nil or not self.owner:IsValid() or (self.owner and self.owner["timer_toremove"]) then
		if self.owner then
			self.owner["timer_toremove"] = nil
		end
		self:StopUpdating()
		self:Kill()
	end
	if scaletext then
		Timer:GetNewFontSizeWithCamera(self)
	end
	
	current_time = GetTime()
	
	self:SetAttackPeriod()
	self:UpdateAttackTime()
		if self.int_timers then
			self:BossStageCheck()
			self:UpdateCooldownTimes() -- I think this one is the most resource heavy function. Should probably optimize something about it.
			self:UpdateTextPositions()
		end
	local x,y,z = TheSim:GetScreenPos(self.owner.Transform:GetWorldPosition())
	self:SetPosition(x,y,z)
end

return Timer
