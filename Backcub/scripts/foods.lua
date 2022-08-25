local foods =
{
	paofu = 
	{
		test = function(cooker, names, tags)
			return tags.egg and names.honey and tags.dairy and not tags.veggie and not tags.fruit
		end,
		weight = 1, -- 食谱权重
		priority = 1, -- 食谱优先级
		foodtype = FOODTYPE.VEGGIE, --料理的食物类型，比如这里定义的是肉类
		health = TUNING.CALORIES_TINY, --吃后回血值
		hunger = TUNING.CALORIES_SMALL, --吃后回饥饿值
		sanity = 100, --吃后回精神值
		perishtime = TUNING.PERISH_MED, --腐烂时间
		cooktime = 1, --烹饪时间
		floater = {"med", nil, 0.55},
	},

}

for k, v in pairs(foods) do
    v.name = k
    v.weight = v.weight or 1
    v.priority = v.priority or 0
	--v.overridebuild = "chinesefood"
	v.cookbook_category = "cookpot"
	v.cookbook_atlas = "images/"..k.."c"..".xml"
	v.cookbook_tex = k.."c"..".tex"
end

return foods
