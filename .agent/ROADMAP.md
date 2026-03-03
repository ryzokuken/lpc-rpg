# Development Roadmap

## Current Status

✅ **Implemented**
- Core stats system (CharacterStats, SurvivalStats)
- Time system with survival drain
- Fishing mini-game
- Liar's Dice gambling game
- Basic NPC interaction and dialogue
- Inventory system
- Crew metabolics and mutiny meter
- HUD with clock and survival vitals

---

## Phase 1: Core Ship Systems (Next)

### 1.0 Infrastructure
- [x] Web build & test workflow (`/test-web`)
- [ ] Automated survival tests

### 1.1 Ship Resource
- [ ] Create `Ship` resource class

- [ ] Hull integrity and damage
- [ ] Speed penalties from fouling
- [ ] Cargo capacity

### 1.2 Careening System
- [ ] Find "Hidden Cove" tiles
- [ ] Beach ship mini-scene
- [ ] Clean hull to restore speed

### 1.3 Ship Interior
- [ ] Complete `ship-interior.tscn`
- [ ] Zone-based areas (Deck, Hold, Galley, etc.)
- [ ] Crew stations and assignments

---

## Phase 2: Combat Systems

### 2.1 Naval Combat (Phase 1)
- [ ] Turn-based ship positioning
- [ ] Wind direction affects movement
- [ ] Ammunition types (Round, Chain, Grape shot)
- [ ] Damage to Hull/Sails/Crew

### 2.2 Boarding Combat (Phase 2)
- [ ] Trigger from ship proximity
- [ ] Grid-based tactical map on deck
- [ ] 4v4 party combat
- [ ] Morale-based victory conditions

### 2.3 Tavern Brawls
- [ ] Same system as boarding
- [ ] Non-lethal by default
- [ ] Reputation consequences

---

## Phase 3: World & Navigation

### 3.1 World Map
- [ ] Strategic sailing view
- [ ] Ship icon movement
- [ ] Wind vector system
- [ ] Point of sail mechanics

### 3.2 Fog of War & Charts
- [ ] Unexplored regions hidden
- [ ] Sea charts as lootable items
- [ ] Reveal reefs, ports, dangers

### 3.3 Ports & Wild Islands
- [ ] Port town scenes (Dock, Tavern, Market)
- [ ] Island exploration scenes
- [ ] Random encounter system

---

## Phase 4: Economy & Progression

### 4.1 Trading System
- [ ] Commodity prices by region
- [ ] Buying/selling UI
- [ ] Smuggling mechanics

### 4.2 Bounty System
- [ ] Global "Heat" from piracy
- [ ] Navy hunter spawns
- [ ] Bounty reduction methods

### 4.3 Crew Management
- [ ] Recruitment UI
- [ ] Pay distribution
- [ ] Democratic voting system
- [ ] Mutiny events

---

## Phase 5: Polish & Content

### 5.1 Additional Mini-games
- [ ] Crown & Anchor (gambling)
- [ ] Knife Game (dexterity)
- [ ] Arm Wrestling (strength)
- [ ] Drinking Contest

### 5.2 Crafting & Repair
- [ ] Repair fishing rod, weapons
- [ ] Patch sails
- [ ] Make bandages/splints
- [ ] Cooking system

### 5.3 Story Content
- [ ] Main questline (optional)
- [ ] Named NPCs and factions
- [ ] Ending scenarios (Retire, Infamy, Redemption)

---

## Technical Debt

- [ ] Stealth system (commented out in player.gd)
- [ ] Status effects system expansion
- [ ] Save/Load system
- [ ] Settings menu
- [ ] Tutorial/onboarding

---

## Open Design Questions

1. **Naval Combat**: Strategic (world map) or Tactical (grid-based)?
2. **Time Flow**: Current 1:1 minute ratio good?
3. **Starting Position**: Fresh recruit or mid-career?
4. **Story vs Sandbox**: Linear main quest needed?
5. **Combat Party Size**: 4 (simple) or 6-8 (chaotic)?
