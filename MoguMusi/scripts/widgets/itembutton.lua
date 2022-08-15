local Button = require("widgets/button")
local Widget = require("widgets/widget")
local Image = require("widgets/image")
local ItemButtonTile = require "widgets/itembuttontile"

local BUTTON_PREFERENCE_CHANGE = true
local BUTTON_AUTO_EQUIP_CHANGE = true

local ItemButton = Class(Widget, function(self, bgim, owner, category)
    Widget._ctor(self, "ItemButton")
    self.owner = owner

    self.bgimage = self:AddChild(Image(HUD_ATLAS, bgim))
    -- self.bgimage:SetTint(0, 0, 0, 0)
    self.category = category
    self.tile = nil
    self.item = nil

    self.highlight_scale = 1.2
    self.base_scale = 1

    self:SetTile(ItemButtonTile(self.category))
end)

function ItemButton:SetDefaultPosition()
    self.default_position = self:GetPosition()
end

function ItemButton:GetCategory()
    return self.category
end

function ItemButton:Highlight()
    if not self.big then
        self:ScaleTo(self.base_scale, self.highlight_scale, .125)
        self.big = true
    end
end

function ItemButton:DeHighlight()
    if self.big then
        if not self.highlight then
            self:ScaleTo(self.highlight_scale, self.base_scale, .25)
        end
        self.big = false
    end
end

function ItemButton:OnGainFocus()
    self:Highlight()
end

function ItemButton:OnLoseFocus()
    self:DeHighlight()
    self:SetPosition(self.default_position)
end

function ItemButton:OnMouseButton(button, down)
    if not self.owner.components.actioncontroller then
        return 
    end

    if button == MOUSEBUTTON_LEFT then
        if down then
            self:SetPosition(self:GetPosition() + Vector3(0,-3,0))
            if self.item then
                self.owner.components.actioncontroller:UseItem(self.item)
            end
        else
            self:SetPosition(self.default_position)
        end
    elseif button == MOUSEBUTTON_RIGHT and down then
        if BUTTON_AUTO_EQUIP_CHANGE and TheInput:IsControlPressed(CONTROL_FORCE_TRADE) then
            self.owner.components.actioncontroller:SetAutoEquipCategory(self.category)
        elseif BUTTON_PREFERENCE_CHANGE and self.item then
            self.owner.components.actioncontroller:ChangePreferredItem(self.category, self.item)
        end
    end
end

function ItemButton:SetTile(tile)
    if self.tile ~= tile then
        if self.tile ~= nil then
            self.tile = self.tile:Kill()
        end
        if tile ~= nil then
            self.tile = self:AddChild(tile)
        end
    end
end

function ItemButton:SetKey(letter)
    self.key = self:AddChild(Button())
    self.key:SetPosition(5, 0, 0)
    self.key:SetFont("stint-ucr")
    self.key:SetTextColour(1, 1, 1, 1)
    self.key:SetTextFocusColour(1, 1, 1, 1)
    self.key:SetTextSize(50)
    self.key:SetText(letter)
end

function ItemButton:SetItem(item)
    if self.tile ~= nil then
        self.item = item
        self.tile:SetImage(item)
    end
end

return ItemButton
