--==============================================================
-- RD Craft Animations
-- Safe integration: do NOT reset Config. These entries can be used
-- by rd_realistic_crafting.lua for recipe animations.
--==============================================================
Config = Config or {}
Config.Animations = Config.Animations or {}

Config.Animations["craft"] = {
    dict = "mech_inventory@crafting@fallbacks",
    name = "full_craft_and_stow",
    flag = 27,
    type = 'standard'
}

Config.Animations["spindlecook"] = {
    dict = "amb_camp@world_camp_fire_cooking@male_d@wip_base",
    name = "wip_base",
    flag = 17,
    type = 'standard',
    prop = {
        model = 'p_stick04x',
        -- RD HAND FIX: correct RedM right-hand bone + palm placement.
        coords = { x = 0.040, y = 0.030, z = -0.020, xr = -92.0, yr = 5.0, zr = 82.0 },
        bone = 'SKEL_R_Hand',
        subprops = {
            {
                model = 's_meatbit_chunck_medium01x',
                coords = { x = 0.0, y = 0.0, z = -0.36, xr = 0.0, yr = 0.0, zr = 78.0 }
            }
        }
    }
}

Config.Animations["stirpot"] = {
    dict = "amb_camp@world_camp_fire_cooking@male_d@wip_base",
    name = "wip_base",
    flag = 17,
    type = 'standard',
    prop = {
        model = 'p_woodenspoon01x',
        coords = { x = 0.045, y = 0.030, z = -0.018, xr = -72.0, yr = 12.0, zr = 78.0 },
        bone = 'SKEL_R_Hand'
    }
}

Config.Animations["knifecooking"] = {
    dict = "amb_camp@world_player_fire_cook_knife@male_a@wip_base",
    name = "wip_base",
    flag = 17,
    type = 'standard',
    prop = {
        model = 'p_knife01x',
        -- RD HAND FIX: knife now sits in the RIGHT palm, not root/left hand.
        coords = { x = 0.035, y = 0.025, z = -0.018, xr = -96.0, yr = 6.0, zr = 84.0 },
        bone = 'SKEL_R_Hand',
        subprops = {
            {
                model = 'p_redefleshymeat01xa',
                target = 'ped',
                bone = 'SKEL_L_Hand',
                coords = { x = 0.040, y = 0.025, z = -0.020, xr = 72.0, yr = -8.0, zr = -12.0 }
            }
        }
    }
}

Config.Animations["campfire"] = {
    dict = "script_campfire@lighting_fire@male_male",
    name = "light_fire_b_p2_male_b",
    flag = 17,
    type = 'standard'
}

Config.Animations["riverwash"] = {
    dict = "amb_misc@world_human_wash_kneel_river@female_a@idle_a",
    name = "idle_c",
    flag = 17,
    type = 'standard'
}

Config.Animations["hoeing"] = {
    dict = "amb_work@world_human_farmer_hoe@male_a@base",
    name = "base",
    flag = 17,
    type = 'standard',
    prop = {
        model = 'p_rake01x',
        coords = { x = 0.2, y = 0.3, z = 0.1, xr = 210.0, yr = -90.0, zr = -186.0 },
        bone = 'SKEL_L_Hand'
    }
}

Config.Animations["readnewspaper"] = {
    dict = "mech_carry_box",
    name = "idle",
    flag = 17,
    type = 'standard',
    prop = {
        model = 'p_cs_newspaper_02x_noanim',
        coords = { x = 0.15, y = -0.0399, z = 0, xr = 0.0, yr = 0.0, zr = 0.0 },
        bone = 'SKEL_L_Finger12'
    }
}

Config.Animations["gravedigging"] = {
    dict = "amb_work@world_human_gravedig@working@male_b@base",
    name = "base",
    flag = 17,
    type = 'standard',
    prop = {
        model = 'p_shovel02x',
        coords = { x = 0.0, y = -0.09, z = -0.09, xr = 250.2899, yr = 579.19, zr = 373.3 },
        bone = 'SKEL_R_Hand'
    }
}

Config.Animations["carry_box"] = {
    dict = "mech_carry_box",
    name = "idle",
    flag = 31,
    type = 'standard',
    prop = {
        model = 'p_chair_crate02x',
        coords = { x = 0.1, y = -0.1399, z = 0.21, xr = 263.2899, yr = 619.19, zr = 334.3 },
        bone = 'SKEL_L_Hand'
    }
}

Config.Animations["carry_sugar"] = {
    dict = "mech_carry_box",
    name = "idle",
    flag = 31,
    type = 'standard',
    prop = {
        model = 'p_cs_sacksugarcornwall01x',
        coords = { x = -0.05, y = 0.0101, z = 0.18, xr = 323.6899, yr = 705.89, zr = 361.4 },
        bone = 'SKEL_L_Hand'
    }
}

Config.Animations["sweeping"] = {
    dict = "amb_work@world_human_farmer_hoe@male_a@base",
    name = "base",
    flag = 17,
    type = 'standard',
    prop = {
        model = 'p_broom04x',
        coords = { x = 0.75, y = 1.1, z = 0.1, xr = 303.0, yr = -90.0, zr = -186.0 },
        bone = 'SKEL_L_Hand'
    }
}

Config.Animations["carry_barrel"] = {
    dict = "mech_carry_box",
    name = "idle",
    flag = 31,
    type = 'standard',
    prop = {
        model = 'p_barrel010x',
        coords = { x = -0.05, y = -0.0899, z = 0.18, xr = 320.6899, yr = 714.89, zr = 361.4 },
        bone = 'SKEL_L_Hand'
    }
}

Config.Animations["carry_moonshine"] = {
    dict = "mech_carry_box",
    name = "idle",
    flag = 31,
    type = 'standard',
    prop = {
        model = 'p_bottlecrate_mil',
        coords = { x = 0.1, y = -0.1399, z = 0.26, xr = 263.2899, yr = 619.19, zr = 334.3 },
        bone = 'SKEL_L_Hand'
    }
}

Config.Animations["carry_moonshine2"] = {
    dict = "mech_carry_box",
    name = "idle",
    flag = 31,
    type = 'standard',
    prop = {
        model = 'p_bottlecrate_cul',
        coords = { x = 0.1, y = -0.1399, z = 0.26, xr = 263.2899, yr = 619.19, zr = 334.3 },
        bone = 'SKEL_L_Hand'
    }
}


-- Scenario animation key for recipes that should use the same FIREWOOD / CHOP scene.
-- Example recipe: animation = 'firewood' or animation = 'spooni_firewood'
Config.Animations["firewood"] = {
    type = 'scenario',
    scenarios = {
        'WORLD_HUMAN_CHOP_WOOD',
        'WORLD_HUMAN_FIREWOOD_CHOP',
        'WORLD_HUMAN_SPLIT_WOOD',
        'WORLD_HUMAN_WOOD_CHOP',
    },
    flag = 17,
    prop = {
        model = 'p_axe02x',
        coords = { x = 0.05, y = -0.02, z = -0.02, xr = -78.0, yr = 10.0, zr = 4.0 },
        bone = 'SKEL_R_Hand'
    }
}
Config.Animations["spooni_firewood"] = Config.Animations["firewood"]
Config.Animations["chop_firewood"] = Config.Animations["firewood"]

--==============================================================
-- RD EXTRA ANIMATIONS: smoking / medical / sleep / moonshine
-- These keys are referenced by config/rd_realistic_crafting.lua recipes.
--==============================================================
Config.Animations["smoke_cigarette"] = {
    dict = "amb_rest@world_human_smoke@male_a@idle_a",
    name = "idle_a",
    flag = 17,
    type = 'standard',
    prop = {
        model = 'p_cigarette01x',
        coords = { x = 0.030, y = 0.012, z = -0.008, xr = 18.0, yr = 2.0, zr = 84.0 },
        bone = 'SKEL_R_Finger11'
    }
}
Config.Animations["smoke"] = Config.Animations["smoke_cigarette"]

Config.Animations["smoke_cigar"] = {
    dict = "amb_rest@world_human_smoke_cigar@male_a@idle_a",
    name = "idle_a",
    flag = 17,
    type = 'standard',
    prop = {
        model = 'p_cigar01x',
        coords = { x = 0.034, y = 0.014, z = -0.010, xr = 18.0, yr = 2.0, zr = 82.0 },
        bone = 'SKEL_R_Finger11'
    }
}

Config.Animations["pipe_craft"] = {
    dict = "amb_work@world_human_hammer@male_a@base",
    name = "base",
    flag = 17,
    type = 'standard',
    stationProps = {
        { kind = 'WorkTable', x = 0.0, y = 1.03, z = -0.98, heading = 0.0, ground = true },
        { kind = 'SmokePipe', x = 0.18, y = 1.00, z = -0.82, heading = 25.0, ground = true },
        { kind = 'CarpenterTools', x = -0.20, y = 1.04, z = -0.82, heading = -20.0, ground = true }
    }
}

Config.Animations["pipe_smoke_craft"] = {
    dict = "amb_rest@world_human_smoke@male_a@idle_a",
    name = "idle_a",
    flag = 17,
    type = 'standard',
    prop = {
        model = 'p_pipe01x',
        coords = { x = 0.045, y = 0.015, z = -0.015, xr = 12.0, yr = -6.0, zr = 84.0 },
        bone = 'SKEL_R_Finger11'
    }
}

Config.Animations["peacepipe_craft"] = {
    dict = "amb_work@world_human_hammer@male_a@base",
    name = "base",
    flag = 17,
    type = 'standard',
    stationProps = {
        { kind = 'WorkTable', x = 0.0, y = 1.03, z = -0.98, heading = 0.0, ground = true },
        { kind = 'SmokePipe', x = 0.18, y = 1.00, z = -0.82, heading = 25.0, ground = true },
        { kind = 'TobaccoPouch', x = -0.18, y = 1.02, z = -0.85, heading = -18.0, ground = true }
    }
}

Config.Animations["chew_tobacco"] = {
    dict = "amb_work@world_human_crouch_inspect@male_c@idle_a",
    name = "idle_a",
    flag = 17,
    type = 'standard',
    prop = {
        model = 'p_tobaccopouch01x',
        coords = { x = 0.040, y = 0.020, z = -0.018, xr = -70.0, yr = 8.0, zr = 75.0 },
        bone = 'SKEL_R_Hand'
    }
}
Config.Animations["chew"] = Config.Animations["chew_tobacco"]

Config.Animations["bandage_craft"] = {
    dict = "mech_inventory@item@bandage@unarmed",
    name = "use",
    flag = 17,
    type = 'standard',
    prop = {
        model = 'p_cs_bandage01x',
        coords = { x = 0.045, y = 0.025, z = -0.015, xr = -70.0, yr = 8.0, zr = 80.0 },
        bone = 'SKEL_R_Hand'
    }
}
Config.Animations["bandage"] = Config.Animations["bandage_craft"]

Config.Animations["syringe_craft"] = {
    dict = "mech_inventory@item@syringe@unarmed",
    name = "use",
    flag = 17,
    type = 'standard',
    prop = {
        model = 'mp007_p_mp_syringe01x_1',
        coords = { x = 0.050, y = 0.018, z = -0.010, xr = -82.0, yr = 12.0, zr = 75.0 },
        bone = 'SKEL_R_Hand'
    }
}
Config.Animations["syringe"] = Config.Animations["syringe_craft"]

Config.Animations["bedroll_craft"] = {
    dict = "amb_work@world_human_crouch_inspect@male_c@idle_a",
    name = "idle_a",
    flag = 17,
    type = 'standard',
    groundProp = { kind = 'Bedroll', x = 0.0, y = 1.05, z = -0.98, heading = 0.0, ground = true }
}
Config.Animations["sleepingbag_craft"] = {
    dict = "amb_work@world_human_crouch_inspect@male_c@idle_a",
    name = "idle_a",
    flag = 17,
    type = 'standard',
    groundProp = { kind = 'SleepingBag', x = 0.0, y = 1.05, z = -0.98, heading = 0.0, ground = true }
}
Config.Animations["sleep"] = Config.Animations["bedroll_craft"]

Config.Animations["moonshine_metal"] = {
    dict = "amb_work@world_human_hammer@male_a@base",
    name = "base",
    flag = 17,
    type = 'standard',
    stationProps = {
        { kind = 'WorkTable', x = 0.0, y = 1.05, z = -0.98, heading = 0.0, ground = true },
        { kind = 'StillBoiler', x = 0.22, y = 1.02, z = -0.82, heading = 22.0, ground = true },
        { kind = 'CarpenterTools', x = -0.22, y = 1.02, z = -0.82, heading = -18.0, ground = true }
    }
}
Config.Animations["moonshine_condenser"] = {
    dict = "amb_work@world_human_repair@male_a@base",
    name = "base",
    flag = 17,
    type = 'standard',
    stationProps = {
        { kind = 'WorkTable', x = 0.0, y = 1.05, z = -0.98, heading = 0.0, ground = true },
        { kind = 'StillCondenser', x = 0.18, y = 1.02, z = -0.82, heading = 15.0, ground = true },
        { kind = 'StillWorm', x = -0.18, y = 1.00, z = -0.84, heading = -25.0, ground = true }
    }
}
Config.Animations["moonshine_barrel"] = {
    dict = "amb_work@world_human_hammer@male_a@base",
    name = "base",
    flag = 17,
    type = 'standard',
    stationProps = {
        { kind = 'StillBarrel', x = 0.0, y = 1.05, z = -0.98, heading = 0.0, ground = true },
        { kind = 'CarpenterTools', x = -0.34, y = 1.00, z = -0.86, heading = -20.0, ground = true }
    }
}
Config.Animations["moonshine_bucket"] = {
    dict = "amb_work@world_human_crouch_inspect@male_c@idle_a",
    name = "idle_a",
    flag = 17,
    type = 'standard',
    groundProp = { kind = 'MashBucket', x = 0.0, y = 1.02, z = -0.98, heading = 0.0, ground = true }
}
Config.Animations["moonshine_repair"] = {
    dict = "amb_work@world_human_hammer@male_a@base",
    name = "base",
    flag = 17,
    type = 'standard',
    stationProps = {
        { kind = 'WorkTable', x = 0.0, y = 1.05, z = -0.98, heading = 0.0, ground = true },
        { kind = 'RepairKit', x = 0.18, y = 1.02, z = -0.82, heading = 15.0, ground = true }
    }
}
Config.Animations["moonshine_kit"] = {
    dict = "amb_work@world_human_hammer@male_a@base",
    name = "base",
    flag = 17,
    type = 'standard',
    stationProps = {
        { kind = 'MoonshineStill', x = 0.0, y = 1.10, z = -0.98, heading = 0.0, ground = true },
        { kind = 'StillBoiler', x = 0.28, y = 1.02, z = -0.84, heading = 25.0, ground = true },
        { kind = 'StillCondenser', x = -0.28, y = 1.02, z = -0.84, heading = -25.0, ground = true },
        { kind = 'StillBarrel', x = 0.0, y = 1.36, z = -0.98, heading = 0.0, ground = true }
    }
}
