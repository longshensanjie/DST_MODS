local a = {
    ["food"] = true,
    ["seeds"] = true,
    ["equip"] = true,
    ["props"] = true,
    ["magic"] = true,
    ["material"] = true,
    ["gift"] = true,
    ["base"] = true,
    ["cooking"] = true,
    ["tool"] = true,
    ["clothes"] = true,
    ["farming"] = true,
    ["puppet"] = true,
    ["plant"] = true,
    ["ore"] = true,
    ["den"] = true,
    ["building"] = true,
    ["sculpture"] = true,
    ["natural"] = true,
    ["animal"] = true,
    ["boss"] = true,
    ["follower"] = true,
    ["ruins"] = true,
    ["event"] = false
}
local b = {
    ["buildgridplacer"] = true,
    ["cave"] = true,
    ["forest"] = true,
    ["frontend"] = true,
    ["global"] = true,
    ["gridplacer"] = true,
    ["hud"] = true,
    ["ice_splash"] = true,
    ["impact"] = true,
    ["lanternlight"] = true,
    ["sporecloud_overlay"] = true,
    ["thunder_close"] = true,
    ["thunder_far"] = true,
    ["waterballoon_splash"] = true,
    ["world"] = true
}
local c = {}
local d = {MOON_ALTAR = "MOON_ALTAR"}
local function e(f, g) return f < g end
local function h(...)
    local i = {}
    for j, k in ipairs({...}) do for l = 1, #k do table.insert(i, k[l]) end end
    return i
end
function split(m, n)
    local o = {}
    while true do
        local p = string.find(m, n)
        if not p then
            table.insert(o, m)
            break
        end
        local q = string.sub(m, 1, p - 1)
        table.insert(o, q)
        m = string.sub(m, p + 1, string.len(m))
    end
    return o
end
local r = ModManager:GetEnabledModNames()
for l, s in ipairs(r) do
    local t = ModManager:GetMod(s)
    if t.Prefabs then
        for u, v in pairs(t.Prefabs) do
            local w = v.name;
            if not string.find(w, "_fx") and not string.find(w, "_placer") and
                not string.find(w, "_builder") and not string.find(w, "buff") then
                table.insert(c, w)
                if _G.TOOMANYITEMS.MODSATLAS then
                    _G.TOOMANYITEMS.MODSATLAS[w] = t.modname
                end
            end
        end
    end
end
local x = Class(function(self)
    self.beta = BRANCH ~= "release" and true or false;
    self.list = {}
    self:Init()
end)
function x:Init()
    if self.beta then self.betalistpatch = require "TMIP/list/itemlist_beta" end
    local v = 1;
    self.list["all"] = {}
    for y, s in pairs(a) do
        local z = "TMIP/list/itemlist_" .. y;
        self.list[y] = require(z)
        if self.betalistpatch and self.betalistpatch[y] and
            #self.betalistpatch[y] > 0 then
            self.list[y] = h(self.list[y], self.betalistpatch[y])
            self:SortList(self.list[y])
        end
        if s then
            for l = 1, #self.list[y] do
                if not table.contains(self.list["all"], self.list[y][l]) and _G.TOOMANYITEMS.MODSATLAS then
                    self.list["all"][v] = self.list[y][l]
                    _G.TOOMANYITEMS.MODSATLAS[self.list[y][l]] = "all"
                    v = v + 1
                end
            end
        end
    end
    self.list["all"] = h(self.list["all"], c)
    self:SortList(self.list["all"])
    self.list["others"] = {}
    for j, s in pairs(PREFAB_SKINS) do
        if type(s) == "table" then
            for j, A in pairs(s) do b[A] = true end
        end
    end
    for j, s in pairs(Prefabs) do
        if s.assets and self:CanAddOthers(s.name) and _G.TOOMANYITEMS.MODSATLAS then
            table.insert(self.list["others"], s.name)
            _G.TOOMANYITEMS.MODSATLAS[s.name] = "all"
        end
    end
    self:SortList(self.list["others"])
end
function x:GetList() return self:GetListbyName(TOOMANYITEMS.DATA.listinuse) end
function x:GetListbyName(B)
    if B and type(B) == "string" then
        if B == "custom" then
            return TOOMANYITEMS.DATA.customitems
        elseif B == "mods" then
            return c
        else
            return self.list[B]
        end
    else
        TOOMANYITEMS.DATA.listinuse = "all"
    end
    return self.list["all"]
end
function x:Search()
    local C = {}
    local D = self:GetList()
    local w = TOOMANYITEMS.DATA.search;
    for j, s in ipairs(D) do if string.find(s, w) then table.insert(C, s) end end
    for y, s in pairs(STRINGS.NAMES) do
        local E = string.lower(y)
        if type(s) == "table" then
            if d[y] ~= nil then
                s = s[d[y]]
            else
                local F, G = next(s)
                s = G
            end
        end
        if table.contains(D, E) and string.find(string.lower(s), w) and
            not table.contains(C, E) then table.insert(C, E) end
    end
    self:SortList(C)
    return C
end
function x:SortList(D) table.sort(D, e) end
function x:CanAddMod(w)
    local H = not table.contains(self.list["others"], w) and
                  not table.contains(self.list["all"], w) and
                  not table.contains(self.list["animal"], w) and
                  not table.contains(self.list["boss"], w) and
                  not table.contains(self.list["follower"], w) and
                  not table.contains(self.list["ruins"], w) and
                  not table.contains(self.list["event"], w) and
                  not table.contains(self.list["puppet"], w) and
                  not table.contains(self.list["plant"], w) and
                  not table.contains(self.list["ore"], w) and
                  not table.contains(self.list["den"], w) and
                  not table.contains(self.list["building"], w) and
                  not table.contains(self.list["sculpture"], w) and
                  not table.contains(self.list["natural"], w) and
                  not string.find(w, "MOD_") and not string.find(w, "_placer") and
                  not string.find(w, "_builder") and
                  not string.find(w, "_classified") and
                  not string.find(w, "_network") and not string.find(w, "_lvl") and
                  not string.find(w, "_fx") and not string.find(w, "blueprint") and
                  not string.find(w, "buff") and not string.find(w, "map") and
                  not string.find(w, "workshop")
    if not b[w] and H then return true end
    return false
end
function x:CanAddOthers(w)
    local H = not table.contains(self.list["others"], w) and
                  not table.contains(self.list["all"], w) and
                  not table.contains(self.list["animal"], w) and
                  not table.contains(self.list["boss"], w) and
                  not table.contains(self.list["follower"], w) and
                  not table.contains(self.list["ruins"], w) and
                  not table.contains(self.list["event"], w) and
                  not table.contains(self.list["puppet"], w) and
                  not table.contains(self.list["plant"], w) and
                  not table.contains(self.list["ore"], w) and
                  not table.contains(self.list["den"], w) and
                  not table.contains(self.list["building"], w) and
                  not table.contains(self.list["sculpture"], w) and
                  not table.contains(self.list["natural"], w) and
                  not table.contains(c, w) and not string.find(w, "MOD_") and
                  not string.find(w, "_placer") and
                  not string.find(w, "_builder") and
                  not string.find(w, "_classified") and
                  not string.find(w, "_network") and not string.find(w, "_lvl") and
                  not string.find(w, "_fx") and not string.find(w, "blueprint") and
                  not string.find(w, "buff") and not string.find(w, "map") and
                  not string.find(w, "workshop")
    if not b[w] and H then return true end
    return false
end
return x
