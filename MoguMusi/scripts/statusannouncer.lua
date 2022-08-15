-- 该mod是蘑菇慕斯私有修改mod，该模组未获得原作者版权，所以请勿搬运至其他页面
-- 该mod依靠某个BUG运行，请勿修改
local WHISPER = false
local WHISPER_ONLY = false
local EXPLICIT = true
local OVERRIDEB = true
local OVERRIDESELECT = true
local SHOWDURABILITY = true
local SHOWPROTOTYPER = true
local SHOWEMOJI = true
local boki = false
local wandahealthy = false

local setters = {
    WHISPER = function(v)
        WHISPER = v
    end,
    WHISPER_ONLY = function(v)
        WHISPER_ONLY = v
    end,
    EXPLICIT = function(v)
        EXPLICIT = v
    end,
    OVERRIDEB = function(v)
        OVERRIDEB = v
    end,
    OVERRIDESELECT = function(v)
        OVERRIDESELECT = v
    end,
    SHOWDURABILITY = function(v)
        SHOWDURABILITY = v
    end,
    SHOWPROTOTYPER = function(v)
        SHOWPROTOTYPER = v
    end,
    SHOWEMOJI = function(v)
        SHOWEMOJI = v
    end,
    boki = function(v)
        boki = v
    end,
    wandahealthy = function(v)
        wandahealthy = v
    end
}

local needs_strings = {
    NEEDSCIENCEMACHINE = "RESEARCHLAB",
    NEEDALCHEMYENGINE = "RESEARCHLAB2",
    NEEDSHADOWMANIPULATOR = "RESEARCHLAB3",
    NEEDPRESTIHATITATOR = "RESEARCHLAB4",
    NEEDSANCIENT_FOUR = "ANCIENT_ALTAR"
}

local StatusAnnouncer = Class(function(self)
    self.cooldown = false
    self.cooldowns = {}
    self.stats = {}
    self.button_to_stat = {}
    self.char_messages = STRINGS._STATUS_ANNOUNCEMENTS.UNKNOWN
end, nil, {})

local emojiTable = {
    emoji_abigail = {"阿比盖尔之花"},
    emoji_alchemyengine = {"炼金引擎"},
    emoji_arcane = {},
    emoji_backpack = {"背包"},
    emoji_battle = {},
    emoji_beefalo = {"皮弗娄牛"},
    emoji_beehive = {"蜂窝"},
    emoji_berry_bush = {"浆果丛", "多汁浆果丛"},
    emoji_carrot = {"胡萝卜"},
    emoji_chest = {"箱子"},
    emoji_chester = {"切斯特", "眼骨"},
    emoji_crockpot = {"烹饪锅"},
    emoji_egg = {"鸟蛋", "煎蛋"},
    emoji_eyeball = {"独眼巨鹿眼球"},
    emoji_eyeplant = {"食人花种子", "眼球草"},
    emoji_faketeeth = {"假牙"},
    emoji_farm = {},
    emoji_fire = {"营火", "吸热营火"},
    emoji_firepit = {"火坑", "吸热火坑"},
    emoji_flex = {},
    emoji_ghost = {"幽灵"},
    emoji_gold = {"金块"},
    emoji_grave = {"墓碑"},
    emoji_hambat = {"火腿棒"},
    emoji_hammer = {"锤子"},
    emoji_heart = {"生命值", "告密的心"},
    emoji_horn = {"牛角"},
    emoji_hunger = {"饥饿值"},
    emoji_lightbulb = { -- "提灯","矿工帽",                     -- 避免歧义
    "南瓜灯"},
    emoji_meat_big = {"大肉"},
    emoji_pig = {"猪皮", "猪人", "猪头"},
    emoji_poop = {"粪肥"},
    emoji_redgem = {"红宝石"},
    emoji_refine = {},
    emoji_salt = {"盐晶"},
    emoji_sanity = {"理智值"},
    emoji_sciencemachine = {"科学机器"},
    emoji_shadowmanipulator = {"暗影操控器"},
    emoji_shovel = {"铲子"},
    emoji_skull = {"骷髅"},
    emoji_thumbsup = {},
    emoji_tophat = {"高礼帽"},
    emoji_torch = {"火炬"},
    emoji_trap = {"陷阱"},
    emoji_web = {"蜘蛛丝"},
    emoji_wormhole = {"虫洞"},

    emoji_trophy = {"蘑菇蛋糕"}, -- 写代码怎么能没有私货！
    emoji_wave = {"舞台之手"}
}

local function Cemoji(emojistr)
    if (not IsSteam() and TheWorld.ismastersim) then
        return emojistr
    end
    for k, v in pairs(emojiTable) do
        if table.contains(v, emojistr) then
            if TheInventory and TheInventory:CheckOwnership(k) then
                return ":" .. EMOJI_ITEMS[k].input_name .. ":"
            end
        end
    end
    return emojistr
end


local function GetTrue_()
    local S = STRINGS._STATUS_ANNOUNCEMENTS
    return S._.getArticle and S._ or S.__
end


local function changeM(message)
    local function quickC(olds,news,mess)
        if mess and mess:find(olds) then
            return (string.gsub(mess,olds,news))
        else
            return mess        
        end
    end
    local S = GetTrue_().ANNOUNCE_SUBFMT[string.upper(boki)]
    local res = S.res or {}
    local suffix = S.suffix or ""
    local suffix_emoji = S.suffix_emoji or false 
    for _,v in pairs(res) do
        message = quickC(v[1],v[2],message)
    end
    message = message .. suffix
    if suffix_emoji and (IsSteam() or not TheWorld.ismastersim) and TheInventory and TheInventory:CheckOwnership("emoji_"..suffix_emoji) then
        message = message..":"..suffix_emoji..":" 
    end
    return message
end

-- 这个宣告只是检查是否按下私聊按键(CTRL), 不会检查shift和alt，所以需要自己写
function StatusAnnouncer:Announce(message)
    if boki then message = changeM(message) end

    if message and not self.cooldown and not self.cooldowns[message] then
        local whisper = TheInput:IsKeyDown(KEY_CTRL) or TheInput:IsControlPressed(CONTROL_MENU_MISC_3)
        self.cooldown = ThePlayer:DoTaskInTime(1, function()
            self.cooldown = false
        end)
        self.cooldowns[message] = ThePlayer:DoTaskInTime(10, function()
            self.cooldowns[message] = nil
        end)
        TheNet:Say(STRINGS.LMB .. " " .. message, WHISPER_ONLY or WHISPER ~= whisper)
    end
    return true
end
-- 获取容器名
local function get_container_name(container)
    if not container then
        return
    end
    local container_name = container:GetBasicDisplayName()
    local container_prefab = container and container.prefab
    local underscore_index = container_prefab and container_prefab:find("_container")
    -- container name was empty or blank, and matches the bundle container prefab naming system
    if type(container_name) == "string" and container_name:find("^%s*$") and underscore_index then
        container_name = STRINGS.NAMES[container_prefab:sub(1, underscore_index - 1):upper()]
    end
    return container_name and container_name:lower()
end
-- 宣告冷却
local function GetTimeString(intime)
    local STRING_TIME_DEFAULT = "--:--"
    local result = STRING_TIME_DEFAULT
    local t = math.floor(intime)

    if t > 0 then
        local minute = 0
        local second = 0

        if t < 60 then
            second = t
        else
            minute = math.floor(t / 60)
            second = t - (minute * 60)
        end

        if minute < 10 then
            minute = "0" .. minute
        end

        if second < 10 then
            second = "0" .. second
        end

        result = minute .. ":" .. second
    end
    return result
end
local function ann_cooldown(inst)
    local rechargetime = inst.rechargetime
    local timeleft = math.floor(rechargetime - (rechargetime * inst.rechargepct))
    timeleft = timeleft <= 0 and 0 or timeleft
    local timestring = GetTimeString(timeleft + 1)

    return timeleft, timestring
end


-- 宣告物品（新鲜度，耐久）
function StatusAnnouncer:AnnounceItem(slot)
    local item = slot.tile.item
    local container = slot.container
    local percent = nil
    local percent_type = nil
    local thermal_stone_warmth = nil
    if slot.tile.percent then
        percent = slot.tile.percent:GetString()
        percent_type = "DURABILITY"
    elseif slot.tile.hasspoilage then
        percent = math.floor(item.replica.inventoryitem.classified.perish:value() * (1 / .62)) .. "%"
        percent_type = "FRESHNESS"
    end
    local S = GetTrue_() -- To save some table lookups
    -- 暖石宣告
    if item.prefab == "heatrock" then
		-- Try to get thermal stone temperature range to announce
		local image_hash = item.replica.inventoryitem:GetImage()
		local hash_lookup = {}
		local skin_name = item.AnimState:GetSkinBuild()
		if skin_name == "" then
			skin_name = "heat_rock"
		end
		for i = 1,5 do
			hash_lookup[hash(skin_name .. i .. ".tex")] = i
		end
		local range = hash_lookup[image_hash]
		if range ~= nil and range >= 1 and range <= 5 then
			thermal_stone_warmth = S.ANNOUNCE_ITEM.HEATROCK[range]
		end
	end



    if container == nil or (container and container.type == "pack") then
        -- \equipslots/        \backpacks/
        container = ThePlayer.replica.inventory
    end
    local num_equipped = 0
    if not container.type then -- this is an inventory
        -- add in items in equipslots, which don't normally get counted by Has
        for _, slot in pairs(EQUIPSLOTS) do
            local equipped_item = container:GetEquippedItem(slot)
            if equipped_item and equipped_item.prefab == item.prefab then
                num_equipped = num_equipped +
                                   (equipped_item.replica.stackable and equipped_item.replica.stackable:StackSize() or 1)
            end
        end
    end
    local container_name = get_container_name(container.type and container.inst)
    -- Try to trace the path from construction container to the constructionsite that spawned it
    if not container_name then
        if not container_name then
            local player = container.inst.entity:GetParent()
            local constructionbuilder = player and player.components and player.components.constructionbuilder
            if constructionbuilder and constructionbuilder.constructionsite then
                container_name = get_container_name(constructionbuilder.constructionsite)
            end
        end
    end
    local name = item:GetBasicDisplayName():lower()
    local has, num_found = container:Has(item.prefab, 1)
    num_found = num_found + num_equipped
    local i_have = ""
    local in_this = ""
    if container_name then -- this is a chest
        i_have = S.ANNOUNCE_ITEM.WE_HAVE
        in_this = S.ANNOUNCE_ITEM.IN_THIS
    else -- this is a backpack or inventory
        i_have = S.ANNOUNCE_ITEM.I_HAVE
        container_name = ""
    end
    local this_many = "" .. num_found
    local plural = num_found > 1
    local with = ""
    local durability = ""
    if SHOWDURABILITY and percent then
        with = plural and S.ANNOUNCE_ITEM.AND_THIS_ONE_HAS or S.ANNOUNCE_ITEM.WITH
        durability = percent and S.ANNOUNCE_ITEM[percent_type]
    else
        percent = ""
    end
    local a = S.getArticle(name)
    local s = S.S
    if (not plural) or string.find(name, s .. "$") ~= nil then
        s = ""
    end
    if thermal_stone_warmth then
		if plural then
			with = S.ANNOUNCE_ITEM.AND_THIS_ONE_IS .. thermal_stone_warmth .. S.ANNOUNCE_ITEM.WITH
		else			
			name = thermal_stone_warmth .. " " .. name
		end
	end
    if this_many == nil or this_many == "1" then
        this_many = a
    end

    local announce_str = subfmt(S.ANNOUNCE_ITEM.FORMAT_STRING, {
        I_HAVE = i_have,
        THIS_MANY = this_many,
        ITEM = Cemoji(name),
        S = s,
        IN_THIS = in_this,
        CONTAINER = Cemoji(container_name),
        WITH = with,
        PERCENT = percent,
        DURABILITY = durability
    })

    -- 必须是CD长的，不然没啥意义
    if item:HasTag("rechargeable") and type(slot.tile.rechargetime) == "number" and slot.tile.rechargetime > 15 then
        local timeleft, timestring = ann_cooldown(slot.tile)
        local cooldown = ""
        local ts = ""
        if timeleft < 2 then
            cooldown = S.ANNOUNCE_COOLDOWN.COOLDOWN_OK
        elseif timeleft < 20 then
            cooldown = S.ANNOUNCE_COOLDOWN.COOLDOWN_PRE
            ts = "(" .. timestring .. ")"
        else
            cooldown = S.ANNOUNCE_COOLDOWN.COOLDOWN_WAIT
            ts = timestring .. S.ANNOUNCE_COOLDOWN.END
        end
        local onehas = S.ANNOUNCE_COOLDOWN.AND_THIS_ONE_HAS
        local ctn = Cemoji(container_name)
        if ctn == "" then
            i_have = S.ANNOUNCE_COOLDOWN.I_HAVE
            this_many = ""
            s = ""
            in_this = ""
            onehas = ""
        end

        announce_str = subfmt(S.ANNOUNCE_COOLDOWN.INCONTAINER, {
            I_HAVE = i_have,
            THIS_MANY = this_many,
            ITEM = Cemoji(name),
            S = s,
            IN_THIS = in_this,
            CONTAINER = ctn,
            AND_THIS_ONE_HAS = onehas,
            COOLDOWN = cooldown,
            TIMESTRING = ts
        })
    end

    return self:Announce(announce_str)
end

local hint_text = {
    ["SCIENCEMACHINE"] = "NEEDSCIENCEMACHINE",
    ["ALCHEMYMACHINE"] = "NEEDALCHEMYENGINE",
    ["SHADOWMANIPULATOR"] = "NEEDSHADOWMANIPULATOR",
    ["PRESTIHATITATOR"] = "NEEDPRESTIHATITATOR",
    ["CANTRESEARCH"] = "CANTRESEARCH",
    ["ANCIENTALTAR_HIGH"] = "NEEDSANCIENT_FOUR",
    ["SPIDERCRAFT"] = "NEEDSSPIDERFRIENDSHIP"
}

local function GetMinPrototyperTree(recipe)
	local validmachines = {}
	local adjusted_level = deepcopy(recipe.level)

	-- Adjust recipe's level for bonus so that the hint gives the right message
	local tech_bonus = ThePlayer.replica.builder:GetTechBonuses()
	for k, v in pairs(adjusted_level) do
		adjusted_level[k] = math.max(0, v - (tech_bonus[k] or 0))
	end

	for k, v in pairs(TUNING.PROTOTYPER_TREES) do
		local canbuild = CanPrototypeRecipe(adjusted_level, v)
		if canbuild then
			table.insert(validmachines, {TREE = tostring(k), SCORE = 0})
		end
	end

	if #validmachines > 0 then
		if #validmachines == 1 then
			--There's only once machine is valid. Return that one.
			return validmachines[1].TREE
		end

		--There's more than one machine that gives the valid tech level! We have to find the "lowest" one (taking bonus into account).
		for k,v in pairs(validmachines) do
			for rk,rv in pairs(adjusted_level) do
				local prototyper_level = TUNING.PROTOTYPER_TREES[v.TREE][rk]
				if prototyper_level and (rv > 0 or prototyper_level > 0) then
					if rv == prototyper_level then
						--recipe level matches, add 1 to the score
						v.SCORE = v.SCORE + 1
					elseif rv < prototyper_level then
						--recipe level is less than prototyper level, remove 1 per level the prototyper overshot the recipe
						v.SCORE = v.SCORE - (prototyper_level - rv)
					end
				end
			end
		end

		table.sort(validmachines, function(a,b) return (a.SCORE) > (b.SCORE) end)

		return validmachines[1].TREE
	end

	return "CANTRESEARCH"
end

local tree_to_prefab = {
	SCIENCEMACHINE = "RESEARCHLAB",
	ALCHEMYMACHINE = "RESEARCHLAB2",
	SHADOWMANIPULATOR = "RESEARCHLAB3",
	PRESTIHATITATOR = "RESEARCHLAB4",
	ANCIENTALTAR_LOW = "ANCIENT_ALTAR_BROKEN",
	ANCIENTALTAR_HIGH = "ANCIENT_ALTAR",
	FISHING = "TACKLESTATION",
	SEAFARING_STATION = "SEAFARING_PROTOTYPER",
	-- Spidercraft doesn't seem to correspond to any prefab, so leaving it out
	-- A bunch more from TUNING.PROTOTYPER_TREES could be added here,
	-- but these were the only ones in CraftingMenuDetails
}

local function GetMinPrototyper(recipe)
	local prefab = tree_to_prefab[GetMinPrototyperTree(recipe)]
	if prefab ~= nil then
		return STRINGS.NAMES[prefab] or prefab
	end
	return prefab
end

function StatusAnnouncer:Breathy(recipe_name)
    local recipe = GetValidRecipe(recipe_name)
    local S = GetTrue_()
    local builder = ThePlayer.replica.builder
    local buffered = builder:IsBuildBuffered(recipe.name)
    local knows = builder:KnowsRecipe(recipe.name) or CanPrototypeRecipe(recipe.level, builder:GetTechTrees())
    local can_build = builder:CanBuild(recipe.name)
    local strings_name = STRINGS.NAMES[recipe.product:upper()] or STRINGS.NAMES[recipe.name:upper()]
    local name = strings_name and strings_name:lower() or "<missing_string>"
    local a = S.getArticle(name)
    local prototyper = ""
    if not knows then
		prototyper = GetMinPrototyper(recipe) or prototyper
	end
    local prototyper_tree = GetMinPrototyperTree(recipe)
    local teaser_string = STRINGS.UI.CRAFTING[hint_text[prototyper_tree] or prototyper_tree]
    local CRAFTING = STRINGS.UI.CRAFTING
    for needs_string, prototyper_prefab in pairs(needs_strings) do
        if teaser_string == CRAFTING[needs_string] then
            prototyper = STRINGS.NAMES[prototyper_prefab]:lower()
        end
    end

    return S, builder, buffered, knows, can_build, name, a, prototyper
end
-- 新版宣告配方
function StatusAnnouncer:newAnnounceRecipe(recipe_name, ingredients)
    local S, builder, buffered, knows, can_build, name, a, prototyper =
        StatusAnnouncer:Breathy(recipe_name or ingredients.recipe.name)

    local a_proto = ""
    local proto = ""

    local ingre = ingredients
    if ingre and ingre.focus then
        -- 配方表，共需要多少-- type、amount
        local turerecipe = ingredients.recipe
        local its1 = turerecipe and turerecipe.ingredients or {}
        local its2 = turerecipe and turerecipe.character_ingredients or {}

        local announce_str = "";
        local flag = true -- 不差材料
        local min = 9999999 -- 能制作多少个

        -- 每项材料的名字、能做多少个、还差多少个, "个", prefab
        local thetable = {}
        local ing_s = S.S

        for _, it in pairs(its1) do
            local ingname = it.type
            local ingtooltip = STRINGS.NAMES[string.upper(it.type)]
            local amount_needed = it.amount
            local has, num_found = ThePlayer.replica.inventory:Has(ingname, RoundBiasedUp(
                amount_needed * ThePlayer.replica.builder:IngredientMod()))
            local num = amount_needed - num_found
            local can_make = math.floor(num_found / amount_needed) * turerecipe.numtogive
            local ingredient_str = (ingtooltip or "<missing_string>"):lower()
            if ingredient_str:find(ing_s .. "$") ~= nil then
                ing_s = ""
            end
            if num > 0 then
                flag = false
            end
            table.insert(thetable, {ingredient_str, can_make, num, ing_s, ingname})
        end

        for _, it in pairs(its2) do
            local ingname = it.type
            local ingtooltip = STRINGS.NAMES[string.upper(it.type)]
            local amount_needed = it.amount
            local has, num_found = ThePlayer.replica.builder:HasCharacterIngredient(it)
            local num = amount_needed - num_found
            local can_make = math.floor(num_found / amount_needed) * turerecipe.numtogive
            local ingredient_str = (ingtooltip or "<missing_string>"):lower()
            ing_s = ""
            if num > 0 then
                flag = false
            end
            table.insert(thetable, {ingredient_str, can_make, num, ing_s, ingname})
        end

        -- 不差材料
        if flag then
            -- local str = ""
            for _, v in pairs(thetable) do
                if v[2] < min then
                    min = v[2]
                end
                --     str = str..v[1]..","
            end
            -- str = string.sub(str, 1, -2)
            local but_need = ""
            if prototyper ~= "" and SHOWPROTOTYPER then
                but_need = S.ANNOUNCE_INGREDIENTS.BUT_NEED
                a_proto = S.getArticle(prototyper) .. " "
                proto = prototyper
            end
            local a_rec = ""
            local rec_s = ""
            if min > 1 then
                a_rec = min .. " "
                rec_s = S.S
                if string.find(name, rec_s .. "$") ~= nil then -- already plural
                    rec_s = ""
                end
            else
                a_rec = S.getArticle(name)
            end
            -- print("宣告测试", but_need)
            announce_str = subfmt(S.ANNOUNCE_INGREDIENTS.FORMAT_HAVE, {
                INGREDIENT = "材料", -- 暂时先不换str
                ING_S = ing_s,
                A_REC = a_rec,
                RECIPE = Cemoji(name),
                REC_S = rec_s,
                BUT_NEED = but_need,
                A_PROTO = a_proto,
                PROTOTYPER = Cemoji(proto)
            })
        else
            -- 差材料
            local cstr = ""
            for _, v in pairs(thetable) do
                if v and v[3] > 0 then
                    cstr = cstr .. v[3] .. ing_s .. Cemoji(v[1]) .. ","
                end
            end
            cstr = string.sub(cstr, 1, -2)

            local and_str = ""
            -- 如果还差科技
            if not knows and prototyper ~= "" and SHOWPROTOTYPER then
                and_str = S.ANNOUNCE_INGREDIENTS.AND
                a_proto = S.getArticle(prototyper) .. " "
                proto = prototyper
            end
            announce_str = subfmt(S.ANNOUNCE_INGREDIENTS.FORMAT_NEED, {
                NUM_ING = "",
                S = "",
                INGREDIENT = cstr,
                AND = and_str,
                A_PROTO = a_proto,
                PROTOTYPER = Cemoji(proto),
                A_REC = S.getArticle(name),
                RECIPE = Cemoji(name)
            })
        end
        return self:Announce(announce_str)

    else
        local start_q = ""
        local to_do = ""
        local s = ""
        local pre_built = ""
        local end_q = ""
        local i_need = ""
        local for_it = ""
        if buffered then
            -- 我做好了一个XX准备放置
            to_do = S.ANNOUNCE_RECIPE.I_HAVE
            pre_built = S.ANNOUNCE_RECIPE.PRE_BUILT
        elseif can_build and knows then
            -- 我可以帮你制作一个XX
            to_do = S.ANNOUNCE_RECIPE.ILL_MAKE
        elseif knows then
            -- 我需要制作一个XX
            to_do = S.ANNOUNCE_RECIPE.WE_NEED
            a = ""
            s = string.find(name, S.S .. "$") == nil and S.S or ""
        else
            -- 有人可以帮我做一个XX吗，我还差一个科技才能制造它
            to_do = S.ANNOUNCE_RECIPE.CAN_SOMEONE
            if prototyper ~= "" and SHOWPROTOTYPER then
                i_need = S.ANNOUNCE_RECIPE.I_NEED
                a_proto = S.getArticle(prototyper) .. " "
                proto = prototyper
                for_it = S.ANNOUNCE_RECIPE.FOR_IT
            end
            start_q = S.ANNOUNCE_RECIPE.START_Q
            end_q = S.ANNOUNCE_RECIPE.END_Q
        end
        local announce_str = subfmt(S.ANNOUNCE_RECIPE.FORMAT_STRING, {
            START_Q = start_q,
            TO_DO = to_do,
            THIS_MANY = a,
            ITEM = Cemoji(name),
            S = s,
            PRE_BUILT = pre_built,
            END_Q = end_q,
            I_NEED = i_need,
            A_PROTO = a_proto,
            PROTOTYPER = Cemoji(proto),
            FOR_IT = for_it
        })
        return self:Announce(announce_str)
    end
end

-- 新版宣告制作面儿
function StatusAnnouncer:newAnnounceDetail(droot)

    local skin = droot.skins_spinner
    if skin and skin.enabled and skin.shown and skin.focus then
        local skin_name = skin:GetItem()
        local item_name = STRINGS.NAMES[string.upper(skin.recipe.product)] or skin.recipe.name
        if skin_name and skin_name ~= item_name then -- don't announce default skins
            return self:Announce(subfmt(GetTrue_().ANNOUNCE_SKIN.FORMAT_STRING, {
                SKIN = GetSkinName(skin_name),
                ITEM = Cemoji(item_name)
            }))
        else
            if item_name then
                -- 没皮肤的只能沦为打工仔
                return self:Announce(subfmt(GetTrue_().ANNOUNCE_SKIN.NO_SKIN, {
                    ITEM = Cemoji(item_name)
                }))
            end
        end
    end

    local ingredients = droot.ingredients
    if ingredients and ingredients.enabled and ingredients.focus and ingredients.recipe then
        return self:newAnnounceRecipe(ingredients.recipe.name, ingredients)
    end

    local buildbtn = droot.build_button_root
    if buildbtn and buildbtn.focus then
        local name = ingredients and ingredients.recipe and ingredients.recipe.name and
                         STRINGS.NAMES[ingredients.recipe.name:upper()] or "蘑菇慕斯"
        if name then
            return self:Announce(subfmt(GetTrue_().ANNOUNCE_SKIN.NO_PROBLEM, {
                ITEM = Cemoji(name)
            }))
        end
    end

end

-- 新版宣告制作条儿
function StatusAnnouncer:newAnnouncePinbar(pinbar)
    local pin_open = pinbar.pin_open
    local pin_slots = pinbar.pin_slots
    if pin_open and pin_open.focus then
        return self:Announce(GetTrue_().ANNONCE_pin_open)
    elseif pin_slots then
        for _, pin_slot in ipairs(pin_slots) do
            if pin_slot and pin_slot.focus and pin_slot.recipe_name and pin_slot.recipe_popup and
                pin_slot.recipe_popup.ingredients then
                return self:newAnnounceRecipe(pin_slot.recipe_name, pin_slot.recipe_popup.ingredients)
            end
        end
    end
end

-- 新版宣告制作版儿
function StatusAnnouncer:newAnnounceGrid(grid)
    local index = grid.focused_widget_index +  grid.displayed_start_index
    local items = grid.items
    if index and items then
        if not items[index] then return end
        local recipe = items[index].recipe
        -- local meta = items[index].meta
        if recipe -- and meta
        then
            local S, builder, buffered, knows, can_build, name, a, prototyper = StatusAnnouncer:Breathy(recipe.name)
            -- can_build = meta.can_build
            local start_q = ""
            local to_do = ""
            local s = ""
            local pre_built = ""
            local end_q = ""
            local i_need = ""
            local for_it = ""
            local a_proto = ""
            local proto = ""
            if buffered then
                to_do = S.ANNOUNCE_RECIPE.I_HAVE
                pre_built = S.ANNOUNCE_RECIPE.PRE_BUILT
            elseif can_build and knows then
                to_do = S.ANNOUNCE_RECIPE.ILL_MAKE
            elseif knows then
                to_do = S.ANNOUNCE_RECIPE.WE_NEED
                a = ""
                s = string.find(name, S.S .. "$") == nil and S.S or ""
            else
                to_do = S.ANNOUNCE_RECIPE.CAN_SOMEONE
                if prototyper ~= "" and SHOWPROTOTYPER then
                    i_need = S.ANNOUNCE_RECIPE.I_NEED
                    a_proto = S.getArticle(prototyper) .. " "
                    proto = prototyper
                    for_it = S.ANNOUNCE_RECIPE.FOR_IT
                end
                start_q = S.ANNOUNCE_RECIPE.START_Q
                end_q = S.ANNOUNCE_RECIPE.END_Q
            end
            local announce_str = subfmt(S.ANNOUNCE_RECIPE.FORMAT_STRING, {
                START_Q = start_q,
                TO_DO = to_do,
                THIS_MANY = a,
                ITEM = Cemoji(name),
                S = s,
                PRE_BUILT = pre_built,
                END_Q = end_q,
                I_NEED = i_need,
                A_PROTO = a_proto,
                PROTOTYPER = Cemoji(proto),
                FOR_IT = for_it
            })
            return self:Announce(announce_str)
        end
    end
end

-- 同屏宣告
function StatusAnnouncer:AnnounceCount(count, name, prefab)
    if type(name) ~= "string" or type(prefab) ~= "string" then
        return
    end
    local theName = STRINGS.NAMES[prefab:upper()]
    if not theName then
        theName = name or "<未知实体>"
    end

    local announce_str = "呼吸 · 同屏宣告"
    if count < 2 then -- 有可能等于0或1哦,你猜猜是什么原因
        announce_str = subfmt(GetTrue_().ANNONCE_COUNT.ONE, {
            NAME = Cemoji(theName)
        })
    else
        announce_str = subfmt(GetTrue_().ANNONCE_COUNT.MORE, {
            COUNT = count,
            NAME = Cemoji(theName)
        })
    end
    return self:Announce(announce_str)
end

-- 打个招呼吧，朋友！
function StatusAnnouncer:AnnouncePeople(he)
    local S = GetTrue_()
    local sayHi = boki and S.ANNOUNCE_SUBFMT[string.upper(boki)].sayhi or S.ANNOUNCE_SAYHI

    local message = sayHi.greeting

    if he:HasTag("playerghost") then
        message = sayHi.ghost_he
    end                                                -- 如果她死了
    if ThePlayer:HasTag("playerghost") then
        message = sayHi.ghost_me
    end                                         -- 如果我死了
    if he:HasTag("playerghost") and ThePlayer:HasTag("playerghost") then
        message = sayHi.ghost_we
    end            -- 如果我们都死了

    return self:Announce(subfmt(message[math.random(#message)], {
        NAME = he.name
    }))
end

-- 宣告个人温度
function StatusAnnouncer:AnnounceTemperature(pronoun)
    local S = GetTrue_().ANNOUNCE_TEMPERATURE -- To save some table lookups
    local temp = ThePlayer:GetTemperature()
    local pronoun = pronoun and S.PRONOUN[pronoun] or S.PRONOUN.DEFAULT
    local message = S.TEMPERATURE.GOOD
    local TUNING = TUNING
    if temp >= TUNING.OVERHEAT_TEMP then
        message = S.TEMPERATURE.BURNING
    elseif temp >= TUNING.OVERHEAT_TEMP - 5 then
        message = S.TEMPERATURE.HOT
    elseif temp >= TUNING.OVERHEAT_TEMP - 15 then
        message = S.TEMPERATURE.WARM
    elseif temp <= 0 then
        message = S.TEMPERATURE.FREEZING
    elseif temp <= 5 then
        message = S.TEMPERATURE.COLD
    elseif temp <= 15 then
        message = S.TEMPERATURE.COOL
    end
    message = subfmt(S.FORMAT_STRING, {
        PRONOUN = pronoun,
        TEMPERATURE = message
    })

    if TUNING.UNIT == "C" then
        temp = math.floor(temp/2 + 0.5)
    elseif TUNING.UNIT == "F" then
        temp = math.floor(0.9*(temp) + 32.5)
    end
    local UNIT_STRING = ""
    if TUNING.UNIT ~= "T" then UNIT_STRING = TUNING.UNIT end

    if EXPLICIT then
        return self:Announce(string.format("(%d°"..UNIT_STRING..") %s", temp, message))
    else
        return self:Announce(message)
    end
end
-- 降雨预测
local function PredictRainStart()
    -- 资料来源：https://www.bilibili.com/video/BV1DE411E7Qi

    -- 一场雨什么时候下由上限决定、什么时候停由下限决定
    -- 冬天第二天上涨速率速率是50
    -- 水分 = 水分速率下限 + (水分速率上限 - 水分速率下限) * {1 - Sin[Π * (当前季节剩余天数, 包括当天) / 当前季节总天数]}

    -- 水分速率上下限
    local MOISTURE_RATES = {
        MIN = {
            autumn = .25,
            winter = .25,
            spring = 3,
            summer = .1
        },
        MAX = {
            autumn = 1.0,
            winter = 1.0,
            spring = 3.75,
            summer = .5
        }
    }
    local world = TheWorld.net.components.weather ~= nil and "Surface" or "Caves"
    local remainingsecondsinday = TUNING.TOTAL_DAY_TIME - (TheWorld.state.time * TUNING.TOTAL_DAY_TIME)
    local totalseconds = 0
    local rain = false

    local season = TheWorld.state.season
    local seasonprogress = TheWorld.state.seasonprogress
    local elapseddaysinseason = TheWorld.state.elapseddaysinseason
    local remainingdaysinseason = TheWorld.state.remainingdaysinseason
    local totaldaysinseason = remainingdaysinseason / (1 - seasonprogress)
    local _totaldaysinseason = elapseddaysinseason + remainingdaysinseason

    local moisture = TheWorld.state.moisture
    local moistureceil = TheWorld.state.moistureceil

    while elapseddaysinseason < _totaldaysinseason do
        local moisturerate

        if world == "Surface" and season == "winter" and elapseddaysinseason == 2 then
            moisturerate = 50
        else
            local p = 1 - math.sin(PI * seasonprogress)
            moisturerate = MOISTURE_RATES.MIN[season] + p * (MOISTURE_RATES.MAX[season] - MOISTURE_RATES.MIN[season])
        end

        local _moisture = moisture + (moisturerate * remainingsecondsinday)

        if _moisture >= moistureceil then
            totalseconds = totalseconds + ((moistureceil - moisture) / moisturerate)
            rain = true
            break
        else
            moisture = _moisture
            totalseconds = totalseconds + remainingsecondsinday
            remainingsecondsinday = TUNING.TOTAL_DAY_TIME
            elapseddaysinseason = elapseddaysinseason + 1
            remainingdaysinseason = remainingdaysinseason - 1
            seasonprogress = 1 - (remainingdaysinseason / totaldaysinseason)
        end
    end
    if world == "Surface" then
        world = "地表"
    elseif world == "Caves" then
        world = "洞穴"
    end
    return world, totalseconds, rain
end
-- 停雨预测
local function PredictRainStop()
    local PRECIP_RATE_SCALE = 10
    local MIN_PRECIP_RATE = .1

    local world = TheWorld.net.components.weather ~= nil and "Surface" or "Caves"
    local dbgstr = (TheWorld.net.components.weather ~= nil and TheWorld.net.components.weather:GetDebugString()) or
                       TheWorld.net.components.caveweather:GetDebugString()
    local _, _, moisture, moisturefloor, moistureceil, moisturerate, preciprate, peakprecipitationrate = string.find(
        dbgstr, ".*moisture:(%d+.%d+)%((%d+.%d+)/(%d+.%d+)%) %+ (%d+.%d+), preciprate:%((%d+.%d+) of (%d+.%d+)%).*")

    moisture = tonumber(moisture)
    moistureceil = tonumber(moistureceil)
    moisturefloor = tonumber(moisturefloor)
    preciprate = tonumber(preciprate)
    peakprecipitationrate = tonumber(peakprecipitationrate)

    local totalseconds = 0

    while moisture > moisturefloor do
        if preciprate > 0 then
            local p = math.max(0, math.min(1, (moisture - moisturefloor) / (moistureceil - moisturefloor)))
            local rate = MIN_PRECIP_RATE + (1 - MIN_PRECIP_RATE) * math.sin(p * PI)

            preciprate = math.min(rate, peakprecipitationrate)
            moisture = math.max(moisture - preciprate * FRAMES * PRECIP_RATE_SCALE, 0)

            totalseconds = totalseconds + FRAMES
        else
            break
        end
    end

    if world == "Surface" then
        world = "地表"
    elseif world == "Caves" then
        world = "洞穴"
    end

    return world, totalseconds
end
-- 宣告世界温度【做了修改，可以宣告降雨】
function StatusAnnouncer:AnnounceWorldtemp(pronoun)
    local S = GetTrue_().ANNOUNCE_WORLDTEMP or nil -- 以保存一些表查找
    if S then
        local temp = TheWorld.state.temperature
        local message = ""
        local tshow = "降雨"
        local tseason = TheWorld.state.season
        if tseason == "spring" then
            tseason = "春天"
            tshow = "绵绵春雨"
        elseif tseason == "summer" then
            tseason = "夏天"
            tshow = "狂风暴雨"
        elseif tseason == "autumn" then
            tseason = "秋天"
            tshow = "蒙蒙细雨"
        elseif tseason == "winter" then
            tseason = "冬天"
            tshow = "纷纷白雪"
        end

        if TheWorld.state.pop ~= 1 then
            local world, totalseconds, rain = PredictRainStart()
            if world == "洞穴" then
                tshow = "强降雨"
            end

            if rain then
                local d = TheWorld.state.cycles + 1 + TheWorld.state.time + (totalseconds / TUNING.TOTAL_DAY_TIME)
                local m = math.floor(totalseconds / 60)
                local s = totalseconds % 60

                message = string.format("%s将会在第%.2f天迎来一场%s(%d分%d秒)", world, d, tshow, m, s)
            else
                message = string.format("%s的这个%s不会再有%s啦", world, tseason, tshow)
            end
        else
            local world, totalseconds = PredictRainStop()
            if world == "洞穴" then
                tshow = "强降雨"
            end

            local d = TheWorld.state.cycles + 1 + TheWorld.state.time + (totalseconds / TUNING.TOTAL_DAY_TIME)
            local m = math.floor(totalseconds / 60)
            local s = totalseconds % 60

            message = string.format("%s的%s会在第%.2f天时停止(%d分%d秒)", world, tshow, d, m, s)
        end
        
        if TUNING.UNIT == "C" then
            temp = math.floor(temp/2 + 0.5)
        elseif TUNING.UNIT == "F" then
            temp = math.floor(0.9*(temp) + 32.5)
        end
        local UNIT_STRING = ""
        if TUNING.UNIT ~= "T" then UNIT_STRING = TUNING.UNIT end
        if EXPLICIT then
            return self:Announce(string.format("(世界气温:%d°"..UNIT_STRING..") %s", temp, message))
        else
            return self:Announce(message)
        end
    end
end

-- 宣告月圆 --失败了 请求支援--Shang

-- 支援失败 哈哈，呼吸留--
-- 支援...成功，Bazinga！
function StatusAnnouncer:AnnounceMoonAnim(moonment)
    -- {今晚或明晚}{月相}{，}距离{反月相}还有{XX}天。
    -- {我们刚刚度过}{月相}{，}距离{月相}还有{XX}天。
    -- 距离{月相}还有{XX}天。
    local worldment = TheWorld.state.cycles + 1 or 0
    if worldment == 0 then return end
    local MS = GetTrue_().ANNOUNCE_MOON
    local recent,phase1,phase2,a_str= "","","",""
    local moonleft = moonment-worldment

    if moonleft>=10 then
        phase1 = MS.FULLMOON
        phase2 = MS.NEWMOON
    else
        phase1 = MS.NEWMOON
        phase2 = MS.FULLMOON
    end
    local interval = MS.INTERVAL
    local judge = moonleft%10
    if judge <= 1 then
        if judge == 0 then
            recent = MS.TODAY
        else
            recent = MS.TOMORROW
        end
        judge = judge + 10
        phase1,phase2 = phase2,phase1
        if worldment < 20 then
            -- 我得整点花活儿，不然心里窝囊
            if phase1 == MS.FULLMOON then
                return self:Announce(subfmt(MS.FORMAT_FULLMOON, {
                    RECENT = recent,
                    PHASE1 = phase1,
                    INTERVAL = interval,
                }))
            else
                return self:Announce(subfmt(MS.FORMAT_NEWMOON, {
                    RECENT = recent,
                    PHASE1 = phase1,
                    INTERVAL = interval,
                }))
            end
        end
    elseif judge >= 8 then
        recent = MS.AFTER
    else
        recent = ""
        phase1 = ""
        interval= ""
    end
    return self:Announce(subfmt(MS.FORMAT_STRING, {
        RECENT = recent,
        PHASE1 = phase1,
        INTERVAL = interval,
        PHASE2 = phase2,
        MOONLEFT = judge,
    }))
end
-- 宣告季节
function StatusAnnouncer:AnnounceSeason()
    return self:Announce(subfmt(GetTrue_().ANNOUNCE_SEASON, {
        DAYS_LEFT = TheWorld.state.remainingdaysinseason,
        SEASON = STRINGS.UI.SERVERLISTINGSCREEN.SEASONS[TheWorld.state.season:upper()]
    }))
end
-- 宣告延迟
function StatusAnnouncer:AnnouncePing()
    local pingN = TheNet:GetAveragePing()
    local PS = GetTrue_().ANNOUNCE_PING
    local announce_str = ""
    if pingN <= 5 then
        return self:Announce(PS.BEST)
    elseif pingN <= 30 then
        announce_str = PS.A
    elseif pingN <= 80 then
        announce_str = PS.B
    elseif pingN <= 500 then
        announce_str = PS.C
    else
        announce_str = PS.D
    end
    if (IsSteam() or not TheWorld.ismastersim) and TheInventory:CheckOwnership("emoji_web") then
        announce_str = ":web:"..announce_str
    end
    return self:Announce(subfmt(announce_str, {
        PING = pingN,
    }))
end

-- 状态注册器
-- 1、name：饥饿、理智、潮湿自定义
-- 2、widget：HUD.controls.status.XX HUD得自己填
-- 3、controller_btn：控制器支持（fuck，没有手柄）
-- 4、thresholds：分段，数值、得递增排序
-- 5、category_names：分段，字符串、得和上个参数匹配
-- 6、value_fn：响应函数：返回（当前数值，最大数值）
-- 7、switch_fn：人物可以变身时用的函数，不用管
function StatusAnnouncer:RegisterStat(name, widget, controller_btn, thresholds, category_names, value_fn, switch_fn)
    self.button_to_stat[controller_btn] = name
    self.stats[name] = {
        -- The widget that should be focused when announcing this stat
        widget = widget,
        -- The button on the controller that announces this stat
        controller_btn = controller_btn,
        -- the numerical thresholds at which messages change (must be sorted in increasing order!)
        thresholds = thresholds,
        -- the names of the buckets between the thresholds, for looking up strings
        category_names = category_names,
        -- value_fn(ThePlayer) returns the current and maximum of the stat
        value_fn = value_fn,
        -- switch_fn(ThePlayer) returns the mode (e.g. HUMAN for Woodie vs WEREBEAVER for Werebeaver)
        -- if this is nil, it assumes there's just one table (look at Woodie's table in announcestrings vs the others)
        switch_fn = switch_fn
    }
end

-- The other arguments are here so that mods can use them to override this function
-- and avoid some of these stats if their character doesn't have them
-- 总状态注册器
function StatusAnnouncer:RegisterCommonStats(HUD, prefab, hunger, sanity, health, moisture, wereness)
    local stat_categorynames = {"EMPTY", "LOW", "MID", "HIGH", "FULL"}
    local default_thresholds = {.15, .35, .55, .75}

    local status = HUD.controls.status
    local has_weremode = type(status.wereness) == "table"
    local switch_fn = has_weremode and function(ThePlayer)
        return ThePlayer.weremode:value() ~= 0 and "WEREBEAVER" or "HUMAN"
    end or nil

    -- 船
    if type(status.boatmeter) == "table" then
        self:RegisterStat("Boat", status.boatmeter, CONTROL_INVENTORY_USEONSCENE, -- D-Pad Left
        default_thresholds, stat_categorynames, function()
            return string.match(tostring(status.boatmeter.num), "(%d+)") or 0,
                string.match(tostring(status.boatmeter.maxnum), "(%d+)") or 200
        end, switch_fn)
    end

    if hunger ~= false and type(status.stomach) == "table" then
        self:RegisterStat("Hunger", status.stomach, CONTROL_INVENTORY_USEONSCENE, -- D-Pad Left
        default_thresholds, stat_categorynames, function(ThePlayer)
            return ThePlayer.player_classified.currenthunger:value(), ThePlayer.player_classified.maxhunger:value()
        end, switch_fn)
    end
    if sanity ~= false and type(status.brain) == "table" then
        self:RegisterStat("Sanity", status.brain, CONTROL_INVENTORY_EXAMINE, -- D-Pad Up
        default_thresholds, stat_categorynames, function(ThePlayer)
            return ThePlayer.player_classified.currentsanity:value(), ThePlayer.player_classified.maxsanity:value()
        end, switch_fn)
    end
    if health ~= false and type(status.heart) == "table" then
        self:RegisterStat("Health", status.heart, CONTROL_INVENTORY_USEONSELF, -- D-Pad Right
        {.25, .5, .75, 1}, stat_categorynames, function(ThePlayer)
            if prefab == "wanda" and wandahealthy then
                return ThePlayer.player_classified.currenthealth:value() / TUNING.OLDAGE_HEALTH_SCALE, ThePlayer.player_classified.maxhealth:value() / TUNING.OLDAGE_HEALTH_SCALE
            end
            return ThePlayer.player_classified.currenthealth:value(), ThePlayer.player_classified.maxhealth:value()
        end, switch_fn)
    end
    if wereness ~= false and has_weremode then
        self:RegisterStat("Log Meter", status.wereness, CONTROL_ROTATE_LEFT, -- Left Bumper
        {.25, .5, .7, .9}, stat_categorynames, function(ThePlayer)
            return ThePlayer.player_classified.currentwereness:value(), 100 -- looks like the only way is to hardcode this; not networked
        end, switch_fn)
    end
    if moisture ~= false and type(status.moisturemeter) == "table" then
        self:RegisterStat("Wetness", status.moisturemeter, CONTROL_ROTATE_RIGHT, -- Right Bumper
        default_thresholds, stat_categorynames, function(ThePlayer)
            return ThePlayer.player_classified.moisture:value(), ThePlayer.player_classified.maxmoisture:value()
        end, switch_fn)
    end

    -- 为温蒂增加宣告阿比盖尔
    if prefab == "wendy" and type(status.pethealthbadge) == "table" and ThePlayer.components.pethealthbar then
        self:RegisterStat("Abigail", status.pethealthbadge, CONTROL_ROTATE_RIGHT, -- D-Pad Up
        default_thresholds, stat_categorynames, function(ThePlayer)
            local ph = ThePlayer.components.pethealthbar
            local maxHP = ph._maxhealth:value()
            local curHP = math.ceil((ph._healthpct:value()) * maxHP)
            return curHP, maxHP
        end, switch_fn)
    end

    -- 为大力士增加宣告健身值
    if prefab == "wolfgang" and type(status.mightybadge) == "table" then
        self:RegisterStat("Flex", status.mightybadge, CONTROL_ROTATE_RIGHT, -- D-Pad Up
        default_thresholds, stat_categorynames, function(ThePlayer)
            return ThePlayer.player_classified.currentmightiness:value(), TUNING.MIGHTINESS_MAX
        end, switch_fn)
    end

    -- 为女武神增加宣告战斗值
    if prefab == "wathgrithr" and type(status.inspirationbadge) == "table" then
        self:RegisterStat("Battle", status.inspirationbadge, CONTROL_ROTATE_RIGHT, -- D-Pad Up
        default_thresholds, stat_categorynames, function(ThePlayer)
            return ThePlayer.player_classified.currentinspiration:value(), TUNING.INSPIRATION_MAX
        end, switch_fn)
    end

    -- 为MUSHA增加宣告魔力值
    if prefab == "musha" and type(status.spellpower) == "table" then
        self:RegisterStat("Spellpower", status.spellpower, CONTROL_ROTATE_RIGHT, -- D-Pad Up
        default_thresholds, stat_categorynames, function()
            return string.match(tostring(status.spellpower.num), "(%d+)") or 0,
                string.match(tostring(status.spellpower.maxnum), "(%d+)") or 100
        end, switch_fn)
    end

    -- 为MUSHA增加宣告耐力值
    if prefab == "musha" and type(status.stamina_sleep) == "table" then
        self:RegisterStat("Stamina", status.stamina_sleep, CONTROL_ROTATE_RIGHT, -- D-Pad Up
        default_thresholds, stat_categorynames, function()
            return string.match(tostring(status.stamina_sleep.num), "(%d+)") or 0,
                string.match(tostring(status.stamina_sleep.maxnum), "(%d+)") or 100
        end, switch_fn)
    end

    -- 为WX-78增加宣告电量值
    if prefab == "wx78" and HUD.controls.secondary_status and HUD.controls.secondary_status.upgrademodulesdisplay then
        self:RegisterStat("Electric", HUD.controls.secondary_status.upgrademodulesdisplay, CONTROL_ROTATE_RIGHT, -- D-Pad Up
        default_thresholds, stat_categorynames, function()
            return HUD.controls.secondary_status.upgrademodulesdisplay.energy_level or 0,TUNING.WX78_MAXELECTRICCHARGE or 6
        end, switch_fn)
    end
end

local function has_seasons(HUD, ignore_focus)
    return
        HUD.controls.seasonclock and (ignore_focus or HUD.controls.seasonclock.focus) or HUD.controls.status.season and
            (ignore_focus or HUD.controls.status.season.focus)
end
local function has_moonanim(HUD)
    return HUD.controls.clock and HUD.controls.clock._moonanim and HUD.controls.clock._moonanim.focus and
               HUD.controls.clock._moonanim.moontext
end

-- 鼠标响应
-- 不用管，除非自定义个新的和人物无关的单独的HUD
function StatusAnnouncer:OnHUDMouseButton(HUD)
    for stat_name, data in pairs(self.stats) do
        if data.widget.focus then
            return self:Announce(self:ChooseStatMessage(stat_name))
        end
    end
    if HUD.controls.status.temperature and HUD.controls.status.temperature.focus then
        return self:AnnounceTemperature(HUD.controls.status._weremode and "BEAST" or nil)
    end
    if has_seasons(HUD, false) then
        return self:AnnounceSeason()
    end
    if has_moonanim(HUD) then
        -- moon moment -> 月圆时刻 -> moonment
        local moonment = string.match(tostring(HUD.controls.clock._moonanim.moontext), "(%d+)") or 0
        if moonment ~= 0 then
            return self:AnnounceMoonAnim(moonment)
        end
    end
    -- 添加宣告世界温度_鼠标 shang
    if HUD.controls.status.worldtemp and HUD.controls.status.worldtemp.focus then
        return self:AnnounceWorldtemp(HUD.controls.status._weremode and "BEAST" or nil)
    end
    -- Ping
    if HUD.controls.clock and HUD.controls.clock.focus then
        return self:AnnouncePing()
    end
end

local function get_category(thresholds, percent)
    local i = 1
    while thresholds[i] ~= nil and percent >= thresholds[i] do
        i = i + 1
    end
    return i
end

-- 选状态文本
-- （生命：数值/最大值 信息）
function StatusAnnouncer:ChooseStatMessage(stat)
    local cur, max = self.stats[stat].value_fn(ThePlayer)
    local percent = cur / max
    local messages = self.stats[stat].switch_fn and self.char_messages[self.stats[stat].switch_fn(ThePlayer)] or self.char_messages
    local category = get_category(self.stats[stat].thresholds, percent)
    local category_name = self.stats[stat].category_names[category]

    if not messages[stat:upper()] then
        messages = self.stats[stat].switch_fn and STRINGS._STATUS_ANNOUNCEMENTS.UNKNOWN[self.stats[stat].switch_fn(ThePlayer)] or STRINGS._STATUS_ANNOUNCEMENTS.UNKNOWN
    end

    if not messages or not messages[stat:upper()] then
        return "<你好, 出现这条信息意味着出现了一个BUG, 请联系hanhuxi@qq.com修复此bug 或者 订阅原版快捷宣告>"
    end
    local message = messages[stat:upper()][category_name]
    if EXPLICIT then
        return string.format("(%s: %d/%d) %s", self.stat_names[stat] or stat, cur, max, message)
    else
        return message
    end
end

-- 刷新冷却
function StatusAnnouncer:ClearCooldowns()
    self.cooldown = false
    self.cooldowns = {}
end

-- 刷新状态
function StatusAnnouncer:ClearStats()
    self.stats = {}
    self.button_to_stat = {}
end
-- 选择角色时加载
function StatusAnnouncer:SetCharacter(prefab)
    self:ClearCooldowns()
    self:ClearStats()
    -- 选择角色设置文本
    self.char_messages = STRINGS._STATUS_ANNOUNCEMENTS[prefab:upper()] or STRINGS._STATUS_ANNOUNCEMENTS.UNKNOWN
    self.stat_names = {}
    for stat, name in pairs(STRINGS._STATUS_ANNOUNCEMENTS._.STAT_NAMES) do
        self.stat_names[stat] = name
    end
    if SHOWEMOJI then
        for stat, emoji in pairs(STRINGS._STATUS_ANNOUNCEMENTS._.STAT_EMOJI) do
            if (IsSteam() or not TheWorld.ismastersim) and TheInventory:CheckOwnership("emoji_" .. emoji) then
                self.stat_names[stat] = ":" .. emoji
            end
        end
    end
end

function StatusAnnouncer:SetLocalParameter(parameter, value)
    if setters[parameter] then
        setters[parameter](value)
    end
end

return StatusAnnouncer
