local _G = GLOBAL
local AutoSaveManager = require("autosavemanager")
local BloomBadge = require("widgets/bloombadge")
local BloomSaver = nil
local inittask = false

local function CalcBloomRateFn(inst, level, is_blooming, fertilizer)
	local season_mult = 1
	if _G.TheWorld.state.season == "spring" then
		if is_blooming then
			season_mult = TUNING.WORMWOOD_SPRING_BLOOM_MOD
		else
			return TUNING.WORMWOOD_SPRING_BLOOMDRAIN_RATE
		end
	elseif _G.TheWorld.state.season == "winter" then
		if is_blooming then
			season_mult = TUNING.WORMWOOD_WINTER_BLOOM_MOD
		else
			return TUNING.WORMWOOD_WINTER_BLOOMDRAIN_RATE
		end
	end

	local rate = (is_blooming and fertilizer > 0) and (season_mult * (1 + fertilizer * TUNING.WORMWOOD_FERTILIZER_RATE_MOD)) or 1
	return rate
end

local function CalcFullBloomDurationFn(inst, value, remaining, full_bloom_duration)
	value = value * TUNING.WORMWOOD_FERTILIZER_BLOOM_TIME_MOD

	return math.min(remaining + value, TUNING.WORMWOOD_BLOOM_FULL_MAX_DURATION)
end

local function OnSeasonChange(inst, season)
	if season == "spring" and not inst:HasTag("playerghost") then
		inst.components._bloomness:Fertilize()
	else
		inst.components._bloomness:UpdateRate()
	end
end

local function UpdateBloomStage(inst, stage)
	inst.HUD.controls.status.bloombadge:UpdateIcon()
end

local function SyncBloomStage(inst)
	local mult = inst.player_classified.runspeed:value() / TUNING.WILSON_RUN_SPEED
	local stage = _G.RoundBiasedUp(_G.Remap(mult, 1, 1.2, 0, 3))
	local level = inst.components._bloomness:GetLevel()
	if stage ~= level then
		inst.components._bloomness:SetLevel(stage)

		local badge = inst.HUD.controls.status.bloombadge or nil
		if badge ~= nil then
			if stage > level then
				badge:PulseGreen()
			elseif stage < level then
				badge:PulseRed()
			end
		end
	end
end

local function OnBloomFXDirty(inst)
	SyncBloomStage(inst)
end

local function OnNewSpawn(inst)
	inittask = false
	if _G.TheWorld.state.isspring then
		inst.components._bloomness:Fertilize()
	end
end

local function OnLoad(inst)
	inst.components._bloomness:Load(BloomSaver:LoadData())
end

AddPlayerPostInit(function(inst)
	inst:DoTaskInTime(0, function(inst)
		if inst == _G.ThePlayer and inst.prefab == "wormwood" and inst.player_classified ~= nil then
			inst:AddComponent("_bloomness")
			inst.components._bloomness:SetDurations(TUNING.WORMWOOD_BLOOM_STAGE_DURATION, TUNING.WORMWOOD_BLOOM_FULL_DURATION)
			inst.components._bloomness.onlevelchangedfn = UpdateBloomStage
			inst.components._bloomness.calcratefn = CalcBloomRateFn
			inst.components._bloomness.calcfullbloomdurationfn = CalcFullBloomDurationFn
			inst.components._bloomness:DoDelta(0)
			inst:ListenForEvent("bloomfxdirty", OnBloomFXDirty)
			inst:WatchWorldState("season", OnSeasonChange)

			BloomSaver = AutoSaveManager("bloomness", inst.components._bloomness.Save, { inst.components._bloomness })
			BloomSaver:StartAutoSave()

			if inittask then
				OnNewSpawn(inst)
			else
				OnLoad(inst)
			end

			SyncBloomStage(inst)
			UpdateBloomStage(inst, inst.components._bloomness:GetLevel())

			inst.player_classified:ListenForEvent("isghostmodedirty", function(inst)
				if inst.isghostmode:value() then
					_G.ThePlayer.components._bloomness:SetLevel(0)
				elseif _G.TheWorld.state.isspring then
					_G.ThePlayer.components._bloomness:Fertilize()
				end
			end)
		end
	end)
end)

AddPrefabPostInit("world", function(inst)
	inst:ListenForEvent("entercharacterselect", function() inittask = true end)

	if not inst.ismastersim then
		local FERTILIZER_DEFS = require("prefabs/fertilizer_nutrient_defs").FERTILIZER_DEFS
		local _SendRPCToServer = nil
		local act = false
		local active = false
		local chain = false
		local fert = nil

		AddPlayerPostInit(function(inst)
			inst:DoTaskInTime(0, function(inst)
				if inst == _G.ThePlayer and inst.prefab == "wormwood" and inst.player_classified ~= nil then
					if _SendRPCToServer == nil then
						_SendRPCToServer = _G.SendRPCToServer

						_G.SendRPCToServer = function(...)
							local arg = { ... }

							if arg[2] == _G.ACTIONS.FERTILIZE.code and (not _G.ThePlayer:HasTag("busy") or chain) then
								act = true
								chain = false

								if arg[1] == _G.RPC.LeftClick then
									active = true
									fert = _G.ThePlayer.replica.inventory:GetActiveItem()
								elseif arg[1] == _G.RPC.UseItemFromInvTile or arg[1] == _G.RPC.ControllerUseItemOnSceneFromInvTile or arg[1] == _G.RPC.ControllerUseItemOnSelfFromInvTile then
									fert = arg[3]
								else
									act = false
								end
							elseif act then
								if arg[1] == _G.RPC.InspectItemFromInvTile then
									act = false
								elseif active and arg[1] == _G.RPC.ClearActionHold then
									active = false
								end
							end

							return _SendRPCToServer(...)
						end

						local _CloseWardrobe = _G.POPUPS.WARDROBE.Close
						_G.POPUPS.WARDROBE.Close = function(...)
							if inst == _G.ThePlayer and inst.components._bloomness ~= nil then
								inst:DoTaskInTime(1, UpdateBloomStage)
							end
							return _CloseWardrobe(...)
						end

						local _CloseGiftItem = _G.POPUPS.GIFTITEM.Close
						_G.POPUPS.GIFTITEM.Close = function(...)
							if inst == _G.ThePlayer and inst.components._bloomness ~= nil then
								inst:DoTaskInTime(1, UpdateBloomStage)
							end
							return _CloseGiftItem(...)
						end
					end

					inst.player_classified:ListenForEvent("isperformactionsuccessdirty", function(inst)
						if not act then return end

						if _G.ThePlayer.AnimState:IsCurrentAnimation(fert:HasTag("slowfertilize") and "fertilize" or "short_fertilize") then
							if inst.isperformactionsuccess:value() then
								local val = FERTILIZER_DEFS[fert.fertilizerkey or fert.prefab].nutrients[TUNING.FORMULA_NUTRIENTS_INDEX]

								if val > 0 then
									_G.ThePlayer.components._bloomness:Fertilize(val)
									print("FERTILIZE SUCCESS: " ..tostring(val))
								end

							end

							chain = true
						else
							chain = false
						end

						if not active then
							act = false
							fert = nil
						end
					end)
				end
			end)
		end)
	else
		AddPlayerPostInit(function(inst)
			inst:DoTaskInTime(0, function(inst)
				if inst == _G.ThePlayer and inst.prefab == "wormwood" and inst.components.bloomness ~= nil then
					local _Fertilize = inst.components.bloomness.Fertilize
					inst.components.bloomness.Fertilize = function(self, value)
						if self.inst.components._bloomness ~= nil then
							self.inst.components._bloomness:Fertilize(value)
							print("FERTILIZE SUCCESS: " ..tostring(value))
						end
						return _Fertilize(self, value)
					end

					if inst.components.skinner ~= nil then
						local _SetSkinMode = inst.components.skinner.SetSkinMode
						inst.components.skinner.SetSkinMode = function(...)
							local r = { _SetSkinMode(...) }
							UpdateBloomStage(inst)
							return _G.unpack(r)
						end
					end
				end
			end)
		end)
	end
end)


-- 注意：接下来两个功能必须启用智能模组！
local function enable_combined_status()
	return IsInMODlist({"季节时钟","Combined Staus", "组合状态", "合并状态栏",}) or GetModConfigData("sw_shizhong")
end

local function enable_status_announcements()
	return IsInMODlist({"快捷宣告","Status Announcements"}) or GetModConfigData("sw_xuangao")
end


AddClassPostConstruct("widgets/statusdisplays", function(self)
	if not self.owner or self.owner.prefab ~= "wormwood" then return end

	self.bloombadge = self:AddChild(BloomBadge(self.owner, enable_combined_status()))
	self.bloombadge:SetPosition(-120, 20)
	self._custombadge = self.bloombadge

	self.onbloomdelta = function(owner, data) self:BloomDelta(data) end
	self.inst:ListenForEvent("bloomdelta", self.onbloomdelta, self.owner)

	function self:BloomDelta(data)
		self.bloombadge:SetPercent(data.newval, data.max, data.rate, data.is_blooming)
		SyncBloomStage(self.owner)

		if (data.newval - data.oldval) >= TUNING.WORMWOOD_FERTILIZER_BLOOM_TIME_MOD then
			self.bloombadge:PulseGreen()
			_G.TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/health_up")
		end
	end

	if enable_combined_status() then
		local Text = require("widgets/text")
		self.bloombadge:SetPosition(-62, -52)
		self.bloombadge.rate = self.bloombadge:AddChild(Text(_G.NUMBERFONT, 28))
		self.bloombadge.rate:SetPosition(2, -40.5, 0)
		self.bloombadge.rate:SetScale(1,.78,1)
		self.bloombadge.rate:Hide()

		local _OnHide = self.bloombadge.maxnum.OnHide
		self.bloombadge.maxnum.OnHide = function(self, ...)
			self.parent.rate:Hide()
			if self.parent.active then
				self.parent.num:Show()
			end
			return _OnHide(self, ...)
		end

		local _OnShow = self.bloombadge.maxnum.OnShow
		self.bloombadge.maxnum.OnShow = function(self, ...)
			self.parent.num:Hide()
			if self.parent.active then
				self.parent.rate:Show()
			end
			return _OnShow(self, ...)
		end


		function self.bloombadge:OnHide()
			if self.parent.boatmeter then
				self.parent.boatmeter:SetPosition(-62, -52)
			end
		end

		function self.bloombadge:OnShow()
			if self.parent.boatmeter then
				self.parent.boatmeter:SetPosition(-124, -52)
			end
		end

		if self.boatmeter then
			self.boatmeter.inst:ListenForEvent("open_meter", function(inst)
				if inst.widget.parent.bloombadge.shown then
					inst.widget:SetPosition(-124, -52)
				else
					inst.widget:SetPosition(-62, -52)
				end
			end)
		end
	else
		self.bloombadge.num:SetSize(25)
		self.bloombadge.num:SetScale(1,.9,1)
		self.bloombadge.num:SetPosition(3, 3)

		local _ShowStatusNumbers = self.ShowStatusNumbers
		self.ShowStatusNumbers = function(self, ...)
			if self.bloombadge ~= nil then
				self.bloombadge.num:Show()
			end
			return _ShowStatusNumbers(self, ...)
		end

		local _HideStatusNumbers = self.HideStatusNumbers
		self.HideStatusNumbers = function(self, ...)
			if self.bloombadge ~= nil then
				self.bloombadge.num:Hide()
			end
			return _HideStatusNumbers(self, ...)
		end
	end
end)

if enable_status_announcements() then
	local PlayerHud = require("screens/playerhud")
	local PlayerHud_SetMainCharacter = PlayerHud.SetMainCharacter
	function PlayerHud:SetMainCharacter(maincharacter, ...)
		PlayerHud_SetMainCharacter(self, maincharacter, ...)
		if maincharacter.prefab == "wormwood" then
			_G.STRINGS._STATUS_ANNOUNCEMENTS.UNKNOWN.STAGE_0 = { BLOOM = { ANY = "需要催长剂..." } }
			_G.STRINGS._STATUS_ANNOUNCEMENTS.UNKNOWN.STAGE_1 = { BLOOM = { ANY = "含苞待放。" } }
			_G.STRINGS._STATUS_ANNOUNCEMENTS.UNKNOWN.STAGE_2 = { BLOOM = { ANY = "野蛮生长！" } }
			_G.STRINGS._STATUS_ANNOUNCEMENTS.UNKNOWN.STAGE_3 = { BLOOM = { ANY = "绽放吧!" } }
			_G.STRINGS._STATUS_ANNOUNCEMENTS.UNKNOWN.STAGE_4 = { BLOOM = { ANY = "花骨朵儿下垂~" } }
			_G.STRINGS._STATUS_ANNOUNCEMENTS.UNKNOWN.STAGE_5 = { BLOOM = { ANY = "凋零..." } }

			self.inst:DoTaskInTime(0, function()
				if self._StatusAnnouncer then
					self._StatusAnnouncer:RegisterStat(
						"Bloom",
						self.controls.status.bloombadge,
						_G.CONTROL_ROTATE_LEFT,
						{},
						{"ANY"},
						function(ThePlayer)
							return	self.controls.status.bloombadge.val,
									self.controls.status.bloombadge.max
						end,
						function(ThePlayer)
							local level = ThePlayer.components._bloomness:GetLevel()
							if (level == 1 or level == 2) and not ThePlayer.components._bloomness.is_blooming then
								level = level + 3
							end

							return	"STAGE_" .. level
						end
					)
				end
			end)
		end
	end
end
