local containers = require("containers")

local storable = {
	["pocketwatch_dismantler"] = true,
	["pocketwatch_parts"] = true,
	["nightmarefuel"] = true,
	["thulecite_pieces"] = true,
	["thulecite"] = true,
	["redgem"] = true,
	["bluegem"] = true,
	["purplegem"] = true,
	["orangegem"] = true,
	["yellowgem"] = true,
	["greengem"] = true,
	["opalpreciousgem"] = true,
	["livinglog"] = true,
	["orangestaff"] = true,
	["yellowstaff"] = true,
	["greenstaff"] = true,
	["icestaff"] = true,
	["firestaff"] = true,
	["telestaff"] = true,
	["opalstaff"] = true,
	["reskin_tool"] = true,
	["redmooneye"] = true,
	["orangemooneye"] = true,
	["yellowmooneye"] = true,
	["greenmooneye"] = true,
	["bluemooneye"] = true,
	["purplemooneye"] = true,
	["moonrockcrater"] = true,
	["amulet"] = true,
	["orangeamulet"] = true,
	["yellowamulet"] = true,
	["greenamulet"] = true,
	["blueamulet"] = true,
	["purpleamulet"] = true,
	["panflute"] = true,
	["nightmare_timepiece"] = true,
	["multitool_axe_pickaxe"] = true,
	["nutrientsgoggleshat"] = true,
	["ruinshat"] = true,
	["armorruins"] = true,
	["ruins_bat"] = true,
	["beardhair"] = true,
	["slurper_pelt"] = true,
	["minotaurhorn"] = true,
	["walrus_tusk"] = true,
	["twigs"] = true,
	["flint"] = true,
	["goldnugget"] = true,
	["boneshard"] = true,
	["marble"] = true,
	["nightsword"] = true,
	["armor_sanity"] = true,
	["steelwool"] = true,
	["furtuft"] = true,
	["bearger_fur"] = true,
	["petals_evil"] = true,
	["boards"] = true,
	["cutstone"] = true,
	["compass"] = true,
	["deerclops_eyeball"] = true,
	["moonglass"] = true,
	["moonrocknugget"] = true,
	["townportaltalisman"] = true,
	["batwing"] = true,
	["batwing_cooked"] = true,
	["rope"] = true,
	["mandrake"] = true,
	["papyrus"] = true,
	["cutreeds"] = true,
	["pigskin"] = true,
	["spear"] = true,
	["skeletonhat"] = true,
	["armorskeleton"] = true,
	["thurible"] = true,
	["fossil_piece"] = true,
	["shadowheart"] = true,
	["rocks"] = true,
	["cutgrass"] = true,
	["log"] = true,
	["ice"] = true,
	["cave_banana"] = true,
	["cave_banana_cooked"] = true,
	["wormlight_lesser"] = true,
	["cutlichen"] = true,
	["cookedmonstermeat"] = true,
	["monstermeat_dried"] = true,
	["lightbulb"] = true,
	["wormlight"] = true,
	["monstermeat"] = true,
	["gears"] = true,
	["dug_trap_starfish"] = true,
	["trinket_1"] = true,
	["trinket_6"] = true,
	["gift"] = true,
	["giftwrap"] = true,
	["bundle"] = true,
	["bundlewrap"] = true,
	["eyemaskhat"] = true,
	["waxpaper"] = true,
	["petals"] = true,
	["batbat"] = true,
	["armorslurper"] = true,
	["axe"] = true,
	["pickaxe"] = true,
	["shovel"] = true,
	["hammer"] = true,
	["farm_hoe"] = true,
	["pitchfork"] = true,
	["goldenaxe"] = true,
	["goldenpickaxe"] = true,
	["goldenshovel"] = true,
	["golden_farm_hoe"] = true,
	["trap"] = true,
	["birdtrap"] = true,
	["bugnet"] = true,
	["razor"] = true,
	["wateringcan"] = true,
	["premiumwateringcan"] = true,
	["fishingrod"] = true,
	["oceanfishingrod"] = true,
	["sewing_kit"] = true,
	["sewing_tape"] = true,
	["silk"] = true,
	["houndstooth"] = true,
	["cane"] = true,
	["eyebrellahat"] = true,
	["walrushat"] = true,
	["beefalohat"] = true,
	["deserthat"] = true,
	["beehat"] = true,
	["wathgrithrhat"] = true,
	["footballhat"] = true,
	["minerhat"] = true,
	["hivehat"] = true,
	["alterguardianhat"] = true,
	["armorwood"] = true,
	["armormarble"] = true,
	["armor_bramble"] = true,
	["armordragonfly"] = true,
	["monkey_smallhat"] = true,
	["monkey_mediumhat"] = true,
	["polly_rogershat"] = true,
	["moonstorm_goggleshat"] = true,
	["winterhat"] = true,
	["malbatross_beak"] = true,
	["driftwood"] = true,
	["bushhat"] = true,
	["oar_driftwood"] = true,
	["oar"] = true,
	["strawhat"] = true,
	["lantern"] = true,
	["nitre"] = true
}

local bpMode = {
	x = -136,
	s = true
}
if (Profile:GetIntegratedBackpack()) then
	local W, H = TheSim:GetScreenSize()
	bpMode.x = W/2 - 130
	bpMode.s = false
end

local params = {
	pocketwatchpack = {
		widget = {
			slotpos = {},
			animbank = "ui_piggyback_2x6",
			animbuild = "ui_piggyback_2x6",
			pos = Vector3(bpMode.x, -50, 0)
		},
		issidewidget = bpMode.s,
		openlimit = 1,
		type = "chest"
	}
}

for y = 0, 5 do
	table.insert(params.pocketwatchpack.widget.slotpos, Vector3(-162, -75 * y + 170, 0))
	table.insert(params.pocketwatchpack.widget.slotpos, Vector3(-162 + 75, -75 * y + 170, 0))
end


function params.pocketwatchpack.itemtestfn(container, item, slot)
	if item:HasTag("pocketwatch") then return true end
	return storable[item.prefab] == true
end 


for k, v in pairs(params) do
	containers.MAXITEMSLOTS = math.max(containers.MAXITEMSLOTS, v.widget.slotpos ~= nil and #v.widget.slotpos or 0)
end


local containers_widgetsetup = containers.widgetsetup

function containers.widgetsetup(container, prefab, data)
	local t = data or params[prefab or container.inst.prefab]
	if t ~= nil then
		for k, v in pairs(t) do
			container[k] = v
		end
		container:SetNumSlots(container.widget.slotpos ~= nil and #container.widget.slotpos or 0)    
	else
		return containers_widgetsetup(container, prefab, data)
	end
end
