-- RD extra items for smoking / medical / sleep / moonshine craft categories.
-- Import this SQL after items.sql / vorp_inventory base items, then restart vorp_inventory.
-- Uses ON DUPLICATE KEY UPDATE so it is safe to run more than once.

INSERT INTO `items`
    (`item`, `label`, `limit`, `can_remove`, `type`, `usable`, `desc`, `groupId`, `weight`, `metadata`, `degradation`, `useExpired`)
VALUES
    ('cigarette', 'Cigare', 20, 1, 'item_standard', 1, 'Cigare për ulje stresi dhe animacion smoke.', 1, 0.02, '{}', 0, 0),
    ('cigaret', 'Cigaret', 20, 1, 'item_standard', 1, 'Emër alternativ për scripts që përdorin cigaret.', 1, 0.02, '{}', 0, 0),
    ('cigar', 'Puro', 20, 1, 'item_standard', 1, 'Puro për animacion smoke.', 1, 0.04, '{}', 0, 0),
    ('pipe', 'Llullë', 10, 1, 'item_standard', 1, 'Llullë druri për duhan.', 1, 0.15, '{}', 0, 0),
    ('pipe_smoker', 'Llullë me duhan', 10, 1, 'item_standard', 1, 'Llullë e përgatitur me duhan.', 1, 0.16, '{}', 0, 0),
    ('chewingtobacco', 'Duhan përtypës', 20, 1, 'item_standard', 1, 'Duhan për përtypje.', 1, 0.05, '{}', 0, 0),
    ('peacepipe', 'Peace Pipe', 10, 1, 'item_standard', 1, 'Llullë ceremoniale.', 1, 0.25, '{}', 0, 0),
    ('consumable_herb_indian_tobacco', 'Duhan Indian', 50, 1, 'item_standard', 0, 'Duhan indian për receta smoking.', 1, 0.05, '{}', 0, 0),
    ('leather', 'Lëkurë', 50, 1, 'item_standard', 0, 'Lëkurë për bedroll dhe craft.', 1, 0.20, '{}', 0, 0),
    ('bandage_2', 'Bandazh Mjekësor', 10, 1, 'item_standard', 1, 'Bandage_2 për shërim, pa konflikt me vorp_medic bandage.', 1, 0.05, '{}', 0, 0),
    ('syringe_2', 'Shiringë Mjekësore', 10, 1, 'item_standard', 1, 'Syringe_2 për shërim, pa konflikt me vorp_medic syringe.', 1, 0.08, '{}', 0, 0),
    ('portable_bedroll', 'Bedroll Portativ', 5, 1, 'item_standard', 1, 'Bedroll portativ për gjumë/pushim në kamp.', 1, 1.00, '{}', 0, 0),
    ('sleeping_bag', 'Sleeping Bag', 5, 1, 'item_standard', 1, 'Çantë gjumi për kamp.', 1, 0.80, '{}', 0, 0),
    ('still_kit', 'Komplet Moonshine', 5, 1, 'item_standard', 1, 'Hap UI-n e moonshine dhe vendos still-in.', 1, 1.00, '{}', 0, 0),
    ('still_boiler', 'Kazan Still', 10, 1, 'item_standard', 1, 'Kazani kryesor i still-it.', 1, 1.20, '{}', 0, 0),
    ('still_condenser', 'Kondensator Still', 10, 1, 'item_standard', 1, 'Pjesë kondensimi për distilim.', 1, 0.80, '{}', 0, 0),
    ('still_thumper', 'Fuçi Thumper', 10, 1, 'item_standard', 1, 'Fuçi ndihmëse për still.', 1, 1.00, '{}', 0, 0),
    ('still_worm', 'Tub Bakri', 10, 1, 'item_standard', 1, 'Tub bakri për distilim.', 1, 0.60, '{}', 0, 0),
    ('still_barrel', 'Fuçi Lisi', 10, 1, 'item_standard', 1, 'Fuçi lisi për moonshine.', 1, 1.00, '{}', 0, 0),
    ('still_repair_kit', 'Kit Riparimi Still', 10, 1, 'item_standard', 1, 'Riparon dëmtimet e still-it.', 1, 0.40, '{}', 0, 0),
    ('mash_bucket', 'Kovë Mash', 10, 1, 'item_standard', 1, 'Kovë për përzierjen e mash-it.', 1, 0.60, '{}', 0, 0)
ON DUPLICATE KEY UPDATE
    `label` = VALUES(`label`),
    `limit` = VALUES(`limit`),
    `can_remove` = VALUES(`can_remove`),
    `type` = VALUES(`type`),
    `usable` = VALUES(`usable`),
    `desc` = VALUES(`desc`),
    `groupId` = VALUES(`groupId`),
    `weight` = VALUES(`weight`),
    `metadata` = VALUES(`metadata`),
    `degradation` = VALUES(`degradation`),
    `useExpired` = VALUES(`useExpired`);
