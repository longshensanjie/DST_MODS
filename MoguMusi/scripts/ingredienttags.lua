
global("FOODTAGDEFINITIONS")
FOODTAGDEFINITIONS = FOODTAGDEFINITIONS or {}

global("AddFoodTag")
AddFoodTag = function(tag, data)
  local mergedData = FOODTAGDEFINITIONS[tag] or {}

  for k, v in pairs(data) do
    mergedData[k] = v
  end

  FOODTAGDEFINITIONS[tag] = mergedData
end

AddFoodTag('meat', { name= "肉", atlas="images/food_tags.xml" })
AddFoodTag('veggie', { name="蔬菜", atlas="images/food_tags.xml" })
AddFoodTag('fish', { name="鱼", atlas="images/food_tags.xml" })
AddFoodTag('sweetener', { name="糖果", atlas="images/food_tags.xml" })

AddFoodTag('monster', { name="怪物肉", atlas="images/food_tags.xml" })
AddFoodTag('fruit', { name="水果", atlas="images/food_tags.xml" })
AddFoodTag('egg', { name="蛋", atlas="images/food_tags.xml" })
AddFoodTag('inedible', { name="树枝", atlas="images/food_tags.xml" })

AddFoodTag('frozen', { name="冰", atlas="images/food_tags.xml" })
AddFoodTag('magic', { name="魔法", atlas="images/food_tags.xml" })
AddFoodTag('decoration', { name="装饰", atlas="images/food_tags.xml" })
AddFoodTag('seed', { name="种子", atlas="images/food_tags.xml" })

AddFoodTag('dairy', { name="乳制品", atlas="images/food_tags.xml" })
AddFoodTag('fat', { name="脂肪", atlas="images/food_tags.xml" })

AddFoodTag('alkaline', { name="碱性", atlas="images/food_tags.xml" })
AddFoodTag('flora', { name="动植物", atlas="images/food_tags.xml" })
AddFoodTag('fungus', { name="真菌", atlas="images/food_tags.xml" })
AddFoodTag('leek', { name="韭菜", atlas="images/food_tags.xml" })
AddFoodTag('citrus', { name="柑橘类", atlas="images/food_tags.xml" })

AddFoodTag('dairy_alt', { name="乳制品", atlas="images/food_tags.xml" })
AddFoodTag('fat_alt', { name="脂肪", atlas="images/food_tags.xml" })

AddFoodTag('mushrooms', { name="蘑菇", atlas="images/food_tags.xml" })
AddFoodTag('nut', { name="坚果", atlas="images/food_tags.xml" })
AddFoodTag('poultry', { name="家禽", atlas="images/food_tags.xml" })
AddFoodTag('pungent', { name="辛辣的", atlas="images/food_tags.xml" })
AddFoodTag('grapes', { name="葡萄", atlas="images/food_tags.xml" })

AddFoodTag('decoration_alt', { name="装饰", atlas="images/food_tags.xml" })
AddFoodTag('seed_alt', { name="种子", atlas="images/food_tags.xml" })

AddFoodTag('root', { name="根", atlas="images/food_tags.xml" })
AddFoodTag('seafood', { name="海鲜", atlas="images/food_tags.xml" })
AddFoodTag('shellfish', { name="贝类", atlas="images/food_tags.xml" })
AddFoodTag('spices', { name="香料", atlas="images/food_tags.xml" })
AddFoodTag('wings', { name="翅膀", atlas="images/food_tags.xml" })

AddFoodTag('monster_alt', { name="怪物肉", atlas="images/food_tags.xml" })
AddFoodTag('sweetener_alt', { name="糖果", atlas="images/food_tags.xml" })

AddFoodTag('squash', { name="南瓜", atlas="images/food_tags.xml" })
AddFoodTag('starch', { name="淀粉", atlas="images/food_tags.xml" })
AddFoodTag('tuber', { name="块茎", atlas="images/food_tags.xml" })
AddFoodTag('precook', { name="预煮的", atlas="images/food_tags.xml" })
AddFoodTag('cactus', { name="仙人掌", atlas="images/food_tags.xml" })
