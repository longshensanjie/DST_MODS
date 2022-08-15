local ItemSlot = require "widgets/itemslot"

local function b(c, d)
    local e = {}
    string.gsub(c, '[^' .. d .. ']+', function(f) table.insert(e, f) end)
    return e
end
local function g(h)
    local i = 0;
    for j, k in pairs(h) do i = i + 1 end
    return i
end
local function l(c)
    if type(c) == "string" then return true end
    return false
end
local function m(c, n)
    local o = b(c, "_")
    if n == true then return o[1] end
    return o[1] .. "_"
end
local function p(c)
    local o = b(c, "_")
    local q = g(o)
    local r = ""
    for s = 1, q - 1, 1 do r = r .. o[s] .. "_" end
    return string.sub(r, 1, string.len(r) - 1)
end
local function t(c)
    local u = {
        "_LOW", "_MED", "_FULL", "_SHORT", "_NORMAL", "_TALL", "_OLD", "_BURNT",
        "_DOUBLE", "_TRIPLE", "_HALLOWEEN", "_STUMP", "_SKETCH",
        "_TACKLESKETCH", "_STONE", "_MARBLE", "_MOONGLASS", "_SPAWNER"
    }
    local v = string.upper(c)
    local o = b(v, "_")
    local w = g(u)
    local x;
    if w > 0 then
        for k = 1, w, 1 do
            x = "_" .. o[g(o)]
            if x == u[k] then
                if l(STRINGS.NAMES["STAGE" .. x]) and l(STRINGS.NAMES[p(v)]) then
                    if x == "_STUMP" or x == "_SKETCH" or x == "_TACKLESKETCH" or
                        x == "_SPAWNER" then
                        return STRINGS.NAMES[p(v)] ..
                                   STRINGS.NAMES["STAGE" .. x]
                    end
                    return STRINGS.NAMES["STAGE" .. x] .. STRINGS.NAMES[p(v)]
                end
            end
        end
    else
        return ""
    end
end
local function y(c)
    local u = {
        "_INV", "_1", "_2", "_3", "_4", "_LAND", "_CONSTRUCTION1",
        "_CONSTRUCTION2", "_CONSTRUCTION3", "_YOTC", "_YOTP"
    }
    local v = string.upper(c)
    local o = b(v, "_")
    local w = g(u)
    local x;
    local z;
    if w > 0 then
        for k = 1, w, 1 do
            x = "_" .. o[g(o)]
            if x == u[k] then
                z = STRINGS.NAMES[p(v)]
                if l(z) then return z end
            end
        end
    else
        return ""
    end
end
local function A(c)
    local B = STRINGS.NAMES[string.upper(c)]
    if B and l(B) then
        return true
    else
        return false
    end
end
local function C(D)
    local E = {"CHILI", "GARLIC", "SALT", "SUGAR"}
    D = string.upper(D)
    for k = 1, 4, 1 do if D == E[k] then return true end end
    return false
end

local TMIP_itemslot = Class(ItemSlot, function(self, owner, atlas, bgim, item)
    ItemSlot._ctor(self, atlas, bgim, owner)
    self.owner = owner
    self.item = item
end)

function TMIP_itemslot:OnControl(K, L)
    if TMIP_itemslot._base.OnControl(self, K, L) then return true end
    if L then
        if K == CONTROL_ACCEPT then
            self:Click(false)
        elseif K == CONTROL_SECONDARY then
            self:Click(true)
        end
        return true
    end
end

function TMIP_itemslot:GetDescription()
    local Item = self.item;
    local N;
    local O = {}
    if Item and Item ~= "" then
        if TOOMANYITEMS.LIST.desclist[self.itemlangstr] then
            N = TOOMANYITEMS.LIST.desclist[self.itemlangstr]
            return N
        end
        if A(Item) then
            N = STRINGS.NAMES[string.upper(Item)]
            return N
        elseif string.find(Item, "_") then
            Item = string.upper(Item)
            O = b(Item, "_")
            if O[1] == "BROKENWALL" then
                N = string.upper(string.sub(Item, 7, -1))
                if N and A(N) then
                    N = STRINGS.NAMES.STAGE_BROKENWALL .. STRINGS.NAMES[N]
                    return N
                end
            end
            if O[2] == "ORNAMENT" then
                if O[3] == "BOSS" then
                    N = O[1] .. "_" .. O[2] .. O[3]
                elseif string.sub(O[3], 1, 5) == "LIGHT" then
                    N = O[1] .. "_" .. O[2] .. "LIGHT"
                elseif string.find(O[3], "FESTIVALEVENTS") then
                    N = tonumber(string.sub(O[3], 15, -1)) <= 3 and "FORGE" or
                            "GORGE"
                    N = O[1] .. "_" .. O[2] .. N
                else
                    N = O[1] .. "_" .. O[2]
                end
                if A(N) then return STRINGS.NAMES[N] end
            end
            if string.find(Item, "_SPICE_") then
                if C(O[3]) then
                    Item = m(Item, true)
                    if A(STRINGS.NAMES[Item]) then
                        N = subfmt(STRINGS.NAMES["SPICE_" .. O[3] .. "_FOOD"],
                                   {food = STRINGS.NAMES[Item]})
                        return N
                    end
                end
            end
            N = t(Item)
            if N then return N end
            N = y(Item)
            if N then return N end
        end
        return string.lower(Item)
    end
end

function TMIP_itemslot:Click(P)
    if self.item then
        local description_txt = self:GetDescription()
        if not description_txt then description_txt = "" end
        local R = P and _G.TOOMANYITEMS.G_TMIP_R_CLICK_NUM or
                      _G.TOOMANYITEMS.G_TMIP_L_CLICK_NUM;
        if TheInput:IsKeyDown(KEY_CTRL) then
            if TheInput:IsKeyDown(KEY_ALT) then
                if P then
                    print("[T键控制台] Teleport to: " .. self.item)
                    SendCommand(gotoonly(self.item))
                    OperateAnnnounce(STRINGS.NAMES.SUPERGOTOTIP .. description_txt)
                else
                    if _G.TOOMANYITEMS.DATA.ADVANCE_DELETE then
                        local S =
                            'local a=%s if a == nil then UserToPlayer("' ..
                                _G.TOOMANYITEMS.DATA.ThePlayerUserId ..
                                '").components.talker:Say("' ..
                                STRINGS.TOO_MANY_ITEMS_UI
                                    .PLAYER_NOT_ON_SLAVE_TIP ..
                                '") end local function b(c)local d=c.components.inventoryitem;return d and d.owner and true or false end;local function e(f)if f and f~=TheWorld and not b(f)and f.Transform then if f:HasTag("player")then if f.userid==nil or f.userid==""then return true end else return true end end;return false end;if a and a.Transform then if a.components.burnable then a.components.burnable:Extinguish(true)end;local g,h,i=a.Transform:GetWorldPosition()local j=TheSim:FindEntities(g,h,i,%s)for k,l in pairs(j)do if e(l)then if l.components then if l.components.burnable then l.components.burnable:Extinguish(true)end;if l.components.firefx then if l.components.firefx.extinguishsoundtest then l.components.firefx.extinguishsoundtest=function()return true end end;l.components.firefx:Extinguish()end end;if l.prefab=="%s"then l:Remove()end end end end'
                        SendCommand(string.format(S, GetCharacter(),
                                                  _G.TOOMANYITEMS.DATA
                                                      .deleteradius, self.item))
                    end
                end
            else
                local T = {}
                if table.contains(_G.TOOMANYITEMS.DATA.customitems, self.item) then
                    print("[T键控制台] Remove custom items: " ..
                              self.item)
                    for s = 1, #_G.TOOMANYITEMS.DATA.customitems do
                        if _G.TOOMANYITEMS.DATA.customitems[s] ~= self.item then
                            table.insert(T, _G.TOOMANYITEMS.DATA.customitems[s])
                        end
                    end
                    TheFocalPoint.SoundEmitter:PlaySound(
                        "dontstarve/HUD/research_unlock")
                    OperateAnnnounce(STRINGS.NAMES.CTRLKEYDOWNTIP .. description_txt ..
                                         STRINGS.NAMES.REMOVEEDITEMSTIP)
                else
                    print("[T键控制台] Add custom items: " .. self.item)
                    table.insert(T, self.item)
                    for s = 1, #_G.TOOMANYITEMS.DATA.customitems do
                        table.insert(T, _G.TOOMANYITEMS.DATA.customitems[s])
                    end
                    TheFocalPoint.SoundEmitter:PlaySound(
                        "dontstarve/HUD/research_available")
                    OperateAnnnounce(STRINGS.NAMES.CTRLKEYDOWNTIP .. description_txt ..
                                         STRINGS.NAMES.ADDEDITEMSTIP)
                end
                _G.TOOMANYITEMS.DATA.customitems = T;
                if _G.TOOMANYITEMS.DATA.listinuse == "custom" then
                    if _G.TOOMANYITEMS.DATA.issearch then
                        self.owner:Search()
                    else
                        self.owner:TryBuild()
                    end
                end
                if _G.TOOMANYITEMS.G_TMIP_DATA_SAVE == 1 then
                    _G.TOOMANYITEMS.SaveNormalData()
                end
            end
        elseif TheInput:IsKeyDown(KEY_SHIFT) then
            print("[T键控制台] Get material from: " .. self.item)
            local S =
                'local player = %s if player == nil then UserToPlayer("' ..
                    _G.TOOMANYITEMS.DATA.ThePlayerUserId ..
                    '").components.talker:Say("' ..
                    STRINGS.TOO_MANY_ITEMS_UI.PLAYER_NOT_ON_SLAVE_TIP ..
                    '") end  local function tmi_give(item) if player ~= nil and player.Transform then local x,y,z = player.Transform:GetWorldPosition() if item ~= nil and item.components then if item.components.inventoryitem ~= nil then if player.components and player.components.inventory then player.components.inventory:GiveItem(item) end else item.Transform:SetPosition(x,y,z) end end end end local function tmi_mat(name) local recipe = AllRecipes[name] if recipe then for _, iv in pairs(recipe.ingredients) do for i = 1, iv.amount do local item = SpawnPrefab(iv.type) tmi_give(item) end end end end for i = 1, %s or 1 do tmi_mat("%s") end'
            SendCommand(string.format(S, GetCharacter(), R, self.item))
            TheFocalPoint.SoundEmitter:PlaySound("dontstarve/HUD/click_object")
            OperateAnnnounce(STRINGS.NAMES.SHIFTKEYDOWNTIP ..
                                 STRINGS.NAMES.GETITEMSMATERIALHTIP .. description_txt ..
                                 STRINGS.NAMES.GETITEMSMATERIALETIP .. " *" .. R)
        else
            print("[T键控制台] SpawnPrefab: " .. self.item)
            local U = self.item;
            local V = 1;
            if string.find(self.item, "critter_") then
                U = self.item .. "_builder"
                V = GetCharacter()
            end
            local W = Profile:GetLastUsedSkinForItem(U)
            if W ~= nil and string.find(self.item, "critter_") and U ~= W then
                local X = b(W, "_")
                W = X[1] .. "_" .. X[2]
            end
            W = W ~= nil and W or self.item;
            local S =
                'local player = %s if player == nil then UserToPlayer("' ..
                    _G.TOOMANYITEMS.DATA.ThePlayerUserId ..
                    '").components.talker:Say("' ..
                    STRINGS.TOO_MANY_ITEMS_UI.PLAYER_NOT_ON_SLAVE_TIP ..
                    '") end local function onturnon(inst) if inst._stage == 3 then if inst.AnimState:IsCurrentAnimation("proximity_pre") or inst.AnimState:IsCurrentAnimation("proximity_loop") or inst.AnimState:IsCurrentAnimation("place3") then inst.AnimState:PushAnimation("proximity_pre") else inst.AnimState:PlayAnimation("proximity_pre") end inst.AnimState:PushAnimation("proximity_loop", true) end end local function onturnoff(inst) if inst._stage == 3 then inst.AnimState:PlayAnimation("proximity_pst") inst.AnimState:PushAnimation("idle3", false) end end if player ~= nil and player.Transform then	if "%s" == "klaus" then	local pos = player:GetPosition() local minplayers = math.huge local spawnx, spawnz FindWalkableOffset(pos,	math.random() * 2 * PI, 33, 16, true, true, function(pt) local count = #FindPlayersInRangeSq(pt.x, pt.y, pt.z, 625) if count < minplayers then minplayers = count spawnx, spawnz = pt.x, pt.z return count <= 0 end return false end) if spawnx == nil then local offset = FindWalkableOffset(pos, math.random() * 2 * PI, 3, 8, false, true) if offset ~= nil then spawnx, spawnz = pos.x + offset.x, pos.z + offset.z end end local klaus = SpawnPrefab("klaus") klaus.Transform:SetPosition(spawnx or pos.x, 0, spawnz or pos.z) klaus:SpawnDeer() klaus.components.knownlocations:RememberLocation("spawnpoint", pos, false) klaus.components.spawnfader:FadeIn() else local x,y,z = player.Transform:GetWorldPosition() for i = 1, %s or 1 do local inst = SpawnPrefab("%s", "%s", nil, "%s") if inst ~= nil and inst.components then	if inst.components.skinner ~= nil and IsRestrictedCharacter(inst.prefab) then inst.components.skinner:SetSkinMode("normal_skin") end if inst.components.inventoryitem ~= nil then if player.components and player.components.inventory then player.components.inventory:GiveItem(inst) end	else inst.Transform:SetPosition(x,y,z) if "%s" == "deciduoustree" then inst:StartMonster(true) end end if not inst.components.health then if inst.components.perishable then inst.components.perishable:SetPercent(%s)	end	if inst.components.finiteuses then inst.components.finiteuses:SetPercent(%s) end if inst.components.fueled then inst.components.fueled:SetPercent(%s) end if inst.components.temperature then	inst.components.temperature:SetTemperature(%s) end if %s ~= 1 and inst.components.follower then inst.components.follower:SetLeader(player) end if "%s" == "moon_altar" then inst._stage =3 inst.AnimState:PlayAnimation("idle3")	inst:AddComponent("prototyper") inst.components.prototyper.trees = TUNING.PROTOTYPER_TREES.MOON_ALTAR_FULL inst.components.prototyper.onturnon = onturnon inst.components.prototyper.onturnoff = onturnoff inst.components.lootdropper:SetLoot({ "moon_altar_idol", "moon_altar_glass", "moon_altar_seed" }) end	end	end end	end	end'
            SendCommand(string.format(S, GetCharacter(), self.item, R,
                                      self.item, W,
                                      _G.TOOMANYITEMS.CHARACTER_USERID,
                                      self.item, _G.TOOMANYITEMS.DATA.xxd,
                                      _G.TOOMANYITEMS.DATA.syd,
                                      _G.TOOMANYITEMS.DATA.fuel,
                                      _G.TOOMANYITEMS.DATA.temperature, V,
                                      self.item))
            TheFocalPoint.SoundEmitter:PlaySound("dontstarve/HUD/click_object")
            OperateAnnnounce(STRINGS.NAMES.SPAWNITEMSTIP .. description_txt .. " *" .. R)
        end
    end
end

return TMIP_itemslot
