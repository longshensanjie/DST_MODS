local a = require "widgets/image"
local b = require "widgets/text"
local c = require "widgets/widget"
local d = "images/inventoryimages1.xml"
local e = "images/inventoryimages2.xml"
local f = "minimap/minimap_data.xml"
local g = require "mods_atlas"
local h = {}
local i = ModManager:GetEnabledModNames()
-- j是引入文件注册的模组
local j = g["register"]
-- i 是所有启用模组
for k, v in ipairs(i) do
    -- l 是一个模组
    local l = ModManager:GetMod(v)

    -- 如果该模组未注册且未导入则导入
    if not table.contains(j, l.modname) and l.Assets then
        g[l.modname] = {}
        for m, n in pairs(l.Assets) do
            for o, p in pairs(n) do
                if string.find(p, ".xml") then
                    table.insert(g[l.modname], p)
                end
            end
        end
    end
end

local function q(r, s)
    local t = {}
    string.gsub(r, "[^" .. s .. "]+", function(u) table.insert(t, u) end)
    return t
end
local function w(x, y, z)
    local A = ""
    for k = y, z, 1 do
        local B = "_"
        if k == z then B = "" end
        A = A .. x[k] .. B
    end
    return A
end
local function C(D, y, z, E)
    local x = q(D, "_")
    if y and z then
        if z < 0 then z = #x + z end
        return w(x, y, z)
    elseif y and E and not z then
        return w(x, y, y + E)
    elseif z and not y and not E then
        return w(x, #x + z, #x)
    else
        return D
    end
end
local function F(G) return G and #G or 0 end
local function H(r)
    if type(r) == "string" then return true end
    return false
end
local function I(r, J)
    local K = q(r, "_")
    if J == true then return K[1] end
    return K[1] .. "_"
end
local function L(r, J)
    local K = q(r, "_")
    local M = F(K)
    if J == true then return K[M] end
    return "_" .. K[M]
end
local function N(r)
    local K = q(r, "_")
    local n = F(K)
    local O = ""
    for k = 1, n - 1, 1 do O = O .. K[k] .. "_" end
    return string.sub(O, 1, string.len(O) - 1)
end
local function P(r, s)
    local K = q(r, s)
    local n = F(K)
    local O = ""
    for k = 2, n, 1 do O = O .. K[k] .. s end
    return string.sub(O, 1, string.len(O) - #s)
end
local function Q(r)
    local R = {
        "_LOW", "_MED", "_FULL", "_SHORT", "_NORMAL", "_TALL", "_OLD", "_BURNT",
        "_DOUBLE", "_TRIPLE", "_HALLOWEEN", "_STUMP", "_SKETCH",
        "_TACKLESKETCH", "_STONE", "_MARBLE", "_MOONGLASS", "_SPAWNER"
    }
    local S = string.upper(r)
    local K = q(S, "_")
    local T = F(R)
    local U;
    if T > 0 then
        for v = 1, T, 1 do
            U = "_" .. K[F(K)]
            if U == R[v] then
                if H(STRINGS.NAMES["STAGE" .. U]) and H(STRINGS.NAMES[N(S)]) then
                    if U == "_STUMP" or U == "_SKETCH" or U == "_TACKLESKETCH" or
                        U == "_SPAWNER" then
                        return STRINGS.NAMES[N(S)] ..
                                   STRINGS.NAMES["STAGE" .. U]
                    end
                    return STRINGS.NAMES["STAGE" .. U] .. STRINGS.NAMES[N(S)]
                end
            end
        end
    else
        return ""
    end
end
local function V(r)
    local R = {
        "_INV", "_1", "_2", "_3", "_4", "_LAND", "_CONSTRUCTION1",
        "_CONSTRUCTION2", "_CONSTRUCTION3", "_YOTC", "_YOTP", "_WAXED"
    }
    local S = string.upper(r)
    local K = q(S, "_")
    local T = F(R)
    local U;
    local W;
    if T > 0 then
        for v = 1, T, 1 do
            U = "_" .. K[F(K)]
            if U == R[v] then
                W = STRINGS.NAMES[N(S)]
                if H(W) then return W end
            end
        end
    else
        return ""
    end
end
local function X(r)
    local Y = STRINGS.NAMES[string.upper(r)]
    if Y and H(Y) then
        return true
    else
        return false
    end
end
local function Z(...)
    local _ = {}
    -- 遍历数组为a1
    for a0, a1 in ipairs({...}) do
        -- 把a1中的所有项插入_表
        for k = 1, #a1 do table.insert(_, a1[k]) end
    end
    return _
end

local function a2(r)
    local a3 = h[r]
    local a4 = {}
    if a3 then a4 = g[a3] end
    -- a5 是a4，和g[all]所有子项的合表
    local a5 = Z(a4, g["all"])
    -- T是a5长度
    local T = F(a5)
    local a6 = r .. ".tex"
    for k = 1, T, 1 do
        if TheSim:AtlasContains(a5[k], a6) then return a5[k] end
    end
    a6 = r .. ".png"
    if TheSim:AtlasContains(f, a6) then return f end
    return nil
end
local function a7(a8)
    local a9 = {"CHILI", "GARLIC", "SALT", "SUGAR"}
    if a8 then
        a8 = string.upper(a8)
        for v = 1, 4, 1 do if a8 == a9[v] then return true end end
    end
    return false
end
local function aa(x, v)
    for a0, m in pairs(x) do if m == v then return true end end
    return false
end
local function ab(x, v)
    for p, m in pairs(x) do if m == v then return p end end
    return -1
end
local function ac(ad)
    local a9 = {"chili", "garlic", "salt", "sugar"}
    local ae = nil;
    local a8 = nil;
    local af = q(ad, "_")
    local ag = ab(af, "spice")
    a8 = af[#af]
    local ah = ""
    ae = ""
    if ad then
        for k = 1, ag - 1, 1 do
            if k < ag - 1 then
                ae = ae .. af[k] .. "_"
            else
                ae = ae .. af[k]
            end
        end
        if aa(a9, a8) and ag == #af - 1 then
            ah = "spice_" .. a8;
            a8 = "spice_" .. a8 .. "_over"
        else
            ah = "spice_" .. a8;
            a8 = "spice_" .. a8 .. "_over"
            if not a2(a8) then
                a8 = "spice_"
                for k = ag + 1, #af, 1 do
                    if k < #af - 1 then
                        a8 = a8 .. af[k] .. "_"
                    else
                        a8 = a8 .. af[k]
                    end
                end
                ah = a8
            end
        end
    end
    return ae, a8, ah
end
local ai = Class(c, function(self, aj)
    c._ctor(self, "ItemTile")
    self.itemlangstr = aj;
    self.itemname = aj;
    self.desc = self:DescriptionInit()
    self:SetTextAndImage()
    h = TOOMANYITEMS.MODSATLAS
end)
function ai:SetText()
    self.image = self:AddChild(a("images/global.xml", "square.tex"))
    self.image:SetTint(0, 0, 0, .8)
    self.text = self.image:AddChild(b(BODYTEXTFONT, 36, ""))
    self.text:SetHorizontalSqueeze(.85)
    self.text:SetMultilineTruncatedString(self:GetDescriptionString(), 2, 68, 8,
                                          true)
end
function ai:SetImage()
    local a5, ak = self:GetAsset()
    if a5 and ak then self.image = self:AddChild(a(a5, ak, "blueprint.tex")) end
end
function ai:SetTextAndImage()
    local a5, ak, al = self:GetAsset(true)
    if a5 and ak then
        self.image = self:AddChild(a(a5, ak))
        if al then self.spiceimage = self:AddChild(a(e, al)) end
        local u, am = self.image:GetSize()
        if math.max(u, am) < 50 then
            self.image:Kill()
            self.image = nil;
            self:SetText()
        else
            self.image:SetScale(50 / u, 50 / am, 1)
        end
    else
        self:SetText()
    end
end
function ai:GetAsset(an)
    if self.itemname == nil then self.itemname = "" end
    local ar = nil;                                             -- altas
    local ao;                                                   -- tex或png
    local al;                                                   -- 调味料理
    local ap = self.itemname;                                   -- name
    local aq;
    if TOOMANYITEMS.LIST.prefablist[self.itemname] then
        ap = TOOMANYITEMS.LIST.prefablist[self.itemname]
    end
    if string.find(ap, "_spice_") then
        local ae, a8, ah = ac(ap)
        ap = ae;
        al = a8 .. ".tex"
    end
    if string.find(ap, "_marble") then ap = N(ap) end
    if string.find(ap, "_sketch") or string.find(ap, "_tacklesketch") then
        ap = L(ap, true)
    end
    ar = a2(ap)
    if ar and ar == f then
        ao = ap .. ".png"
    elseif ar and string.find(ar, "images/") then
        ao = ap .. ".tex"
    else
        ao = nil
    end
    return ar, ao, al
end
function ai:OnControl(as, at)
    self:UpdateTooltip()
    return false
end
function ai:UpdateTooltip() self:SetTooltip(self:GetDescriptionString()) end
function ai:GetDescriptionString() if self.desc then return self.desc end end
function ai:DescriptionInit()
    local ap = self.itemname;
    local au;
    local av = {}
    if ap and ap ~= "" then
        if TOOMANYITEMS.LIST.desclist[self.itemlangstr] then
            au = TOOMANYITEMS.LIST.desclist[self.itemlangstr]
            return au
        end
        if X(ap) then
            au = STRINGS.NAMES[string.upper(ap)]
            return au
        elseif string.find(ap, "_") then
            ap = string.upper(ap)
            av = q(ap, "_")
            if av[1] == "BROKENWALL" then
                au = string.upper(string.sub(ap, 7, -1))
                if au and X(au) then
                    au = STRINGS.NAMES.STAGE_BROKENWALL .. STRINGS.NAMES[au]
                    return au
                end
            end
            if av[2] == "ORNAMENT" then
                if av[3] == "BOSS" then
                    au = av[1] .. "_" .. av[2] .. av[3]
                elseif string.sub(av[3], 1, 5) == "LIGHT" then
                    au = av[1] .. "_" .. av[2] .. "LIGHT"
                elseif string.find(av[3], "FESTIVALEVENTS") then
                    au = tonumber(string.sub(av[3], 15, -1)) <= 3 and
                                "FORGE" or "GORGE"
                    au = av[1] .. "_" .. av[2] .. au
                else
                    au = av[1] .. "_" .. av[2]
                end
                if X(au) then return STRINGS.NAMES[au] end
            end
            if av[#av] == "LEGION" then
                local au = C(ap, 1, -1, nil)
                if X(au) then return STRINGS.NAMES[au] end
            end
            if string.find(ap, "_SPICE_") then
                local ae, a8, ah = ac(string.lower(ap))
                ap = string.upper(ae)
                if X(ap) then
                    if X(ah .. "_food") then
                        return subfmt(
                                    STRINGS.NAMES[string.upper(ah .. "_food")],
                                    {food = STRINGS.NAMES[ap]})
                    elseif X(ah) then
                        return subfmt(STRINGS.NAMES[string.upper(ah)],
                                        {food = STRINGS.NAMES[ap]})
                    end
                    return STRINGS.NAMES[ap]
                end
            end
            au = Q(ap)
            if au then return au end
            au = V(ap)
            if au then return au end
        end
        return string.lower(ap)
    end
end
function ai:OnGainFocus() self:UpdateTooltip() end
return ai
