-- 别打编织者
local function find_shadowchanneler(inst)
    return inst.prefab == "shadowchanneler"
end
-- 别打食人花和蜘蛛卵
local function find_krauss(inst)
    return inst.prefab == "klaus"
end
-- 旺达别打沙刺
local function find_antion(inst)
    return inst.prefab == "antlion"
end



local comb_rep = GLOBAL.require "components/combat_replica"
local old_IsAlly = comb_rep.IsAlly
function comb_rep:IsAlly(guy, ...)
    if self.inst == GLOBAL.ThePlayer then
        if guy:HasTag("wall") then
            return true
        end
        if guy.prefab == "pumpkin_lantern" then
            return true
        end
        if guy.prefab == "stalker_atrium" and GLOBAL.FindEntity(guy, 30, find_shadowchanneler) then
            return true
        end
        if guy.prefab == "lureplant" and GLOBAL.FindEntity(guy, 30, find_krauss) then
            return true
        end
        if guy.prefab == "spiderden" and GLOBAL.FindEntity(guy, 30, find_krauss) then
            return true
        end
        if GLOBAL.ThePlayer.prefab == "wanda" and guy.prefab == "sandspike_tall" or guy.prefab == "sandspike_med" or guy.prefab ==
            "sandspike_short" or guy.prefab == "sandblock" and GLOBAL.FindEntity(guy, 30, find_antion) then
            return true
        end
    end
    return old_IsAlly(self, guy, ...)
end
