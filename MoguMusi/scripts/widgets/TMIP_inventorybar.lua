local a = require "widgets/widget"
local b = require "TMIP/itemlistcontrol"
local TMIP_itemslot = require "widgets/TMIP_Invslot"
local d = require "widgets/TMIP_Itemtile"
local G_HUD = "images/hud.xml"
local f = 8;
local g = 8;
local h = f * g;
local i = Class(a, function(self, j)
    a._ctor(self, "TMIP_Inventory")
    self.base_scale = .6;
    self.selected_scale = .8;
    self.buildfn = j;
    self.size = 76;
    self:SetScale(self.base_scale)
    self:SetPosition(-130, 190, 0)
    self.listcontrol = b()
    self.slots = self:AddChild(a("SLOTS"))
end)
function i:Build()
    self.build_pending = true;
    self.slots:KillAllChildren()
    if self.inv then
        for k, l in pairs(self.inv) do
            l:Kill()
        end
    end
    self.inv = {}
    local m;
    if TOOMANYITEMS.DATA.issearch then
        m = self.listcontrol:Search()
    else
        self.currentpage = TOOMANYITEMS.DATA.currentpage[TOOMANYITEMS.DATA.listinuse]
        m = self.listcontrol:GetList()
        if not self.currentpage then
            self.currentpage = 1;
            TOOMANYITEMS.DATA.currentpage[TOOMANYITEMS.DATA.listinuse] = 1
        end
    end
    local n = 0;
    if m then
        n = #m
    end
    local o = math.ceil(n / h)
    local p = o == 0 and 1 or o;
    if self.currentpage and self.currentpage > p then
        self.currentpage = 1
    end
    local q = h * self.currentpage;
    if q > n then
        q = n
    end
    local r = 0;
    for s = 1 + (self.currentpage - 1) * h, q do
        local t_item = TMIP_itemslot(self, G_HUD, "inv_slot.tex", m[s])
        local u = r % f;
        local v = math.floor(r / f) * self.size;
        local w = self.size * u;
        self.inv[s] = self.slots:AddChild(t_item)
        t_item:SetTile(d(m[s]))
        t_item:SetPosition(w, -v, 0)
        r = r + 1
    end
    if self.buildfn ~= nil then
        self.buildfn(self.currentpage, p)
    end
    self.build_pending = false
end
function i:TryBuild()
    if not self.build_pending then
        self:Build()
    end
end
function i:Scroll(x)
    local y = self.currentpage;
    self.currentpage = self.currentpage + x;
    if y ~= self.currentpage then
        if not TOOMANYITEMS.DATA.issearch then
            TOOMANYITEMS.DATA.currentpage[TOOMANYITEMS.DATA.listinuse] = self.currentpage;
            if TOOMANYITEMS.G_TMIP_DATA_SAVE == 1 then
                TOOMANYITEMS.SaveNormalData()
            end
        end
        self:TryBuild()
    end
end
return i
