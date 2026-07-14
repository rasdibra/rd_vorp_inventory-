-- RD missing crafting items for VORP inventory
-- Fixes repeated getItemCount warnings for: pork/carrot/grain/orange.
-- Import this into your server database, then restart vorp_inventory/server.
-- Uses lowercase item names to avoid MySQL case-collation conflicts.

INSERT INTO `items`
    (`item`, `label`, `limit`, `can_remove`, `type`, `usable`, `desc`, `groupId`, `weight`, `metadata`, `degradation`, `useExpired`)
VALUES
    ('pork',   'Pork',   50, 1, 'item_standard', 0, 'Fresh pork meat used for cooking.', 1, 0.25, '{}', 0, 0),
    ('carrot', 'Carrot', 50, 1, 'item_standard', 0, 'Fresh carrot used for cooking.', 1, 0.10, '{}', 0, 0),
    ('grain',  'Grain',  50, 1, 'item_standard', 0, 'Grain used for food and crafting.', 1, 0.10, '{}', 0, 0),
    ('orange', 'Orange', 50, 1, 'item_standard', 0, 'Fresh orange used for juice and cooking.', 1, 0.10, '{}', 0, 0)
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
