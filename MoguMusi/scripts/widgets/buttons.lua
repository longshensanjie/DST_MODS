local Widget = require "widgets/widget"
local ItemButton = require "widgets/itembutton"
-- ModDataContainer:Load()

local function IsPlatformHopping(inst)
    return inst and inst.sg ~= nil and inst.sg:HasStateTag("jumping") or
               inst.AnimState and
               (inst.AnimState:IsCurrentAnimation("boat_jump_pre") or
                   inst.AnimState:IsCurrentAnimation("boat_jump_loop"))
end

local Buttons = Class(Widget, function(self, owner, inventorybar, heightY)
    Widget._ctor(self, "Buttons")

    self.owner = owner

    self.buttons = {}

    if TheWorld.ismastersim then
        self.inst:ListenForEvent("newactiveitem", function()
            self:Refresh()
        end, self.owner)
        self.inst:ListenForEvent("itemget", function() self:Refresh() end,
                                 self.owner)
        self.inst:ListenForEvent("itemlose", function() self:Refresh() end,
                                 self.owner)
    else
        self.inst:ListenForEvent("refreshinventory",
                                 function() self:Refresh() end, self.owner)
    end

    self.inst:ListenForEvent("playeractivated", function()
        self.inst:DoTaskInTime(0, function() self:Refresh() end)
    end, self.owner)

    self.inst:ListenForEvent("got_on_platform", function() self:Refresh() end,
                             self.owner)

    self.inst:ListenForEvent("got_off_platform", function()
        self.inst:StartThread(function()
            while IsPlatformHopping(self.owner) do Sleep(0) end
            if self.owner and self.owner:IsValid() then
                self:Refresh()
            end
        end)
    end, self.owner)

    self.inst:ListenForEvent("wetdirty", function() self:Refresh() end,
                             TheWorld.net)

    self.rebuild = inventorybar.Rebuild
    inventorybar.Rebuild = function(_self) self:UpdatePositions(_self) end

    self:Build()

    -- 适配45格
    self.heightY = heightY or 0

    owner:ListenForEvent("Mod_Sloth", function(_, style)
        if style == "hide" then
            self.inst:Hide()
        elseif style == "show" then
            self:SlothShow()
        else
            self:SlothTrans()
        end
    end)
end)

local btnCategory = {
    "ARMORHAT", "ARMORBODY", "WEAPON", "CANE", "LIGHTSOURCE", "AXE",
    "PICKAXE", "SHOVEL", "HAMMER", "PITCHFORK", "RANGED", "STAFF"
}
function Buttons:Build()
    for i = 1, #btnCategory do
        self.buttons[i] = self:AddChild(ItemButton("inv_slot_spoiled.tex",
                                                   self.owner, btnCategory[i]))
    end
end

function Buttons:SlothShow()
    for i = 1, #btnCategory do
       if self.buttons[i] and self.buttons[i].bgimage then
            -- self.buttons[i].bgimage:SetTexture(HUD_ATLAS, "inv_slot_spoiled.tex")
            self.buttons[i].bgimage:SetTint(1, 1, 1, 1)
       end
    end
    if self.inst then self.inst:Show() end
end

function Buttons:SlothTrans()
    for i = 1, #btnCategory do
       if self.buttons[i] and self.buttons[i].bgimage then
            self.buttons[i].bgimage:SetTint(0, 0, 0, 0)
       end
    end
    if self.inst then self.inst:Show() end
end

function Buttons:Refresh()
    if self.owner.components.actioncontroller then
        for _, button in pairs(self.buttons) do
            local bestItem =
                self.owner.components.actioncontroller:GetItemFromCategory(
                    button:GetCategory())
            button:SetItem(bestItem)
        end
    end
end

function Buttons:UpdatePositions(inventorybar)
    self.rebuild(inventorybar)
    for i, slot in pairs(inventorybar.inv) do
        if self.buttons[i] then
            local _, sizeY = slot.bgimage:GetSize()
            local slotX = slot:GetPosition().x
            local toprowY = inventorybar.toprow:GetPosition().y
            self.buttons[i]:SetPosition(slotX,
                                        toprowY + (sizeY * 1.5) + self.heightY)
            self.buttons[i]:SetDefaultPosition()
        end
    end
end

return Buttons
