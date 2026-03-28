#!/bin/bash
# Initialize a new world in the current repo.
# Usage: init-world.sh <world-name> [--system <system>]

set -euo pipefail

SYSTEM="Nimble"
WORLD_NAME=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --system) SYSTEM="$2"; shift 2 ;;
    -*) echo "Unknown option: $1"; exit 1 ;;
    *) WORLD_NAME="$1"; shift ;;
  esac
done

if [ -z "$WORLD_NAME" ]; then
  read -p "World name: " WORLD_NAME
fi

if [ -z "$WORLD_NAME" ]; then
  echo "Error: world name is required."
  echo "Usage: init-world.sh <world-name> [--system <system>]"
  exit 1
fi
echo "[grove] Initializing world: ${WORLD_NAME} (system: ${SYSTEM})"

# Create vault structure
echo "[grove] Creating vault structure..."
mkdir -p "vault/Compendium/World Atlas/Settlements"
mkdir -p "vault/Compendium/World Atlas/Landmarks"
mkdir -p "vault/Compendium/Factions"
mkdir -p "vault/Compendium/NPCs"
mkdir -p "vault/Compendium/History"
mkdir -p "vault/Compendium/Bestiary"
mkdir -p "vault/Adventures/One-Shots"
mkdir -p "vault/Adventures/Campaigns"
mkdir -p "vault/Sessions"
mkdir -p "vault/Players"

# Create empty starter files
cat > "vault/World Overview.md" << 'EOF'
---
tags:
  - meta
---

# World Overview

(The world will define itself as it is built.)
EOF

cat > "vault/Timeline.md" << 'EOF'
---
tags:
  - meta
---

# Timeline
EOF

cat > "vault/NPCRegistry.md" << 'EOF'
---
tags:
  - meta
---

# NPC Registry

| Name | Location | Role | Status | File |
|------|----------|------|--------|------|
EOF

cat > "vault/index.md" << EOF
---
title: ${WORLD_NAME}
---

# ${WORLD_NAME}

A world being built from the ground up.

## Explore

- [[World Overview]] — what we know so far
- [[Timeline]] — history as it's been established
- [[NPCRegistry|People]] — who lives here
EOF

cat > "vault/CHANGELOG.md" << EOF
# Changelog

## $(date '+%Y-%m-%d') — World Initialized

World created. System: ${SYSTEM}.
EOF

echo "[grove] Vault structure created."

# Initialize os-eco tools
echo "[grove] Initializing os-eco tools..."
ml init 2>/dev/null || true
sd init 2>/dev/null || true
cn init 2>/dev/null || true
ov init 2>/dev/null || true

# Create mulch domains
echo "[grove] Setting up Mulch domains..."
ml add tone --description "Emerging world tone and atmosphere" 2>/dev/null || true
ml add lore-rules --description "Established facts that constrain new content" 2>/dev/null || true
ml add anti-cliches --description "Trope blacklist and alternatives" 2>/dev/null || true
ml add writing-craft --description "Prose style, formatting, structure rules" 2>/dev/null || true
ml add obsidian --description "Obsidian vault conventions and schemas" 2>/dev/null || true
ml add ttrpg-system --description "${SYSTEM} rules, stat blocks, encounter balance" 2>/dev/null || true
ml add adventure-design --description "Narrative techniques and adventure structure" 2>/dev/null || true

# Seed anti-cliche rules
echo "[grove] Seeding anti-cliche rules..."
ml record anti-cliches --type convention \
  --description "Hard reject: dead god bodies as landscape, ancient evil awakening, chosen one prophecy, light/dark balance, advanced ancients, corrupted crystals, dark lord in tower, stock races in stock locations, visible magic corruption, amnesia plot, domain-mapped gods, trickster-Loki god, sung/dreamed creation, neat historical Ages, single defining war, too-dangerous knowledge, mysterious tavern stranger, dying mentor, monologuing villain, mysterious-only NPCs, secretly-royal orphan, monoculture nations, evil races, medieval stasis, open thieves guild, Hogwarts academy" 2>/dev/null || true

ml record anti-cliches --type convention \
  --description "Hard reject AI tendencies: everything 'ancient', purple prose (shimmering/ethereal/eldritch/ineffable/resplendent), cosmic scope creep, overwrought naming (Shadowmere/Darkhollow/Grimwatch), every NPC has dark secret, every location has dark history, 'once great now fallen', symmetrical moral frameworks, instant gravitas, emotional inflation" 2>/dev/null || true

ml record anti-cliches --type convention \
  --description "Structural cliches to avoid: every faction has exactly 3 goals and 1 secret, every NPC darker than they seem, ruins under every location, tavern as only social center, quest hooks always missing/stolen/awakening, Act 1 investigate Act 2 travel Act 3 boss fight, one threat per region, factions only in opposition" 2>/dev/null || true

ml record anti-cliches --type convention \
  --description "What to do instead: think mundane first (what do people eat, what's the boring job), conflict from competing reasonable interests not good-vs-evil, magic as infrastructure with costs and supply chains, monsters with ecological niches, messy disputed history, vary emotional register (humor pettiness mundanity), veteran DM eye-roll test" 2>/dev/null || true

# Seed Nimble TTRPG system reference
if [ "$SYSTEM" = "Nimble" ]; then
  echo "[grove] Seeding Nimble TTRPG reference..."
  ml record ttrpg-system --type reference \
    --description "Nimble TTRPG core: no AC (armor: None/M/H), no attack rolls (damage dice direct, 1=miss, max=crit exploding), 5 stats (Str/Dex/Int/Wis/Cha, no Con), 3 saves (Str/Dex/Will), 3 heroic actions per turn, advantage stacks, level replaces CR" 2>/dev/null || true

  ml record ttrpg-system --type reference \
    --description "Nimble armor: None=full damage (dice+modifier), M=dice only (modifiers ignored), H=half all damage (crits and vulnerabilities bypass). Reactions: Defend (reduce damage), Interpose (push ally take hit), opportunity attacks" 2>/dev/null || true

  ml record ttrpg-system --type reference \
    --description "Nimble stat block: summary table (Name|Lvl|Armor|HP|Speed|Str|Dex|Will|Attacks). Then: Resistances/Immunities, Vision, Languages, Special Abilities, Special Actions, Bloodied (half HP effect, Lvl 1+), Last Stand (on death, Lvl 10+). Use [!example] callout. Speed in SPACES not feet (30ft=6, 40ft=8). NEVER use feet notation." 2>/dev/null || true

  ml record ttrpg-system --type reference \
    --description "Nimble references: nimblerpg.com, solorpgstudio.com/blog/5e-to-nimble-monster-converter-guide, frank-mitchell.com/rpg/dnd5e/nimble-monsters" 2>/dev/null || true
fi

# Seed writing craft rules
echo "[grove] Seeding writing craft rules..."
ml record writing-craft --type convention \
  --description "Never use em dashes. Use commas instead. No exceptions." 2>/dev/null || true

ml record writing-craft --type convention \
  --description "All content must be scannable: headings, short paragraphs (2-4 sentences), bulleted lists, tables. No text blobs. A GM must find what they need in 5 minutes." 2>/dev/null || true

ml record writing-craft --type convention \
  --description "No purple prose: avoid shimmering, ethereal, eldritch, ineffable, resplendent. Be evocative but grounded in sensory detail." 2>/dev/null || true

# Seed obsidian conventions
echo "[grove] Seeding Obsidian conventions..."
ml record obsidian --type convention \
  --description "Always use [[wikilinks]] for internal vault references. Never use [text](path) markdown links. Link to entities (NPCs, factions, locations) whenever mentioned." 2>/dev/null || true

ml record obsidian --type convention \
  --description "Callout types: [!info] player-facing lore, [!warning]- GM Only (collapsed), [!tip] GM craft, [!quote] in-world text, [!example] stat blocks, [!note]- collapsible. Add - for collapsed default." 2>/dev/null || true

ml record obsidian --type convention \
  --description "Every file needs YAML frontmatter with at minimum: tags array and type field. Use tag hierarchy: #npc, #faction, #location, #region/[name], #status/active." 2>/dev/null || true

# Seed adventure design rules
echo "[grove] Seeding adventure design rules..."
ml record adventure-design --type convention \
  --description "Situations not plots. Define the scenario, NPCs, their goals, obstacles, ticking clock. Never script player actions or solutions. Multiple valid approaches must exist." 2>/dev/null || true

ml record adventure-design --type convention \
  --description "But/Therefore never And Then. Every beat chains through complication or consequence. Dramatic questions: every scene answers 'Will the players...?' No question = no tension." 2>/dev/null || true

ml record adventure-design --type convention \
  --description "Intention and Obstacle: define what PCs want and what blocks them. Want vs Need: NPCs have conscious goal and deeper need in tension. The best arcs pit want against need." 2>/dev/null || true

# Create seeds templates
echo "[grove] Creating Seeds templates..."
sd tpl create worldbuild --fields "implication,source_file,scope,agent" 2>/dev/null || true
sd tpl create lore-check --fields "target_area,audit_type" 2>/dev/null || true
sd tpl create adventure --fields "type,scale,hooks,locations" 2>/dev/null || true
sd tpl create npc --fields "context,location,faction,role" 2>/dev/null || true

# Create canopy prompts
echo "[grove] Creating Canopy prompts..."
cn create --name base-agent --description "Shared rules for all worldbuilding agents" --section "body=$(cat .grove/prompts/base-agent.md)" 2>/dev/null || true
cn create --name gamemaster --extends base-agent --description "Gamemaster orchestrator agent" --section "body=$(cat .grove/prompts/gamemaster.md)" 2>/dev/null || true
cn create --name lorekeeper --extends base-agent --description "Lore consistency auditor" --section "body=$(cat .grove/prompts/lorekeeper.md)" 2>/dev/null || true
cn create --name worldwriter --extends base-agent --description "Location and lore writer" --section "body=$(cat .grove/prompts/worldwriter.md)" 2>/dev/null || true
cn create --name characterwriter --extends base-agent --description "NPC and character writer" --section "body=$(cat .grove/prompts/characterwriter.md)" 2>/dev/null || true
cn create --name adventuresmith --extends base-agent --description "Playable content specialist" --section "body=$(cat .grove/prompts/adventuresmith.md)" 2>/dev/null || true
cn create --name idea-agent --extends base-agent --description "Ephemeral brainstorm agent" --section "body=$(cat .grove/prompts/idea-agent.md)" 2>/dev/null || true

echo ""
echo "[grove] World '${WORLD_NAME}' initialized."
echo ""
echo "  Start autonomous mode:  ./scripts/grove-auto.sh"
echo "  Start interactive mode: ./scripts/grove-interactive.sh"
