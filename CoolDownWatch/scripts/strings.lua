local STRINGS = GLOBAL.STRINGS

STRINGS.NAMES.POCKETWATCH_SHIFTING = "冷切表"
STRINGS.RECIPE_DESC.POCKETWATCH_SHIFTING = "或许它能让你的一只表重振旗鼓。"

STRINGS.CHARACTERS.GENERIC.POCKETWATCH_SHIFTING_FAIL = "only_used_by_wanda"
STRINGS.CHARACTERS.WANDA.POCKETWATCH_SHIFTING_FAIL = "There is nothing to Cooldown here!"

-- Lines are formatted Generic - Recharging

local lines = {
	GENERIC = {"I'm sure it's scientific!", "Clock hands don't go that way!"},
	WANDA = {"Causality doesn't always mean reality.", "快点，时间就是生命!"},
	WILLOW = {"Ruins my hard work.", "I can't read that."},
	WOLFGANG = {"No burning!", "Is clock broken?"},
	WENDY = {"Wards off inevitability.", "Its energy is spent."},
	WX78 = {"SYSTEM RESTORE", "RECHARGING"},
	WICKERBOTTOM = {"It changes an instance of reality to another one.", "It has to wind itself back up."},
	WOODIE = {"I am not sure I get it.", "Weird."},
	WINONA = {"Not exactly my kind of engineering.", "You sure this thing's working right?"},
	WAXWELL = {"They aren't going to like this.", "Going to have to wait to fix your mistakes."},
	WATHGRITHR = {"So long as it lets me make my spears!", "Is it supposed to do that?"},
	WEBBER = {"Lets us keep our things.", "It doesn't normally do that."},
	WORTOX = {"Ruins my pranks.", "I didn't do it, this time."},
	WURT = {"It fix thing.", "Look at it go!"},
	WARLY = {"Can it fix a bad meal?", "What kind of timer is that?"},
	WORMWOOD = {"Fixes big mistake.", "It make noises."},
	WALTER = {"This one's different!", "What's it doing now?"}
}

for k,v in pairs(lines) do
	STRINGS.CHARACTERS[k].DESCRIBE.POCKETWATCH_SHIFTING = {
		GENERIC = v[1],
		RECHARGING = v[2],
	}
end