local require = GLOBAL.require
local BossIndicator = require("widgets/bossindicator")
local EntityScript = require("entityscript")
local Flag_sync = true

GLOBAL.MOD_BOSSINDICATORS = {}
GLOBAL.MOD_BOSSINDICATORS.BOSSES = {}

local function RGB(r, g, b) return {r / 255, g / 255, b / 255, 1} end

AddClassPostConstruct("screens/playerhud", function(self)

    self.AddBossIndicator = function(self, target)
        if not self.bossindicators then self.bossindicators = {} end

        local bi = self.under_root:AddChild(
                       BossIndicator(self.owner, target, RGB(255, 192, 203)))
        table.insert(self.bossindicators, bi)
    end

    self.HasBossIndicator = function(self, target)
        if not self.bossindicators then return end

        for i, v in pairs(self.bossindicators) do
            if v and v:GetTarget() == target then return true end
        end
        return false
    end

    self.RemoveBossIndicator = function(self, target)
        if not self.bossindicators then return end

        local index = nil
        for i, v in pairs(self.bossindicators) do
            if v and v:GetTarget() == target then
                index = i
                break
            end
        end
        if index then
            local bi = table.remove(self.bossindicators, index)
            if bi then bi:Kill() end
        end
    end
end)

AddPlayerPostInit(function(inst) inst:AddComponent("playerbossindicator") end)			-- 给玩家增加指示器？

local Bosses = {
    "deerclops", "bearger", "dragonfly", "moose", "toadstool", "antlion",
    "klaus", "klaus_sack", "beequeen", "beequeenhivegrown", "shadow_rook",
    "shadow_knight", "shadow_bishop", "stalker", "stalker_forest",
    "stalker_atrium", "malbatross", "minotaur", "leif", "leif_sparse",
    "koalefant_summer", "koalefant_winter", "spat", "warg", "dirtpile",
    "spiderqueen", "deer", -- "sculpture_rooknose", 			-- 可疑的大理石
    -- "sculpture_knighthead", 
    -- "sculpture_bishophead", 
    "mermking", "alterguardian_phase1", "alterguardian_phase2",
    "alterguardian_phase3", "eyeofterror", "twinofterror1", "twinofterror2",
    "rook_nightmare", "knight_nightmare", "bishop_nightmare", "rook", "knight",
    "bishop", "gingerbreadwarg", -- "gingerbreadhouse", 
    "gingerbreadpig", "claywarg", -- "firehound","hound","icehound",
    -- "fruitflyfruit",
    "crabking", "chester_eyebone", "hermit_cracked_pearl", "hermit_pearl",
    "hutch_fishbowl", "klaussackkey", "messagebottle",
    -- "moonstorm_static_item",
    -- "terrarium",
    "toadstool_dark", "walrus_camp", "wormhole"
}

if HasModName("insight") then
    Bosses = {
        "dirtpile", "walrus_camp", "rook", "deer", "knight", "bishop",
        "rook_nightmare", "knight_nightmare", "bishop_nightmare",
        "beequeenhivegrown", "wormhole"
    }
end

local function AddBossToIndicatorTable(inst)
    table.insert(GLOBAL.MOD_BOSSINDICATORS.BOSSES, inst)
end

local function RemoveBossFromIndicatorTable(inst)
    local index = nil
    for i, v in ipairs(GLOBAL.MOD_BOSSINDICATORS.BOSSES) do
        if v == inst then
            index = i
            break
        end
    end
    if index then table.remove(GLOBAL.MOD_BOSSINDICATORS.BOSSES, index) end
end

local function SetupBossIndicator(inst)
    AddBossToIndicatorTable(inst)
    inst:ListenForEvent("onremove",
                        function(inst) RemoveBossFromIndicatorTable(inst) end)
end

for _, b in ipairs(Bosses) do
    AddPrefabPostInit(b, function(inst) SetupBossIndicator(inst) end)
end

local function ShowOrHideHUD()
    if not InGame() then return end
    local hud = ThePlayer.HUD.bossindicators
    if hud then
        for k, v in pairs(hud) do
            if Flag_sync then
                v:Hide()
            else
                v:Show()
            end
        end
    end
    Flag_sync = not Flag_sync
end

if GetModConfigData("sw_OBC") and not HasModName("Observer Camera") and
    not HasModName("OB视角") and GetModConfigData("OBC_FUNCTION_KEY_2") then
    GLOBAL.TheInput:AddKeyUpHandler(GetModConfigData("OBC_FUNCTION_KEY_2"),
                                    ShowOrHideHUD)
end

AddPlayerPostInit(function(inst)
    inst:DoTaskInTime(1.44, function()
        if inst == GLOBAL.ThePlayer then
            GLOBAL.ThePlayer:PushEvent("Mod_BossIndicator", LoadModData("Mod_BossIndicator"))
        end
    end)
end)
local tempsave = {}
DEAR_BTNS:AddDearBtn(GLOBAL.GetInventoryItemAtlas("arrowsign_post_circus.tex"), "arrowsign_post_circus.tex", "方向指示", "方向指示可选【隐藏/显示】两种样式", false, function()
	local style =LoadModData("Mod_BossIndicator")
    if style == nil then
        style = true
    end
	TIP("方向指示","pink",style)
	GLOBAL.ThePlayer:PushEvent("Mod_BossIndicator", style)
	if style then
		GLOBAL.MOD_BOSSINDICATORS.BOSSES = tempsave
	else
		tempsave = GLOBAL.MOD_BOSSINDICATORS.BOSSES
		GLOBAL.MOD_BOSSINDICATORS.BOSSES = {}
	end
	SaveModData("Mod_BossIndicator", not style)
end)

if HasModName("insight") then return end

local Toadstool_Cap = nil

AddPrefabPostInit("toadstool", function(inst)
    AddBossToIndicatorTable(inst)
    -- Remove toadstool_cap indicator
    if Toadstool_Cap then RemoveBossFromIndicatorTable(Toadstool_Cap) end

    inst:ListenForEvent("onremove", function(inst)
        RemoveBossFromIndicatorTable(inst)

        -- Re-add toadstool_cap indicator
        if Toadstool_Cap then AddBossToIndicatorTable(Toadstool_Cap) end
    end)
end)

AddPrefabPostInit("toadstool_cap", function(inst)
    inst:DoTaskInTime(0.1, function(inst)
        if inst._state:value() > 0 then
            AddBossToIndicatorTable(inst)
            Toadstool_Cap = inst
        end
    end)
end)