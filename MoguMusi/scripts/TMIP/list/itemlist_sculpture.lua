local thetable = {
    "statueglommer", "statuemaxwell", "marblepillar", "statueharp",
    "statue_marble_muse", "statue_marble_pawn", "statue_marble",
    "sculpture_bishopbody", "sculpture_knightbody", "sculpture_rookbody",
    "sculpture_bishophead", "sculpture_knighthead", "sculpture_rooknose",
    "moon_altar_glass", "moon_altar_seed", "moon_altar_idol",
    "moon_altar_crown", "moon_altar_icon","moon_altar_ward",
    "glassspike_short", "glassspike_med", "glassspike_tall",
    "glassspike", "glassblock", "cavein_boulder","sculpture_bishop",
    "sculpture_knight", "sculpture_rook","chesspiece_hornucopia_marble",
    "chesspiece_hornucopia_stone", "chesspiece_hornucopia_moonglass", 
    "chesspiece_pipe_marble", "chesspiece_pipe_stone",
    "chesspiece_pipe_moonglass","chesspiece_pipe","chesspiece_hornucopia", 
    "oceantreenut","shell_cluster", "sunkenchest","potatosack",
}

local thelist = {
    "moosegoose", "dragonfly", "bearger", "deerclops", "crabking", "malbatross",
    "antlion","beequeen","klaus","minotaur","stalker","toadstool","knight",
    "bishop","rook","formal","muse","pawn","anchor","butterfly",
    "moon","claywarg","clayhound","carrat","beefalo","eyeofterror","twinsofterror",
    "guardianphase3","kitcoon","catcoon",
}


for k,v in pairs(thelist) do
    table.insert( thetable,  "chesspiece_"..v.."_moonglass" )
    table.insert( thetable,  "chesspiece_"..v.."_marble" )
    table.insert( thetable,  "chesspiece_"..v.."_stone" )
    table.insert( thetable,  "chesspiece_"..v.."_sketch" )
end

for k,v in pairs(thelist) do
    table.insert( thetable,  "chesspiece_"..v)
end


return thetable