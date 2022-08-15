local thetable = {
}
local thelist = {
    "shroomcake","vegstinger","bananajuice","bunnystew",
    "bonestew", "meatballs", "kabobs", "honeyham", "honeynuggets", "surfnturf",
    "seafoodgumbo", "fishsticks", "californiaroll", "fishtacos", "ceviche",
    "unagi", "lobsterdinner", "lobsterbisque", "barnaclestuffedfishhead",
    "barnaclinguine", "barnaclepita", "barnaclesushi", "turkeydinner",
    "baconeggs", "perogies", "hotchili", "pepperpopper", "frogglebunwich",
    "guacamole", "monsterlasagna", "mandrakesoup", "sweettea",
    "mashedpotatoes", "potatotornado", "pumpkincookie", "stuffedeggplant",
    "salsa", "ratatouille", "asparagussoup", "flowersalad",
    "meatysalad", "leafymeatsouffle", "leafymeatburger", "leafloaf",
    "dragonpie", "jammypreserves", "fruitmedley", "trailmix", "bananapop",
    "watermelonicle", "icecream", "waffles", "butterflymuffin", "powcake",
    "taffy", "jellybean",
    "figatoni","figkabab","frognewton","frozenbananadaiquiri","koalefig_trunk",
    "bonesoup", "freshfruitcrepes", "moqueca",
    "monstertartare", "voltgoatjelly", "glowberrymousse", "potatosouffle",
    "frogfishbowl", "gazpacho", "dragonchilisalad", "nightmarepie","wetgoop",
}

local thelist2 = {
    "wereitem_beaver", "wereitem_goose",
    "wereitem_moose","carnivalfood_corntea",
    "berrysauce", "bibingka", "cabbagerolls",
    "festivefish", "gravy", "latkes", "lutefisk", "mulleddrink", "panettone",
    "pavlova", "pickledherring", "polishcookie", "pumpkinpie", "roastturkey",
    "stuffing", "sweetpotato", "tamales", "tourtiere",
}

for k,v in pairs(thelist) do
    table.insert( thetable, v)
end


for k,v in pairs(thelist) do
    table.insert( thetable,  v.."_spice_sugar" )
    table.insert( thetable,  v.."_spice_salt" )
    table.insert( thetable,  v.."_spice_garlic" )
    table.insert( thetable,  v.."_spice_chili" )
end


for k,v in pairs(thelist2) do
    table.insert( thetable, v)
end
return thetable