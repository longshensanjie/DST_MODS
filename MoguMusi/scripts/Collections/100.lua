local ImageButton = require "widgets/imagebutton"
local window_null = require "widgets/huxi_null"
local table_imgs = {"ttt1", "ttt2","ttt3","ttt4","ttt5","ttt6"}
local order = 1
local w
local function setOrder(num)
    order = num
    if num > #table_imgs then order = 1 end
    if num < 1 then order = #table_imgs end
end

AddClassPostConstruct("widgets/controls",function(self)
    w = self:AddChild(window_null())
    local img = w:AddChild(ImageButton())
    img:SetTextures("images/ttt.xml", table_imgs[order]..".tex")
    img:SetHAnchor(GLOBAL.ANCHOR_MIDDLE)
    img:SetVAnchor(GLOBAL.ANCHOR_MIDDLE)
    img.OnControl = LROnControl
    img:SetNormalScale(1)
    img:SetFocusScale(1)
    img:SetOnClick(function(lmb)
        if lmb then
            setOrder(order+1)
        else 
            if w:IsVisible() then
                w:Hide()
            end
        end
        img:SetTextures("images/ttt.xml", table_imgs[order]..".tex")
    end)
    img.OnMouseButton = function(_self, button, down, x, y)    --注意:此处应将self.drag_button替换为你要拖拽的widget
		if button == MOUSEBUTTON_MIDDLE and down then    --鼠标中键按下
			-- print("开始拖拽")
			 _self.draging = true    --标志这个widget正在被拖拽，不需要可以删掉
			_self:StartFollowMouse()     --开启控件的鼠标跟随
		elseif button == MOUSEBUTTON_MIDDLE then            --鼠标中键抬起
			_self.draging = false        --标志这个widget没有被拖拽，不需要可以删掉
			_self:StopFollowMouse()        --停止控件的跟随
			-- print("退出拖拽")
		end
	end
    w:Hide()
end)

local function fn()
    if w:IsVisible() then
        w:Hide()
    else
        w:Show()
    end 
end


DEAR_BTNS:AddDearBtn(GLOBAL.GetInventoryItemAtlas("eggplant_oversized.tex"), "eggplant_oversized.tex", "看图", "查数据方便点", true, fn)
