# Project Nebula: Antica
**Concept:** A hardcore ARPG blending Tibia's world-interaction and PoE's character complexity.

## Core Mechanics
- **Movement:** Same as POE/D2.
- **Combat:** Real-time projectile and melee logic.
- **Loot:** Randomized affixes (e.g., "+10 Fire Damage") on gear.

## Data Structures
### Item Schema
| Property | Type | Description |
| :--- | :--- | :--- |
| `id` | String | Unique identifier |
| `rarity` | Enum | Common, Rare, Artifact |
| `stats` | Object | Randomized modifiers |

## The Crafting Bench
- **Input:** Raw materials + Base item.
- **Process:** Spending "Essences" to reroll specific modifiers.
- **Risk:** 5% chance to "Corrupt" the item, locking it forever.

## Monster AI
- **Behavior:** Pathfinding toward player within 10 tiles.
- **Abilities:** Telegraphed "Slam" attacks (PoE style bosses).