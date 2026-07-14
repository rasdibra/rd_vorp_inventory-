-- RD EXTRA CONSUMABLE ITEMS EXAMPLE
-- Ky file është shembull për cas-metabolism ose script consumables.
-- Nuk ngarkohet nga vorp_inventory automatikisht.
-- Kopjo entries brenda listës së item-ave në cas-metabolism.

-- SMOKES / DUHAN
return {
{
  Name = "cigarette",
  Thirst = 0, Hunger = 0, Metabolism = 0, Stamina = 2,
  InnerCoreHealth = 0, OuterCoreHealth = 0,
  stress = { mode = "decrease", value = 50 },
  drunk  = { mode = "increase", value = 0 },
  Animation = "smoke",
  SmokeEvent = "cas-metabolism:prop:cigaret",
  GiveBackItemLabel = "", GiveBackItem = "", GiveBackItemAmount = 1
},
{
  Name = "cigar",
  Thirst = 0, Hunger = 0, Metabolism = 0, Stamina = 2,
  InnerCoreHealth = 0, OuterCoreHealth = 0,
  stress = { mode = "decrease", value = 50 },
  drunk  = { mode = "increase", value = 0 },
  Animation = "smoke",
  SmokeEvent = "cas-metabolism:prop:cigar",
  GiveBackItemLabel = "", GiveBackItem = "", GiveBackItemAmount = 1
},
{
  Name = "pipe",
  Thirst = 0, Hunger = 0, Metabolism = 0, Stamina = 2,
  InnerCoreHealth = 0, OuterCoreHealth = 0,
  stress = { mode = "decrease", value = 50 },
  drunk  = { mode = "increase", value = 0 },
  Animation = "smoke",
  SmokeEvent = "cas-metabolism:prop:pipe_smoker",
  GiveBackItemLabel = "", GiveBackItem = "", GiveBackItemAmount = 1
},
{
  Name = "pipe_smoker",
  Thirst = 0, Hunger = 0, Metabolism = 0, Stamina = 2,
  InnerCoreHealth = 0, OuterCoreHealth = 0,
  stress = { mode = "decrease", value = 0 },
  drunk  = { mode = "increase", value = 0 },
  Animation = "smoke",
  SmokeEvent = "cas-metabolism:prop:pipe_smoker",
  GiveBackItemLabel = "", GiveBackItem = "", GiveBackItemAmount = 1
},
{
  Name = "chewingtobacco",
  Thirst = 0, Hunger = 0, Metabolism = 0, Stamina = 2,
  InnerCoreHealth = 0, OuterCoreHealth = 0,
  stress = { mode = "decrease", value = 0 },
  drunk  = { mode = "increase", value = 0 },
  Animation = "chew",
  SmokeEvent = "cas-metabolism:prop:chewingtobacco",
  GiveBackItemLabel = "", GiveBackItem = "", GiveBackItemAmount = 1
},
{
  Name = "peacepipe",
  Thirst = 0, Hunger = 0, Metabolism = 0, Stamina = 2,
  InnerCoreHealth = 0, OuterCoreHealth = 0,
  stress = { mode = "decrease", value = 0 },
  drunk  = { mode = "increase", value = 0 },
  Animation = "smoke",
  SmokeEvent = "cas-metabolism:prop:pipe_smoker",
  GiveBackItemLabel = "", GiveBackItem = "", GiveBackItemAmount = 1
},
{
  Name = "cigaret",
  Thirst = 0, Hunger = 0, Metabolism = 0, Stamina = 2,
  InnerCoreHealth = 0, OuterCoreHealth = 0,
  stress = { mode = "decrease", value = 0 },
  drunk  = { mode = "increase", value = 0 },
  Animation = "smoke",
  SmokeEvent = "cas-metabolism:prop:cigaret",
  GiveBackItemLabel = "", GiveBackItem = "", GiveBackItemAmount = 1
},

-- MJEKËSI
{
  Name = "bandage_2",
  Thirst = 0, Hunger = 0, Metabolism = 0, Stamina = 50,
  InnerCoreHealth = 50, OuterCoreHealth = 50,
  PropName = "p_cs_bandage01x",
  stress = { mode = "decrease", value = 0 },
  drunk = { mode = "increase", value = 0 },
  Animation = "bandage",
  Effect = "", EffectDuration = "",
  GiveBackItemLabel = "", GiveBackItem = "", GiveBackItemAmount = 1
},
{
  Name = "syringe_2",
  Thirst = 0, Hunger = 0, Metabolism = 0, Stamina = 40,
  InnerCoreHealth = 130, OuterCoreHealth = 130,
  PropName = "mp007_p_mp_syringe01x_1",
  stress = { mode = "decrease", value = 0 },
  drunk = { mode = "increase", value = 0 },
  Animation = "syringe",
  Effect = "", EffectDuration = "",
  GiveBackItemLabel = "", GiveBackItem = "", GiveBackItemAmount = 1
},

-- GJUMI / KAMP
{
  Name = "portable_bedroll",
  Thirst = 0, Hunger = 0, Metabolism = 0, Stamina = 170,
  InnerCoreHealth = 120, OuterCoreHealth = 120,
  PropName = "p_bedrollopen01x",
  stress = { mode = "decrease", value = 150 },
  drunk = { mode = "decrease", value = 0 },
  Animation = "sleep",
  SleepReduction = 100,
  SleepDurationSeconds = 20,
  Effect = "", EffectDuration = "",
  GiveBackItemLabel = "", GiveBackItem = "", GiveBackItemAmount = 0
},
{
  Name = "sleeping_bag",
  Thirst = 0, Hunger = 0, Metabolism = 0, Stamina = 130,
  InnerCoreHealth = 90, OuterCoreHealth = 90,
  PropName = "p_bedrollopen01x",
  stress = { mode = "decrease", value = 90 },
  drunk = { mode = "decrease", value = 0 },
  Animation = "sleep",
  SleepReduction = 1000,
  SleepDurationSeconds = 15,
  Effect = "", EffectDuration = "",
  GiveBackItemLabel = "", GiveBackItem = "", GiveBackItemAmount = 0
},
}
