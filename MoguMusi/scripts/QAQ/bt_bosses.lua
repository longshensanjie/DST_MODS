return {
    dragonfly = {
        image = "chesspiece_dragonfly",
        duration = TUNING.DRAGONFLY_RESPAWN_TIME,
        judge = {"death"},
        descripe = STRINGS.NAMES.DRAGONFLY,
    },
    beequeen = {
        image = "chesspiece_beequeen",
        duration = TUNING.BEEQUEEN_RESPAWN_TIME,
        judge = {"death"},
        descripe = STRINGS.NAMES.BEEQUEEN,
    },
    eyeofterror = {
        image = "terrarium_crimson",
        duration = TUNING.EYEOFTERROR_SPAWNDELAY,
        judge = {"death"},
        descripe = STRINGS.NAMES.TERRARIUM,
    },
    twinofterror1 = {
        image = "terrarium_crimson",
        duration = TUNING.EYEOFTERROR_SPAWNDELAY,
        judge = {"death"},
        descripe = STRINGS.NAMES.TERRARIUM,
        alias = "eyeofterror",
    },
    twinofterror2 = {
        image = "terrarium_crimson",
        duration = TUNING.EYEOFTERROR_SPAWNDELAY,
        judge = {"death"},
        descripe = STRINGS.NAMES.TERRARIUM,
        alias = "eyeofterror",
    },
    malbatross = {
        image = "chesspiece_malbatross",
        duration = TUNING.MALBATROSS_SPAWNDELAY_BASE,
        judge = {"death"},
        descripe = STRINGS.NAMES.MALBATROSS,
    },
    klaus = {
        image = "chesspiece_klaus",
        duration = TUNING.KLAUSSACK_EVENT_RESPAWN_TIME,
        judge = {"death"},
        descripe = STRINGS.NAMES.KLAUS,
    },
    walrus = {
        image = "walrus_tusk",
        duration = TUNING.WALRUS_REGEN_PERIOD,
        judge = {"death"},
        descripe = STRINGS.NAMES.WALRUS,
    },
    crabking = {
        image = "chesspiece_crabking",
        duration = TUNING.CRABKING_RESPAWN_TIME,
        judge = {"death","death1","death2","death3"},
        descripe = STRINGS.NAMES.CRABKING,
    },
    toadstool = {
        image = "chesspiece_toadstool",
        duration = TUNING.TOADSTOOL_RESPAWN_TIME,
        judge = {"death"},
        descripe = STRINGS.NAMES.TOADSTOOL,
    },
    toadstool_dark = {
        image = "chesspiece_toadstool",
        duration = TUNING.CRABKING_RESPAWN_TIME,
        judge = {"death"},
        descripe = STRINGS.NAMES.TOADSTOOL,
        alias = "toadstool",
    },
    stalker_atrium = {
        image = "chesspiece_stalker",
        duration = TUNING.ATRIUM_GATE_COOLDOWN + TUNING.ATRIUM_GATE_DESTABILIZE_DELAY + TUNING.ATRIUM_GATE_DESTABILIZE_TIME + TUNING.ATRIUM_GATE_DESTABILIZE_WARNING_TIME,
        judge = {"death3"},
        descripe = STRINGS.NAMES.STALKER_ATRIUM,
    },
    lordfruitfly = {
        image = "fruitflyfruit",
        duration = TUNING.LORDFRUITFLY_RESPAWN_TIME,
        judge = {"death"},
        descripe = STRINGS.NAMES.LORDFRUITFLY,
    },
    



    -- 补充生物
    minotaur = {
        image = "chesspiece_minotaur",
        descripe = STRINGS.NAMES.MINOTAUR,
    },

    -- 模组联动内容
    deerclops = {
        image = "chesspiece_deerclops_moonglass",
        descripe = STRINGS.NAMES.DEERCLOPS,
    },
    bearger = {
        image = "chesspiece_bearger_moonglass",
        descripe = STRINGS.NAMES.BEARGER,
    },
    hound = {
        image = "chesspiece_claywarg_moonglass",
        descripe = STRINGS.NAMES.HOUND,
    },
    worm = {
        image = "wormlight",
        descripe = STRINGS.NAMES.WORM,
    },
    sinkhole = {
        image = "chesspiece_antlion_moonglass",
        descripe = "蚁狮地陷",
    },
    cavein = {
        image = "cavein_boulder",
        descripe = "蚁狮落石"
    }
}