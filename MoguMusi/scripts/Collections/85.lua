--全部角色
local foodall={}
-- 禁止吃这个食物
local banfood = {"jellybean"}


local function OnHungerDelta(inst)
    if  inst.replica.hunger and inst.replica.hunger:GetCurrent() <= GetModConfigData("sw_AUTO_EAT_FOOD") then
        local player = GLOBAL.ThePlayer
        if player then
            local invent = player.replica.inventory
            local items = GetItemsFromAll()
            local must_tag = "preparedfood"                             -- 必须是料理
            local can_tag                                               -- 某些角色可以吃
            local dont_tag                                              -- 某些角色不能吃
            if player.prefab == "wathgrithr" then
                dont_tag = "edible_VEGGIE"
            elseif player.prefab == "wurt" then
                dont_tag = "edible_MEAT"
            -- elseif player.prefab == "wickerbottom" then              -- 老奶奶不吃红色食物
            --     dont_tag = nil
            elseif player.prefab == "wx78" then
                can_tag = "edible_GEARS"
            elseif player.prefab == "wortox" then
                can_tag = "soul"
            end
            
            local function GetNeedFood()
                for _,item in pairs(items)do
                    if ((must_tag and item:HasTag(must_tag)) or (can_tag and item:HasTag(can_tag))) 
                    and not table.contains(banfood, item.prefab) then
                        if dont_tag then
                            if not item:HasTag(dont_tag)then
                                return item
                            end
                        else
                            return item
                        end
                    end
                end
            end

            local food = GetNeedFood()
            if food then
                invent:UseItemFromInvTile(food)
                if food.name ~= "MISSING NAME" then
                    TIP("自动吃饭", "pink", "吃掉 "..food.name)
                else
                    TIP("自动吃饭", "pink", "吃掉了奇怪的东西")
                end
            else
                TIP("自动吃饭", "red", "给口饭吧, 孩子饿饿")
            end
        end
    end
end

AddPlayerPostInit(function(player)
    player:ListenForEvent("hungerdelta", OnHungerDelta)
end)