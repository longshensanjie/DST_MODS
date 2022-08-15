-- 该mod是蘑菇慕斯私有修改mod，该模组未获得原作者版权，所以请勿搬运
-- 该mod依靠某个BUG运行，请勿修改


local TheInput = GLOBAL.TheInput
local require = GLOBAL.require
TUNING.UNIT = GetModConfigData("sw_shizhong_UNIT") or "T"
-- 语言

-- 导入宣告表
local LANGUAGE = "chinese"
modimport("languages/Announces_cn.lua")

for k,v in pairs(ANNOUNCE_STRINGS) do
	if k ~= "UNKNOWN" and k ~= "_" and GetModConfigData(k) == false then
		ANNOUNCE_STRINGS[k] = ANNOUNCE_STRINGS.UNKNOWN
	end
end

-- 合并宣告字符，在其他mod前加载
if type(GLOBAL.STRINGS._STATUS_ANNOUNCEMENTS) == "table" then
	for k,v in pairs(GLOBAL.STRINGS._STATUS_ANNOUNCEMENTS) do
		ANNOUNCE_STRINGS[k] = v;
	end
end
ANNOUNCE_STRINGS._.LANGUAGE = LANGUAGE -- 翻译，慕斯不管这个

--表情
ANNOUNCE_STRINGS._.STAT_EMOJI = {
	Hunger = "hunger",
	Sanity = "sanity",
	Health = "heart",
	Abigail = "abigail",
	Flex = "flex",
	Battle = "battle",
	Boat = "salt",
	Stamina = "refine",
	Spellpower = "redgem",
	Electric = "lightbulb",
	Bloom = "carrot",
}
-- 将宣告的句子放在全局的表中，让别的mod也能修改
GLOBAL.STRINGS._STATUS_ANNOUNCEMENTS = ANNOUNCE_STRINGS

-- 适配熔炉
if GLOBAL.TheNet:GetServerGameMode() == "lavaarena" then
	GLOBAL.STRINGS._STATUS_ANNOUNCEMENTS.WOODIE = GLOBAL.STRINGS._STATUS_ANNOUNCEMENTS.WOODIE.HUMAN
end

local StatusAnnouncer = require("statusannouncer")()

--实际上需要这个在本地添加控制器按钮提示
local OVERRIDEB =  GetModConfigData("shizhong_SHOWWORLDTEMP")
local boki = GetModConfigData("xuangao_saobao")
local only = GetModConfigData("xuangao_self")
local wandahealthy = GetModConfigData("sw_wanda") and (GetModConfigData("wanda_display") == true)
local OVERRIDESELECT = "Clock"
StatusAnnouncer:SetLocalParameter("WHISPER", GetModConfigData("xuangao_WHISPER"))
StatusAnnouncer:SetLocalParameter("WHISPER_ONLY", false)
StatusAnnouncer:SetLocalParameter("EXPLICIT", true)
StatusAnnouncer:SetLocalParameter("OVERRIDEB", OVERRIDEB)
StatusAnnouncer:SetLocalParameter("OVERRIDESELECT", OVERRIDESELECT)
StatusAnnouncer:SetLocalParameter("SHOWDURABILITY", true)
StatusAnnouncer:SetLocalParameter("SHOWPROTOTYPER", true)
StatusAnnouncer:SetLocalParameter("SHOWEMOJI", true)
StatusAnnouncer:SetLocalParameter("boki", boki)
StatusAnnouncer:SetLocalParameter("wandahealthy", wandahealthy)

local PlayerHud = require("screens/playerhud")
local PlayerHud_SetMainCharacter = PlayerHud.SetMainCharacter
function PlayerHud:SetMainCharacter(maincharacter, ...)
	PlayerHud_SetMainCharacter(self, maincharacter, ...)
	self._StatusAnnouncer = StatusAnnouncer
	if maincharacter then
		--Note that this also clears out the stats and cooldowns, so we have to re-register them
		StatusAnnouncer:SetCharacter(maincharacter.prefab)
		StatusAnnouncer:RegisterCommonStats(self, maincharacter.prefab)
	end
end
local PlayerHud_OnMouseButton = PlayerHud.OnMouseButton
function PlayerHud:OnMouseButton(button, down, ...)
	if button == 1000 and down and TheInput:IsControlPressed(GLOBAL.CONTROL_FORCE_INSPECT) then
		if StatusAnnouncer:OnHUDMouseButton(self) then
			return true
		end
	end
	if type(PlayerHud_OnMouseButton) == "function" then
		return PlayerHud_OnMouseButton(self, button, down, ...)
	end
end


local function find_season_badge(HUD)
	HUD = HUD or GLOBAL.ThePlayer.HUD
	if HUD.controls.seasonclock then
		return HUD.controls.seasonclock, "Clock"
	elseif HUD.controls.season then -- actually needs to get checked before Compact because they both get attached to status
		return HUD.controls.season, "Micro"
	elseif HUD.controls.status.season then
		return HUD.controls.status.season, "Compact"
	end
end


local newCraftSlot = require("widgets/redux/craftingmenu_hud")
local newCraftSlot_OnControl = newCraftSlot.OnControl
function newCraftSlot:OnControl(control, down, ...)
	if down and control == GLOBAL.CONTROL_ACCEPT
	and TheInput:IsControlPressed(GLOBAL.CONTROL_FORCE_INSPECT)
	and self.ui_root 
	then
		if self.pinbar and self.pinbar.focus then
			return StatusAnnouncer:newAnnouncePinbar(self.pinbar)
		end
		if self.craftingmenu and self.craftingmenu.focus and self.craftingmenu.enabled then 
			local menu = self.craftingmenu
			if menu.details_root and menu.details_root.shown and menu.details_root.focus then
				return StatusAnnouncer:newAnnounceDetail(menu.details_root)
			end
			if menu.recipe_grid and menu.recipe_grid.shown and menu.recipe_grid.focus then
				return StatusAnnouncer:newAnnounceGrid(menu.recipe_grid)
			end
			if menu.filter_panel and menu.filter_panel.shown and menu.filter_panel.focus then
				-- 暂时不适配，因为官方无官中
				-- 有官中了，但是没啥好想法，先鸽子了
			end
		end
	elseif not TheInput:IsControlPressed(GLOBAL.CONTROL_FORCE_INSPECT) then
		return newCraftSlot_OnControl(self, control, down, ...)
	end
end



--宣告库存,阻止宣告时制作 - 旧版
for _,classname in pairs({"invslot", "equipslot"}) do
	local SlotClass = require("widgets/"..classname)
	local SlotClass_OnControl = SlotClass.OnControl
	function SlotClass:OnControl(control, down, ...)
		if down and control == GLOBAL.CONTROL_ACCEPT
			and TheInput:IsControlPressed(GLOBAL.CONTROL_FORCE_INSPECT)
			and TheInput:IsKeyDown(GLOBAL.KEY_SHIFT)
			and self.tile then --ignore empty slots
			return StatusAnnouncer:AnnounceItem(self)
		else
			return SlotClass_OnControl(self, control, down, ...)
		end
	end
end

-- 宣告礼物
AddClassPostConstruct("widgets/giftitemtoast", function(self)
	local _OnMouseButton = self.OnMouseButton
	function self:OnMouseButton(button, down, ...)
		local ret = _OnMouseButton(self, button, down, ...)
		if button == GLOBAL.MOUSEBUTTON_LEFT and down and TheInput:IsControlPressed(GLOBAL.CONTROL_FORCE_INSPECT) then
			StatusAnnouncer:Announce(self.enabled
								and ANNOUNCE_STRINGS._.ANNOUNCE_GIFT.CAN_OPEN
								or ANNOUNCE_STRINGS._.ANNOUNCE_GIFT.NEED_SCIENCE)
		end
	end
end)

-- 同屏宣告
local cooldown = false
AddComponentPostInit("playercontroller", function(self, inst)
    if inst ~= GLOBAL.ThePlayer then return end
    local PlayerControllerOnControl = self.OnControl
    self.OnControl = function(self, control, down, ...)
        if InGame() and not cooldown
		and down 
		and control == GLOBAL.CONTROL_PRIMARY -- 左键点击
		and TheInput:IsControlPressed(GLOBAL.CONTROL_FORCE_INSPECT) -- 键盘ALT
		and TheInput:IsKeyDown(GLOBAL.KEY_SHIFT) -- 键盘SHIFT
		and not TheInput:GetHUDEntityUnderMouse() -- 鼠标下不是HUD
		then
			cooldown = GLOBAL.ThePlayer:DoTaskInTime(2, function()
				cooldown = false		-- 2秒的内置CD，万一有人卡键就不会卡死
			end)

			local ent = TheInput:GetWorldEntityUnderMouse()
			if ent and ent.prefab then
				if ent == GLOBAL.ThePlayer then
					return PlayerControllerOnControl(self, control, down, ...)
				end
				if ent:HasTag("player") and ent.name and ent ~= GLOBAL.ThePlayer then
					return StatusAnnouncer:AnnouncePeople(ent)
				end
				local x, _, z = inst.Transform:GetWorldPosition()
				local ents
				if only then
					ents = GLOBAL.TheSim:FindEntities(x,0,z, 80, nil, {'FX','DECOR','INLIMBO','NOCLICK'})
				else
					ents = GLOBAL.TheSim:FindEntities(x,0,z, 80, nil, {'FX','DECOR','NOCLICK'})
				end
				local count = 0
				for k,v in pairs(ents)do
					if v.prefab == ent.prefab and v ~= GLOBAL.ThePlayer then
						if v.replica._ and v.replica._.stackable and v.replica._.stackable._stacksize then
							count = count + v.replica._.stackable._stacksize:value()
						end
						count = count+1
					end
				end
				return StatusAnnouncer:AnnounceCount(count, ent:GetBasicDisplayName(), ent.prefab)
			end
        end
        return PlayerControllerOnControl(self, control, down, ...)
    end
end)
