if GLOBAL.TheNet:GetServerGameMode() == "lavaarena" then return end


local _G = GLOBAL
local require = _G.require


local MOD_EQUIPMENT_CONTROL = {}
MOD_EQUIPMENT_CONTROL.MODNAME = modname
MOD_EQUIPMENT_CONTROL.SPECIALFOOD = require("util/specialfood")
MOD_EQUIPMENT_CONTROL.KEYBINDSERVICE = require("util/keybindservice")(modname)
MOD_EQUIPMENT_CONTROL.STRINGS = require("equipment_control_strings")
MOD_EQUIPMENT_CONTROL.SPAWNING = false
MOD_EQUIPMENT_CONTROL.PICKUP_FILTER = {}
_G.MOD_EQUIPMENT_CONTROL = MOD_EQUIPMENT_CONTROL

require("categories")

local function EntityScriptPostConstruct(self)
    local OldRegisterComponentActions = self.RegisterComponentActions 
    function self:RegisterComponentActions(...)
        if _G.MOD_EQUIPMENT_CONTROL.SPAWNING then
            return
        end
        OldRegisterComponentActions(self, ...)
    end
end
AddGlobalClassPostConstruct("entityscript", "EntityScript", EntityScriptPostConstruct)


-- 固定装备栏
if GetModConfigData("boas_BUTTON_SHOW") then
    local Buttons = require "widgets/buttons"
    local heightY = 0

    if HasModName("45 Inventory") or HasModName("45格") or HasModName("2 Inventory slots") then heightY = 60 end
    AddClassPostConstruct("widgets/inventorybar", function(self)
        self.buttons = self.root:AddChild(Buttons(self.owner, self, heightY))
        local style = LoadModData("SlothStyle") or "trans"
        self.inst:DoTaskInTime(1.22, function()
            if _G.ThePlayer then
                -- print("加载了风格", style)
                _G.ThePlayer:PushEvent("Mod_Sloth", style)
            end
        end)
    end)
    DEAR_BTNS:AddDearBtn(_G.GetInventoryItemAtlas("backpack_crab.tex"), "backpack_crab.tex", "控制栏样式", "虚拟装备栏可选【透明/隐身/全显】三种样式", false, function()
        local style = LoadModData("SlothStyle") or "trans"
        if style == "show" then
            style = "trans"
            TIP("控制栏样式","green","透明")
        elseif style == "trans" then
            style = "hide"
            TIP("控制栏样式","green","隐藏")
        else
            style = "show"
            TIP("控制栏样式","green","显示")
        end
        _G.ThePlayer:PushEvent("Mod_Sloth", style)
        SaveModData("SlothStyle", style)
    end)

end



local Overrides = {}

if GetModConfigData("boas_AUTO_EQUIP_CANE") then
    Overrides.autocane = require("overrides/autocane")
end
if GetModConfigData("boas_AUTO_EQUIP_LIGHTSOURCE") then
    Overrides.autolight = require("overrides/autolight")
end
if GetModConfigData("boas_AUTO_RE_EQUIP_WEAPON") then
    Overrides.autoweapon = require("overrides/autoweapon")
end
if GetModConfigData("boas_AUTO_EQUIP_TOOL") then
    Overrides.autotool = require("overrides/autotool")
end
if GetModConfigData("boas_ELSE") then
    -- Overrides.mousethrough = require("overrides/mousethrough")
    Overrides.woodieregear = require("overrides/woodieregear")
    Overrides.autocandybag = require("overrides/autocandybag")
end

if GetModConfigData("boas_DoubleClick") and not HasModName("musha") and not HasModName("EditedAnims") then
    Overrides.telepoof = require("overrides/telepoof")
end
if GetModConfigData("boas_Quick") then
    Overrides.quickactions = require("overrides/quickactions")
end
if GetModConfigData("boas_AUTO_RE_EQUIP_ARMOR") then
    Overrides.autohelm = require("overrides/autohelm")
end

local function OnPlayerActivated(_, player)
    if player ~= _G.ThePlayer then
        return
    end

    player:AddComponent("actioncontroller")
    player:AddComponent("eventtracker")
    player:AddComponent("itemtracker")

    for _, override in pairs(Overrides) do
        override()
    end
end

local function OnWorldPostInit(inst)
    inst:ListenForEvent("playeractivated", OnPlayerActivated, _G.TheWorld)
end
AddPrefabPostInit("world", OnWorldPostInit)

-- Pickup filter colors
AddPrefabPostInitAny(function(inst)
    if inst and inst.prefab then
        if _G.MOD_EQUIPMENT_CONTROL.PICKUP_FILTER[inst.prefab] then
            if inst.AnimState then
                inst.AnimState:SetMultColour(1, 0, 0, 1)
            end
        end
    end
end)
