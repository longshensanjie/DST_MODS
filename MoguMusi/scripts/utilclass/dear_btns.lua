local DearBtns = Class(function(self)
    self.dear_btns = {}
    self.dear_btn_ids = {}
end)

function DearBtns:AddDearBtn(atlas, tex, destxt, tooltip, tclose, fn)
    if not (atlas and tex) then
        print("注册按钮无效")
        return
    end
    local dearbtn = {}
    dearbtn.atlas = atlas
    dearbtn.tex = tex
    dearbtn.destxt = destxt or ""
    dearbtn.tooltip = tooltip or destxt
    dearbtn.fn = fn or function() print(destxt) end
    dearbtn.tclose = tclose
    if not table.contains(self.dear_btn_ids, dearbtn.destxt) then
        table.insert(self.dear_btn_ids, dearbtn.destxt)
        table.insert(self.dear_btns, dearbtn)
    end
end

function DearBtns:GetBtns()
    return self.dear_btns
end

return DearBtns