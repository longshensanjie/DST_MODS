local SeedImages = {
    "asparagus_seeds", "carrot_seeds", "corn_seeds", "dragonfruit_seeds",
    "durian_seeds", "eggplant_seeds", "garlic_seeds", "onion_seeds",
    "pepper_seeds", "pomegranate_seeds", "potato_seeds", "pumpkin_seeds",
    "tomato_seeds", "watermelon_seeds"
}
_G = GLOBAL
local HD_cf = 10 ^ 6
local HD_dx = 0.5 + 256 / HD_cf

local TextureReplace = {}
for k, v in pairs(SeedImages) do
    TextureReplace[v .. ".tex"] = {
        _G.resolvefilepath("images/myseeds.xml"), v .. ".tex", HD_dx
    }
end

local Image = _G.require('widgets/image')

local SetTexture_old = Image.SetTexture

local function SetTexture_new(self, atlas, tex, ...)
    local replace = TextureReplace[tex] or nil

    if replace == nil then
        local scale = self.inst.UITransform:GetScale() or nil
        if scale and type(scale) == "number" and math.floor(scale * HD_cf) /
            HD_cf == HD_dx then
            self.inst.UITransform:SetScale(1, 1, 1) -- 修复未做高清的tex在制作栏缩小问题 Shang
        end
        SetTexture_old(self, atlas, tex, ...)
        return
    end

    SetTexture_old(self, replace[1] or atlas, replace[2] or tex, ...) -- replace[2] == tex 否则不兼容快捷宣告

    local scale = replace[3] or nil

    if scale == nil then return end

    self.inst.UITransform:SetScale(scale, scale, scale)
end

Image.SetTexture = SetTexture_new
