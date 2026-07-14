Config4 = {} 
Config4.weapons = {  
    ["Melee"] = {
        ["Horror Knife"] = {	
            hashname = "WEAPON_MELEE_KNIFE_HORROR",
            expadd = 1,
            expreq = 0,
            diff = 3500,
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable
            jobonly = true, -- turn this to true if you want crafting this weapon to only be allowed for a certain job
            jobs = {"gunsmith"}, 
            materials = {
                item1 = {name = "ironbar",label = "Iron Bar", amount = 3},
                item2 = {name = "hwood",label = "hard wood", amount = 2},
                item3 = {name = "coal",label = "Coal", amount = 5},
                item10 = {name = "bolts",label = "Bolts", amount = 2},

            }, 
        
        },
        ["Rustic Knife"] = {	
            hashname = "WEAPON_MELEE_KNIFE_RUSTIC",
            expadd = 1,
            expreq = 0,
            diff = 2500,
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable
            jobonly = true, -- turn this to true if you want crafting this weapon to only be allowed for a certain job
            jobs = {"gunsmith"}, 
            materials = {
                item1 = {name = "ironbar",label = "Iron Bar", amount = 3},
                item2 = {name = "hwood",label = "hard wood", amount = 2},
                item3 = {name = "deerskin",label = "deerskin", amount = 2},
                item4 = {name = "coal",label = "Coal", amount = 5},
                item10 = {name = "bolts",label = "Bolts", amount = 2},


            },   
        
        },
        ["Tradders Knife"] = {	
            expadd = 1,
            expreq = 0,
            diff = 3000,
            hashname = "WEAPON_MELEE_KNIFE_TRADER",   
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable
            jobonly = true, -- turn this to true if you want crafting this weapon to only be allowed for a certain job
            jobs = {"gunsmith"}, 
            materials = {
                item1 = {name = "ironbar",label = "Iron Bar", amount = 3},
                item2 = {name = "hwood",label = "hard wood", amount = 2},
                item3 = {name = "deerskin",label = "deerskin", amount = 2},
                item4 = {name = "coal",label = "Coal", amount = 5},
                item10 = {name = "bolts",label = "Bolts", amount = 2},


            }, 
        },
        ["JawBone Knife"] = {	
            expadd = 1,
            expreq = 0,
            diff = 3000,
            hashname = "WEAPON_MELEE_KNIFE_JAWBONE",    
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable
            jobonly = true,
            jobs = {"gunsmith"}, 
            materials = {
                item1 = {name = "ironbar",label = "Iron Bar", amount = 2},
                item2 = {name = "hwood",label = "hard wood", amount = 1},
                item3 = {name = "deerskin",label = "deerskin", amount = 2},
                item4 = {name = "coal",label = "Coal", amount = 5},
                                item10 = {name = "bolts",label = "Bolts", amount = 2},


            }, 
        },
        ["Cleaver"] = {	
            expadd = 1,
            expreq = 0,
            diff = 3000,
            hashname = "WEAPON_MELEE_CLEAVER", 
            jobonly = true,
            jobs = {"gunsmith"}, 
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable
            materials = {
                item1 = {name = "ironbar",label = "Iron Bar", amount = 3},
                item2 = {name = "hwood",label = "hard wood", amount = 1},
                item3 = {name = "bucks",label = "Buck skin", amount = 1},
                item4 = {name = "coal",label = "Coal", amount = 5},
                                item10 = {name = "bolts",label = "Bolts", amount = 2},


            }, 
        },
        ["Hunter Hatchet"] = {	
            expadd = 1,
            expreq = 0,
            diff = 2500,
            hashname = "WEAPON_MELEE_HATCHET_HUNTER",  
            jobonly = true,
            jobs = {"gunsmith"}, 
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable  
            materials = {
                item1 = {name = "ironbar",label = "Iron Bar", amount = 4},
                item2 = {name = "hwood",label = "hard wood", amount = 1},
                item3 = {name = "bucks",label = "Buck skin", amount = 2},
                item4 = {name = "coal",label = "Coal", amount = 5},
                                item10 = {name = "bolts",label = "Bolts", amount = 2},


            }, 
        },
        ["Machete"] = {	
            expadd = 1,
            expreq = 0,
            diff = 3000,
            hashname = "WEAPON_MELEE_MACHETE", 
            jobonly = true,
            jobs = {"gunsmith"}, 
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable
            materials = {
                item1 = {name = "ironbar",label = "Iron Bar", amount = 4},
                item2 = {name = "hwood",label = "hard wood", amount = 1},
                item3 = {name = "bucks",label = "Buck skin", amount = 2},
                item4 = {name = "coal",label = "Coal", amount = 5},
                                item10 = {name = "bolts",label = "Bolts", amount = 2},


            }, 
        },
        ["Collector Machete"] = {	
            expadd = 1,
            expreq = 0,
            diff = 2500,
            hashname = "WEAPON_MELEE_MACHETE_COLLECTOR",    
            jobonly = true,
            jobs = {"gunsmith"}, 
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable 
            materials = {
                item1 = {name = "ironbar",label = "Iron Bar", amount = 4},
                item2 = {name = "hwood",label = "hard wood", amount = 2},
                item3 = {name = "bucks",label = "Buck skin", amount = 2},
                item4 = {name = "coal",label = "Coal", amount = 5},
                                item10 = {name = "bolts",label = "Bolts", amount = 2},


            }, 
        },
        
    },
    ["Bows"] = {
        ["Improved Bow"] = {	
            expadd = 1,
            expreq = 0,
            diff = 3000,
            hashname = "WEAPON_BOW_IMPROVED",   
            jobonly = true,
            jobs = {"gunsmith"},  
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable
            materials = {
                item1 = {name = "deerskin",label = "deerskin", amount = 2},
                item2 = {name = "hwood",label = "Hard Wood", amount = 3},
                item3 = {name = "fibers",label = "Fibers", amount = 10},
            }, 
        },
    },
    ["Rifles"] = {
        ["Elephant Rifle"] = {	
            expadd = 2,
            expreq = 0,
            diff = 2500,
            hashname = "WEAPON_RIFLE_ELEPHANT",   
            jobonly = true,
            jobs = {"gunsmith"}, 
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable  
            materials = {
                item1 = {name = "wooden_stock",label = "Wooden Stock", amount = 1},
                item2 = {name = "bolt_carrier",label = "Bolt Carrier", amount = 1},
                item3 = {name = "rifle_barrel",label = "Rifle Barrel", amount = 1},
                item4 = {name = "coal",label = "Coal", amount = 5},
                item5 = {name = "recoil_spring",label = "Recoil Spring", amount = 1},
                item6 = {name = "firing_pin",label = "Firing Pin", amount = 1},
                item7 = {name = "rifle_receiver",label = "Rifle Receiver", amount = 1},
                                item10 = {name = "bolts",label = "Bolts", amount = 2},


            }, 
        },
        ["Rollingblock Rifle"] = {	
            expadd = 2,
            expreq = 0,
            diff = 3000,
            hashname = "WEAPON_SNIPERRIFLE_ROLLINGBLOCK", 
            jobonly = true,
            jobs = {"gunsmith"},  
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable   
            materials = {
                item1 = {name = "wooden_stock",label = "Wooden Stock", amount = 1},
                item2 = {name = "bolt_carrier",label = "Bolt Carrier", amount = 1},
                item3 = {name = "rifle_barrel",label = "Rifle Barrel", amount = 1},
                item4 = {name = "coal",label = "Coal", amount = 5},
                item5 = {name = "recoil_spring",label = "Recoil Spring", amount = 1},
                item6 = {name = "firing_pin",label = "Firing Pin", amount = 1},
                item7 = {name = "rifle_receiver",label = "Rifle Receiver", amount = 1},
                                item10 = {name = "bolts",label = "Bolts", amount = 2},



            }, 
        },
        ["Carcano Rifle"] = {	
            expadd = 2,
            expreq = 0,
            diff = 3000,
            hashname = "WEAPON_SNIPERRIFLE_CARCANO",  
            jobonly = true,
            jobs = {"gunsmith"},  
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable   
            materials = {
                item1 = {name = "wooden_stock",label = "Wooden Stock", amount = 1},
                item2 = {name = "bolt_carrier",label = "Bolt Carrier", amount = 1},
                item3 = {name = "rifle_barrel",label = "Rifle Barrel", amount = 1},
                item4 = {name = "coal",label = "Coal", amount = 5},
                item5 = {name = "recoil_spring",label = "Recoil Spring", amount = 1},
                item6 = {name = "firing_pin",label = "Firing Pin", amount = 1},
                item7 = {name = "rifle_receiver",label = "Rifle Receiver", amount = 1},
                                item10 = {name = "bolts",label = "Bolts", amount = 2},



            }, 
        },
        ["Springfield Rifle"] = {	
            expadd = 2,
            expreq = 0,
            diff = 3000,
            hashname = "WEAPON_RIFLE_SPRINGFIELD", 
            jobonly = true,
            jobs = {"gunsmith"},  
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable  
            materials = {
                item1 = {name = "wooden_stock",label = "Wooden Stock", amount = 1},
                item2 = {name = "bolt_carrier",label = "Bolt Carrier", amount = 1},
                item3 = {name = "rifle_barrel",label = "Rifle Barrel", amount = 1},
                item4 = {name = "coal",label = "Coal", amount = 5},
                item5 = {name = "recoil_spring",label = "Recoil Spring", amount = 1},
                item6 = {name = "firing_pin",label = "Firing Pin", amount = 1},
                item7 = {name = "rifle_receiver",label = "Rifle Receiver", amount = 1},
                                item10 = {name = "bolts",label = "Bolts", amount = 2},


            }, 
        },
        ["Boltaction Rifle"] = {	
            expadd = 2,
            expreq = 0,
            diff = 3000,
            hashname = "WEAPON_RIFLE_BOLTACTION",  
            jobonly = true,
            jobs = {"gunsmith"},  
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable   
            materials = {
                item1 = {name = "wooden_stock",label = "Wooden Stock", amount = 1},
                item2 = {name = "bolt_carrier",label = "Bolt Carrier", amount = 1},
                item3 = {name = "rifle_barrel",label = "Rifle Barrel", amount = 1},
                item4 = {name = "coal",label = "Coal", amount = 5},
                item5 = {name = "recoil_spring",label = "Recoil Spring", amount = 1},
                item6 = {name = "firing_pin",label = "Firing Pin", amount = 1},
                item7 = {name = "rifle_receiver",label = "Rifle Receiver", amount = 1},
                                item10 = {name = "bolts",label = "Bolts", amount = 2},



            }, 
        },
    },
    ["Repeaters"] = {
        ["Winchester Repeater"] = {	
            expadd = 2,
            expreq = 0,
            diff = 3000,
            hashname = "WEAPON_REPEATER_WINCHESTER",   
            jobonly = true,
            jobs = {"gunsmith"},  
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable 
            materials = {
                item1 = {name = "wooden_stock",label = "Wooden Stock", amount = 1},
                item2 = {name = "bolt_carrier",label = "Bolt Carrier", amount = 1},
                item3 = {name = "rifle_barrel",label = "Rifle Barrel", amount = 1},
                item4 = {name = "coal",label = "Coal", amount = 5},
                item5 = {name = "recoil_spring",label = "Recoil Spring", amount = 1},
                item6 = {name = "firing_pin",label = "Firing Pin", amount = 1},
                item7 = {name = "rifle_receiver",label = "Rifle Receiver", amount = 1},
                                item10 = {name = "bolts",label = "Bolts", amount = 2},

            }, 
        },
        ["Henry Repeater"] = {	
            expadd = 2,
            expreq = 0,
            diff = 3000,
            hashname = "WEAPON_REPEATER_HENRY", 
            jobonly = true,
            jobs = {"gunsmith"},  
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable
            materials = {
                item1 = {name = "wooden_stock",label = "Wooden Stock", amount = 1},
                item2 = {name = "bolt_carrier",label = "Bolt Carrier", amount = 1},
                item3 = {name = "rifle_barrel",label = "Rifle Barrel", amount = 1},
                item4 = {name = "coal",label = "Coal", amount = 5},
                item5 = {name = "recoil_spring",label = "Recoil Spring", amount = 1},
                item6 = {name = "firing_pin",label = "Firing Pin", amount = 1},
                item7 = {name = "rifle_receiver",label = "Rifle Receiver", amount = 1},
                                item10 = {name = "bolts",label = "Bolts", amount = 2},

            }, 
        },
        ["Evans Repeater"] = {	
            expadd = 2,
            expreq = 0,
            diff = 3000,
            hashname = "WEAPON_REPEATER_EVANS",
            jobonly = true,
            jobs = {"gunsmith"},  
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable
            materials = {
                item1 = {name = "wooden_stock",label = "Wooden Stock", amount = 1},
                item2 = {name = "bolt_carrier",label = "Bolt Carrier", amount = 1},
                item3 = {name = "rifle_barrel",label = "Rifle Barrel", amount = 1},
                item4 = {name = "coal",label = "Coal", amount = 5},
                item5 = {name = "recoil_spring",label = "Recoil Spring", amount = 1},
                item6 = {name = "firing_pin",label = "Firing Pin", amount = 1},
                item7 = {name = "rifle_receiver",label = "Rifle Receiver", amount = 1},
                                item10 = {name = "bolts",label = "Bolts", amount = 2},

            }, 
        },
    },
    ["Pistols"] = {
            ["SemiAuto Pistol "] = {	
            expadd = 2,
            expreq = 0,
            diff = 2000,
            hashname = "WEAPON_PISTOL_SEMIAUTO",   
            jobonly = true,
            jobs = {"gunsmith"},  
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable
            materials = {
                item1 = {name = "pistol_barrel",label = "Pistol Barrel", amount = 1},
                item2 = {name = "pistol_slide",label = "Pistol Slide", amount = 1},
                item3 = {name = "pistol_frame",label = "Pistol Frame", amount = 1},
                item4 = {name = "trigger_mechanism",label = "Trigger Mechanism", amount = 1},
                item5 = {name = "coal",label = "Coal", amount = 5},
                                item10 = {name = "bolts",label = "Bolts", amount = 2},
            }, 
        },
        ["Mauser Pistol "] = {	
            expadd = 2,
            expreq = 0,
            diff = 2000,
            hashname = "WEAPON_PISTOL_MAUSER",  
            jobonly = true,
            jobs = {"gunsmith"},  
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable
            materials = {
                item1 = {name = "pistol_barrel",label = "Pistol Barrel", amount = 1},
                item2 = {name = "pistol_slide",label = "Pistol Slide", amount = 1},
                item3 = {name = "pistol_frame",label = "Pistol Frame", amount = 1},
                item4 = {name = "trigger_mechanism",label = "Trigger Mechanism", amount = 1},
                item5 = {name = "coal",label = "Coal", amount = 5},
                                item10 = {name = "bolts",label = "Bolts", amount = 2},


            }, 
        },
        ["Volcanic Pistol "] = {	
            expadd = 2,
            expreq = 0,
            diff = 2000,
            hashname = "WEAPON_PISTOL_VOLCANIC",   
            jobonly = true,
            jobs = {"gunsmith"},  
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable
            materials = {
                item1 = {name = "pistol_barrel",label = "Pistol Barrel", amount = 1},
                item2 = {name = "pistol_slide",label = "Pistol Slide", amount = 1},
                item3 = {name = "pistol_frame",label = "Pistol Frame", amount = 1},
                item4 = {name = "trigger_mechanism",label = "Trigger Mechanism", amount = 1},
                item5 = {name = "coal",label = "Coal", amount = 5},
                                item10 = {name = "bolts",label = "Bolts", amount = 2},


            }, 
        },
        ["M1899 Pistol "] = {	
            expadd = 2,
            expreq = 0,
            diff = 2000,
            hashname = "WEAPON_PISTOL_M1899",  
            jobonly = true,
            jobs = {"gunsmith"},  
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable
            materials = {
                item1 = {name = "pistol_barrel",label = "Pistol Barrel", amount = 1},
                item2 = {name = "pistol_slide",label = "Pistol Slide", amount = 1},
                item3 = {name = "pistol_frame",label = "Pistol Frame", amount = 1},
                item4 = {name = "trigger_mechanism",label = "Trigger Mechanism", amount = 1},
                item5 = {name = "coal",label = "Coal", amount = 5},
                                item10 = {name = "bolts",label = "Bolts", amount = 2},

            }, 
        },
        
    }, 
    ["Revolvers"] = {
        ["Double Action Gambler"] = {	
            hashname = "WEAPON_REVOLVER_DOUBLEACTION_GAMBLER",    
            expadd = 2,
            expreq = 0,
            diff = 2500,
            jobonly = true,
            jobs = {"gunsmith"},  
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable  
            materials = {
                item1 = {name = "revolver_cylinder",label = "Revolver Cylinder", amount = 1},
                item2 = {name = "revolver_barrel",label = "Revolver Barrel", amount = 1},
                item3 = {name = "revolver_frame",label = "Revolver Frame", amount = 1},
                item4 = {name = "coal",label = "Coal", amount = 5},
                item10 = {name = "bolts",label = "Bolts", amount = 2},
            }, 
        },
        ["Mexican Cattleman"] = {	
            hashname = "WEAPON_REVOLVER_CATTLEMAN_MEXICAN",    
            expadd = 2,
            expreq = 0,
            diff = 2500,
            jobonly = true,
            jobs = {"gunsmith"},  
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable  
            materials = {
                item1 = {name = "revolver_cylinder",label = "Revolver Cylinder", amount = 1},
                item2 = {name = "revolver_barrel",label = "Revolver Barrel", amount = 1},
                item3 = {name = "revolver_frame",label = "Revolver Frame", amount = 1},
                item4 = {name = "coal",label = "Coal", amount = 5},
                item10 = {name = "bolts",label = "Bolts", amount = 2},

            }, 
        },
        ["Navy Revolver Crossover"] = {	
            hashname = "WEAPON_REVOLVER_NAVY_CROSSOVER",    
            expadd = 2,
            expreq = 0,
            diff = 2500,
            jobonly = true,
            jobs = {"gunsmith"},  
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable  
            materials = {
                item1 = {name = "revolver_cylinder",label = "Revolver Cylinder", amount = 1},
                item2 = {name = "revolver_barrel",label = "Revolver Barrel", amount = 1},
                item3 = {name = "revolver_frame",label = "Revolver Frame", amount = 1},
                item4 = {name = "coal",label = "Coal", amount = 5},
                item10 = {name = "bolts",label = "Bolts", amount = 2},

            }, 
        },
        ["Schofield Revolver"] = {	
            expadd = 2,
            expreq = 0,
            diff = 3000,
            hashname = "WEAPON_REVOLVER_SCHOFIELD",  
            jobonly = true,
            jobs = {"gunsmith"},  
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable  
            materials = {
                item1 = {name = "revolver_cylinder",label = "Revolver Cylinder", amount = 1},
                item2 = {name = "revolver_barrel",label = "Revolver Barrel", amount = 1},
                item3 = {name = "revolver_frame",label = "Revolver Frame", amount = 1},
                item4 = {name = "coal",label = "Coal", amount = 5},
                item10 = {name = "bolts",label = "Bolts", amount = 2},

            }, 
        },
        ["Lemat Revolver"] = {	
            expadd = 2,
            expreq = 0,
            diff = 3000,
            hashname = "WEAPON_REVOLVER_LEMAT",   
            jobonly = true,
            jobs = {"gunsmith"},  
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable
            materials = {
                item1 = {name = "revolver_cylinder",label = "Revolver Cylinder", amount = 1},
                item2 = {name = "revolver_barrel",label = "Revolver Barrel", amount = 1},
                item3 = {name = "revolver_frame",label = "Revolver Frame", amount = 1},
                item4 = {name = "coal",label = "Coal", amount = 5},
                item10 = {name = "bolts",label = "Bolts", amount = 2},

            }, 
        },
        ["Double Action Revolver"] = {	
            expadd = 2,
            expreq = 0,
            diff = 3000,
            hashname = "WEAPON_REVOLVER_DOUBLEACTION", 
            jobonly = true,
            jobs = {"gunsmith"},  
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable   
            materials = {
                item1 = {name = "revolver_cylinder",label = "Revolver Cylinder", amount = 1},
                item2 = {name = "revolver_barrel",label = "Revolver Barrel", amount = 1},
                item3 = {name = "revolver_frame",label = "Revolver Frame", amount = 1},
                item4 = {name = "coal",label = "Coal", amount = 5},
                item10 = {name = "bolts",label = "Bolts", amount = 2},

            }, 
        },
        ["Navy Revolver"] = {	
            expadd = 2,
            expreq = 0,
            diff = 3000,
            hashname = "WEAPON_REVOLVER_NAVY",     
            jobonly = true,
            jobs = {"gunsmith"}, 
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable
            materials = {
                item1 = {name = "revolver_cylinder",label = "Revolver Cylinder", amount = 1},
                item2 = {name = "revolver_barrel",label = "Revolver Barrel", amount = 1},
                item3 = {name = "revolver_frame",label = "Revolver Frame", amount = 1},
                item4 = {name = "coal",label = "Coal", amount = 5},
                item10 = {name = "bolts",label = "Bolts", amount = 2},

            }, 
        },
    },
    ["Throwable"] = { -- Due to vorp bug, using this weapon never runs out of ammo if u requip. 
    -- in order for throwables to work. the player must buy the throwable weapon then buy and use the related ammo box
    -- only then will the throwable show up in their weapon wheel 
        ["Bolas Hawkmoth"] = {	
            hashname = "WEAPON_THROWN_BOLAS_HAWKMOTH",    
            expadd = 1,
            expreq = 0,
            diff = 3000,
            jobonly = true,
            jobs = {"gunsmith"},   
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable
            materials = {
                item1 = {name = "iron",label = "Iron", amount = 2},
                item2 = {name = "fibers",label = "Fibers", amount = 5},
                item3 = {name = "hawkt",label = "Hawk claws", amount = 2},
            }, 
        
        },
        ["Bolas Iron-Spiked"] = {	
            hashname = "WEAPON_THROWN_BOLAS_IRONSPIKED",    
            expadd = 1,
            expreq = 0,
            diff = 3000,
            jobonly = true,
            jobs = {"gunsmith"},   
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable
            materials = {
                item1 = {name = "iron",label = "Iron", amount = 2},
                item2 = {name = "fibers",label = "Fibers", amount = 5},
                item3 = {name = "deerskin",label = "Deer skin", amount = 2},
            }, 
        
        },
        ["Bolas Intertwined"] = {	
            hashname = "WEAPON_THROWN_BOLAS_INTERTWINED",    
            expadd = 1,
            expreq = 0,
            diff = 3000,
            jobonly = true,
            jobs = {"gunsmith"},   
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable
            materials = {
                item1 = {name = "sap",label = "Sap", amount = 2},
                item2 = {name = "fibers",label = "Fibers", amount = 5},
                item3 = {name = "deerskin",label = "Deer skin", amount = 2},
            },
        
        },
        ["Tomahawk"] = {	
            expadd = 1,
            expreq = 5,
            diff = 3000,
            hashname = "WEAPON_THROWN_TOMAHAWK",  
            jobonly = true,
            jobs = {"gunsmith"},   
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable
            materials = {
                item1 = {name = "ironbar",label = "Iron Bar", amount = 3},
                item2 = {name = "hwood",label = "Hard Wood", amount = 2},
                item3 = {name = "fibers",label = "Fibers", amount = 2},
            }, 
        },
        ["Knives"] = {	
            expadd = 1,
            expreq = 0,
            diff = 3000,
            hashname = "WEAPON_THROWN_THROWING_KNIVES", 
            jobonly = true,
            jobs = {"gunsmith"},  
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable
            materials = {
                item1 = {name = "iron",label = "Iron Bar", amount = 3},
                item2 = {name = "hwood",label = "hard wood", amount = 1},
                item3 = {name = "clay",label = "Clay", amount = 1},
                item4 = {name = "coal",label = "Coal", amount = 5},
                                item10 = {name = "bolts",label = "Bolts", amount = 2},

            }, 
        },
        ["Poison Bottle"] = {	
            expadd = 1,
            expreq = 5000,
            diff = 3000,
            hashname = "WEAPON_THROWN_POISONBOTTLE", 
            jobonly = true,
            jobs = {"gunsmith"}, 
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable
            materials = {
                item1 = {name = "alcohol",label = "alcohol", amount = 3},
                item2 = {name = "glassbottle",label = "glassbottle", amount = 3},
                item3 = {name = "acid",label = "acid", amount = 3},
            }, 
        },
        ["Bolas"] = {	
            expadd = 1,
            expreq = 0,
            diff = 3000,
            hashname = "WEAPON_THROWN_BOLAS",  
            jobonly = true,
            jobs = {"gunsmith"}, 
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable
            materials = {
                item1 = {name = "deerskin",label = "deer skin", amount = 2},
                item2 = {name = "fibers",label = "Fibers", amount = 2},
                item3 = {name = "rock",label = "rock", amount = 2},
            }, 
        },
        ["Dynamite"] = {	
            expadd = 2,
            expreq = 0,
            diff = 1500,
            hashname = "WEAPON_THROWN_DYNAMITE",  
            jobonly = true,
            jobs = {"gunsmith"}, 
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable
            materials = {
                item1 = {name = "nitrite",label = "nitrite", amount = 10},
                item2 = {name = "acid",label = "Acid", amount = 10},
                item3 = {name = "dynamite",label = "dynamite", amount = 1},
                item4 = {name = "specialpelt",label = "Special Pelt", amount = 5},
                item5 = {name = "clay",label = "Clay", amount = 5},
                item6 = {name = "sap",label = "Sap", amount = 5},
                item7 = {name = "coal",label = "Coal", amount = 5},

                item8 = {name = "fibers",label = "Fibers", amount = 5},
                item9 = {name = "alcohol",label = "Alcohol", amount = 10},
                item10 = {name = "fertilizerbless",label = "Blessed Fertilizer", amount = 10},
                item11 = {name = "iron",label = "iron ore", amount = 10},
                item12 = {name = "porkfat",label = "Pork Fat", amount = 10},
                item13 = {name = "fertilizersyn",label = "Synful Fertilizer", amount = 10},
                item14 = {name = "salt",label = "Salt", amount = 10},
                
            }, 
        },
        ["Molotov"] = {	
            expadd = 2,
            expreq = 5000,
            diff = 3000,
            hashname = "WEAPON_THROWN_MOLOTOV",
            jobonly = true,
            jobs = {"gunsmith"}, 
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable
            materials = {
                item1 = {name = "alcohol",label = "alcohol", amount = 3},
                item4 = {name = "specialpelt",label = "Special Pelt", amount = 2},
                item3 = {name = "glassbottle",label = "glassbottle", amount = 3},
                item7 = {name = "coal",label = "Coal", amount = 5},
                item8 = {name = "fibers",label = "Fibers", amount = 5},
                item9 = {name = "porkfat",label = "Pork Fat", amount = 10},
                item10 = {name = "nitrite",label = "Nitrite", amount = 10},


            }, 
        },

    },
    ["Shotguns"] = {
        ["Semiauto Shotgun"] = {	
            expadd = 2,
            expreq = 0,
            diff = 2000,
            hashname = "WEAPON_SHOTGUN_SEMIAUTO",  
            jobonly = true,
            jobs = {"gunsmith"},  
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable   
            materials = {
                item1 = {name = "shotgun_wooden_stock",label = "Shotgun Wooden Stock", amount = 1},
                item2 = {name = "firing_pin",label = "Firing Pin", amount = 1},
                item3 = {name = "shotgun_barrel",label = "Shotgun Barrel", amount = 1},
                item7 = {name = "coal",label = "Coal", amount = 5},

            }, 
        },
        ["Sawedoff Shotgun"] = {	
            expadd = 2,
            expreq = 0,
            diff = 4000,
            hashname = "WEAPON_SHOTGUN_SAWEDOFF",  
            jobonly = true,
            jobs = {"gunsmith"},  
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable  
            materials = {
                item1 = {name = "shotgun_wooden_stock",label = "Shotgun Wooden Stock", amount = 1},
                item2 = {name = "firing_pin",label = "Firing Pin", amount = 1},
                item3 = {name = "shotgun_barrel",label = "Shotgun Barrel", amount = 1},
                item7 = {name = "coal",label = "Coal", amount = 5},

            }, 
        },
        ["Repeating Shotgun"] = {	
            expadd = 2,
            expreq = 0,
            diff = 3000,
            hashname = "WEAPON_SHOTGUN_REPEATING",   
            jobonly = true,
            jobs = {"gunsmith"},  
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable
            materials = {
                item1 = {name = "shotgun_wooden_stock",label = "Shotgun Wooden Stock", amount = 1},
                item2 = {name = "firing_pin",label = "Firing Pin", amount = 1},
                item3 = {name = "shotgun_barrel",label = "Shotgun Barrel", amount = 1},
                item7 = {name = "coal",label = "Coal", amount = 5},


            }, 
        },
        ["Pump Shotgun"] = {	
            expadd = 2,
            expreq = 0,
            diff = 3000,
            hashname = "WEAPON_SHOTGUN_PUMP",  
            jobonly = true,
            jobs = {"gunsmith"},  
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable
            materials = {
                item1 = {name = "shotgun_wooden_stock",label = "Shotgun Wooden Stock", amount = 1},
                item2 = {name = "firing_pin",label = "Firing Pin", amount = 1},
                item3 = {name = "shotgun_barrel",label = "Shotgun Barrel", amount = 1},
                item7 = {name = "coal",label = "Coal", amount = 5},


            }, 
        },
        ["Exotic Doublebarrel Shotgun"] = {	
            expadd = 2,
            expreq = 0,
            diff = 3000,
            hashname = "WEAPON_SHOTGUN_DOUBLEBARREL_EXOTIC",   
            jobonly = true,
            jobs = {"gunsmith"},  
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable  
            materials = {
                item1 = {name = "shotgun_wooden_stock",label = "Shotgun Wooden Stock", amount = 1},
                item2 = {name = "firing_pin",label = "Firing Pin", amount = 1},
                item3 = {name = "shotgun_barrel",label = "Shotgun Barrel", amount = 1},
                item7 = {name = "coal",label = "Coal", amount = 5},


            }, 
        },
    },
    ["Misc."] = {
        ["Metal Dectector"] = {	 
            expadd = 1,
            expreq = 0,
            diff = 2000,
            hashname = "WEAPON_KIT_METAL_DETECTOR",   
            jobonly = true,
            jobs = {"gunsmith"},   
            letcraft = false, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable
            materials = {
                item1 = {name = "iron",label = "iron", amount = 2},
                item2 = {name = "copper",label = "Copper", amount = 2},
            }, 
        },
        ["Halloween Lantern"] = {	
            expadd = 1,
            expreq = 5,
            diff = 3000,
            hashname = "WEAPON_MELEE_LANTERN_HALLOWEEN",   
            jobonly = true,
            jobs = {"gunsmith"},   
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable
            materials = {
                item1 = {name = "deerskin",label = "deerskin", amount = 2},
                item2 = {name = "specialpelt",label = "Special Pelt", amount = 1},
                item3 = {name = "ironbar",label = "Iron Bar", amount = 2},
            },  
        
        },
        ["Reinforced Lasso"] = {	
            expadd = 1,
            expreq = 0,
            diff = 3000,
            hashname = "WEAPON_LASSO_REINFORCED",   
            jobonly = true,
            jobs = {"gunsmith"},   
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable  
            materials = {
                item1 = {name = "deerskin",label = "deerskin", amount = 5},
                item2 = {name = "fibers",label = "Fibers", amount = 10},
                item3 = {name = "copper",label = "copper", amount = 5},
                item7 = {name = "coal",label = "Coal", amount = 5},

            }, 
        },
        ["Improved Binoculars"] = {	
            expadd = 1,
            expreq = 0,
            diff = 2500,
            hashname = "WEAPON_KIT_BINOCULARS_IMPROVED",  
            jobonly = true,
            jobs = {"gunsmith"},   
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable   
            materials = {
                item1 = {name = "iron",label = "Iron", amount = 5},
                item2 = {name = "copper",label = "copper", amount = 8},
                item3 = {name = "deerskin",label = "deerskin", amount = 4},
            }, 
        },
        ["Camera"] = {	
            expadd = 1,
            expreq = 0,
            diff = 3000,
            hashname = "WEAPON_KIT_CAMERA", 
            jobonly = true,
            jobs = {"gunsmith"},   
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable
            materials = {
                item1 = {name = "ironbar",label = "Iron Bar", amount = 2},
                item2 = {name = "copper",label = "Copper", amount = 2},
                item3 = {name = "lense",label = "Lense", amount = 2},
            }, 
        },
        ["Advanced Camera"] = {	
            expadd = 1,
            expreq = 0,
            diff = 2000,
            hashname = "WEAPON_kIT_CAMERA_ADVANCED",    
            jobonly = true,
            jobs = {"gunsmith"},   
            letcraft = true, -- show in crafting u can toggle this to false if you want to make this weapon sellable but not craftable 
            materials = {
                item1 = {name = "ironbar",label = "Iron Bar", amount = 5},
                item2 = {name = "copper",label = "Copper", amount = 2},
                item3 = {name = "lense",label = "lense", amount = 4},
            }, 
        },
    },
   
}