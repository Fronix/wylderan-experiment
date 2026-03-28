# Grove: Agentic Worldbuilding System — Implementation Spec

## Overview

Grove is a TTRPG worldbuilding system that uses a swarm of AI agents to autonomously build, expand, and maintain playable game worlds. It is built on the os-eco toolkit (Overstory, Mulch, Seeds, Canopy, Sapling) with custom extensions for creative writing workflows.

The system replaces the previous AI Maestro + AMP setup with Overstory-native orchestration while preserving the proven agent roles, bottom-up worldbuilding loop, and Obsidian vault output format.

---

## Design Principles

1. **Playable over lore-rich.** Every implication followed should bring the world closer to something a GM can run at the table.
2. **Bottom-up, not top-down.** Follow implications from what exists. Never fill a predetermined template.
3. **Anti-cliche by default.** Multiple creative voices (idea swarm) + explicit trope detection prevent generic fantasy output.
4. **Spawn on demand, kill when done.** Only the Gamemaster persists. Everything else is ephemeral.
5. **Human optional.** Autonomous mode runs unattended. Interactive mode is a conversation, not a command line.

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                    Human (optional)                  │
│           Interactive mode: talks to GM              │
│           Autonomous mode: walks away                │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│              Gamemaster (persistent)                  │
│         Overstory Orchestrator agent                 │
│                                                      │
│  Responsibilities:                                   │
│  - Runs the build loop (autonomous) or               │
│    decomposes human input (interactive)               │
│  - Spawns idea agents for brainstorming              │
│  - Spawns specialist agents for execution            │
│  - Curates ideas, manages state, commits results     │
│  - Tracks vault state, triggers audits/synthesis     │
│                                                      │
│  Tools: ov sling, sd (seeds), ml prime,              │
│         vault-context (custom), idea-swarm (custom)  │
└──┬───────┬───────┬───────┬───────┬──────────────────┘
   │       │       │       │       │
   ▼       ▼       ▼       ▼       ▼
┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌──────────┐
│Idea │ │Lore │ │World│ │Char │ │Adventure │
│Swarm│ │keep │ │write│ │write│ │smith     │
│(N)  │ │     │ │     │ │     │ │          │
└──┬──┘ └──┬──┘ └──┬──┘ └──┬──┘ └────┬─────┘
   │       │       │       │         │
   ▼       ▼       ▼       ▼         ▼
 Ideas   Audit   Files    NPCs    Adventures
 (text)  Report  Written  Written  Written
```

### Agent Lifecycle

| Agent | Persistence | Spawned by | Runtime |
|-------|-------------|------------|---------|
| Gamemaster | Persistent (Overstory orchestrator) | Human via `ov orchestrator start` | Claude Code |
| Idea Agent (x2-4) | Ephemeral (minutes) | Gamemaster | Sapling with creative-lens prompt |
| Lorekeeper | Ephemeral (per-task) | Gamemaster via `ov sling` | Sapling with lorekeeper prompt |
| Worldwriter | Ephemeral (per-task) | Gamemaster via `ov sling` | Sapling with worldwriter prompt |
| Characterwriter | Ephemeral (per-task) | Gamemaster via `ov sling` | Sapling with characterwriter prompt |
| Adventuresmith | Ephemeral (per-task) | Gamemaster via `ov sling` | Sapling with adventuresmith prompt |

---

## os-eco Tool Usage

### Overstory — Orchestration

The Gamemaster runs as the Overstory orchestrator. It uses `ov sling` to spawn specialist agents and `ov mail` for coordination.

**Key configuration:**

```yaml
# .overstory/config.yaml
runtime: sapling              # Use Sapling as the agent runtime
worktree_strategy: shared     # Agents share the vault (no isolation)
                              # OR: branch-per-agent with auto-merge
```

**Worktree strategy decision:**

The existing system has all agents working on the same filesystem. Overstory's default is isolated worktrees. We have two options:

- **Option A: Shared worktree** — All agents work on the same branch. Simpler, matches current behavior. Risk: file conflicts if two writers touch the same file.
- **Option B: Branch-per-agent with merge** — Each spawned agent gets a branch. Gamemaster merges via `ov merge` after task completion. Safer, but more complex.

**Recommendation: Option B.** Writers should never touch the same file in the same batch (the Gamemaster already enforces this), and `ov merge` handles the merge-back. This also gives us free rollback if a writer produces bad output — just don't merge.

**Agent capabilities mapping:**

| Overstory capability | Our agent |
|---------------------|-----------|
| `builder` | Worldwriter, Characterwriter, Adventuresmith |
| `scout` | (unused) |
| `reviewer` | Lorekeeper |
| `lead` | Gamemaster (orchestrator, not slung) |

We use `--spec` files to differentiate between builder subtypes rather than adding new capability types.

### Mulch — Expertise & Conventions

Stores worldbuilding rules, not code patterns. Agents load relevant domains at startup via `ml prime`.

**Domains:**

| Domain | Contents | Used by |
|--------|----------|---------|
| `tone` | Emerging world tone, atmosphere descriptors, what the world "feels like" | All agents |
| `lore-rules` | Established facts that constrain new content (e.g., "magic returned 40 years ago", "no living gods") | Lorekeeper, Worldwriter, Characterwriter |
| `anti-cliches` | Explicit trope blacklist with examples of what to avoid and what to do instead | Idea agents, Lorekeeper |
| `writing-craft` | Prose style rules: no em-dashes, scannable structure, Obsidian formatting, no purple prose | Worldwriter, Characterwriter, Adventuresmith |
| `obsidian` | Wikilink conventions, frontmatter schemas, callout syntax, tag hierarchy | Worldwriter, Characterwriter, Adventuresmith |
| `ttrpg-system` | Game system rules, stat block format, encounter balance. Defaults to Nimble TTRPG (seeded on init) | Characterwriter, Adventuresmith |
| `adventure-design` | Narrative techniques (but/therefore, dramatic questions, situations not plots), structure templates | Adventuresmith, Gamemaster |

**Recording new expertise:**

The Gamemaster records new expertise after each tone synthesis:
```bash
ml record tone --type convention \
  --description "World feels hopeful but fragile — communities rebuilding, practical survival"
```

The Lorekeeper records lore rules when new constraints are established:
```bash
ml record lore-rules --type convention \
  --description "The river is tidal — salt water reaches 20 miles inland"
```

### Seeds — Internal Task Queue

The Gamemaster creates and manages seeds. The human never touches these directly.

**Task templates:**

```bash
sd tpl create worldbuild --fields "implication,source_file,scope,agent"
sd tpl create lore-check --fields "target_area,audit_type"
sd tpl create adventure --fields "type,scale,hooks,locations"
sd tpl create npc --fields "context,location,faction,role"
```

**Example usage in the build loop:**

```bash
# Discovery — GM finds implications
sd create --tpl worldbuild \
  --title "Flesh out the river merchant guild" \
  --implication "Town trades grain via river merchants — who are they?" \
  --source_file "vault/Compendium/World Atlas/Settlements/ExampleTown.md" \
  --scope "faction file + 2-3 NPCs" \
  --agent "worldwriter"

# Build — GM slings the task
ov sling seed-a1b2 --capability builder --spec .canopy/specs/worldwriter.yaml

# Agent completes, GM closes
sd close seed-a1b2
```

**Dependency tracking for build order:**

```bash
sd create --title "Create River Merchants Guild faction file" --id guild-file
sd create --title "Create guild master NPC" --id guild-npc
sd dep add guild-npc --blocked-by guild-file
# guild-npc won't show in `sd ready` until guild-file is closed
```

### Canopy — Prompt Management

Agent role definitions move from raw `.md` files into Canopy-managed prompts with versioning and composition.

**Prompt hierarchy:**

```
base-agent (shared rules: Obsidian format, no em-dashes, wikilinks, vault structure)
├── gamemaster (extends base-agent)
├── lorekeeper (extends base-agent)
├── worldwriter (extends base-agent)
├── characterwriter (extends base-agent)
├── adventuresmith (extends base-agent)
└── idea-agent (extends base-agent, minimal — just creative lens)
```

**Canopy inheritance** means shared rules live in `base-agent` and are automatically included when rendering any child prompt. Changes to formatting rules propagate to all agents.

**World-specific overrides:**

Each repo is one world. The Canopy profile injects world-specific context:

```bash
cn create world --parent base-agent \
  --body "World: [name]. System: Nimble. Vault path: vault/"

cn render worldwriter --profile world
# → base-agent rules + worldwriter role + world context
```

One repo = one world. The prompts are portable to new repos via Canopy export/import.

### Sapling — Headless Writing Agent

Sapling is the runtime for all ephemeral agents. It's a coding agent by default, but with `--system-prompt-file` we inject writing-focused prompts.

**How agents are spawned:**

```bash
# Overstory calls this internally when you `ov sling`
sp run --system-prompt-file .canopy/rendered/worldwriter.md \
       --max-turns 50 \
       --guards-file .grove/guards/anti-cliche.json \
       --cwd . \
       "Create the river landmark file. Context: [vault context here]"
```

**Guards file for agent sandboxing:**

Sapling's guards system operates on tool call inputs (not output content), so we use it for sandboxing rather than trope detection. Anti-cliche enforcement is handled by Mulch expertise loaded into agent prompts (`ml prime anti-cliches`) and the Lorekeeper's post-hoc review.

```json
{
  "version": "1",
  "rules": [],
  "pathBoundary": "vault/",
  "readOnly": false
}
```

**Per-agent guards:**

| Agent | Guards |
|-------|--------|
| Lorekeeper | `readOnly: true` — can read the vault but never modify files |
| Worldwriter | `pathBoundary` scoped to vault — can only write within the world's vault |
| Characterwriter | `pathBoundary` scoped to vault — can only write within the world's vault |
| Adventuresmith | `pathBoundary` scoped to vault — can only write within the world's vault |
| Idea agents | `readOnly: true` — brainstorm only, no file access needed |

**Anti-cliche enforcement is layered:**

1. **At ideation** — Idea agents get the anti-cliche list via `ml prime anti-cliches` in their prompt. Creative lenses push away from tropes at the source.
2. **At curation** — The Gamemaster filters brainstorm results against the anti-cliche list before selecting a direction.
3. **At review** — The Lorekeeper checks new content for tropes during lore audits.

---

## Custom Components (What We Build)

### 1. Idea Swarm (`scripts/idea-swarm.sh`)

A script the Gamemaster calls to spawn parallel idea agents, collect their responses, and present them for curation.

**Behavior:**

1. Takes a prompt (the implication/question to brainstorm)
2. Spawns 2-4 Sapling instances in parallel, each with a different creative lens
3. Collects all responses
4. Returns them to the Gamemaster as a structured list

**Creative lenses (injected per-agent):**

| Lens | System prompt addition |
|------|----------------------|
| Pragmatist | "Think about how ordinary people would actually deal with this. What are the practical, economic, and social consequences? Avoid cosmic or magical explanations when mundane ones work." |
| Weird | "Find the angle nobody would expect. What if the obvious assumption is wrong? What if the cause and effect are reversed? Push past the first three ideas — they're probably cliche." |
| Local | "Think from the perspective of someone who lives here. What do they see, fear, want? What rumors do they tell? What do they take for granted that an outsider would find strange?" |
| Player | "Think about what would be fun to interact with at the table. What creates choices, dilemmas, and moments players would talk about after the session? What makes this gameable, not just readable?" |

**Implementation:**

```bash
#!/bin/bash
# scripts/idea-swarm.sh
# Usage: idea-swarm.sh <prompt> [num_agents]

PROMPT="$1"
NUM_AGENTS="${2:-3}"

LENSES=("pragmatist" "weird" "local" "player")
RESULTS_DIR=$(mktemp -d)

# Spawn agents in parallel
for i in $(seq 0 $((NUM_AGENTS - 1))); do
  LENS=${LENSES[$i]}
  sp run \
    --system-prompt-file ".canopy/rendered/idea-agent-${LENS}.md" \
    --max-turns 3 \
    --backend cc \
    --quiet \
    "$PROMPT" \
    > "${RESULTS_DIR}/idea-${LENS}.md" &
done

wait

# Combine results
echo "# Brainstorm Results"
echo ""
for f in "${RESULTS_DIR}"/idea-*.md; do
  LENS=$(basename "$f" .md | sed 's/idea-//')
  echo "## ${LENS^} Lens"
  cat "$f"
  echo ""
done

rm -rf "$RESULTS_DIR"
```

The Gamemaster calls this, reads the output, selects/combines/rejects ideas, then proceeds to planning.

**Token efficiency:** Each idea agent runs max 3 turns with a tiny system prompt. Total cost per brainstorm: ~4-12k tokens across all agents. Cheap enough to run on every implication.

### 2. Vault Context Assembler (`scripts/vault-context.sh`)

Given a topic, location, or entity name, assembles relevant vault files into a context block that can be injected into an agent's prompt.

**Behavior:**

1. Takes a search query and world name
2. Greps the vault for relevant files
3. Reads and concatenates them (with file path headers)
4. Truncates to a token budget
5. Returns the assembled context

**Implementation:**

```bash
#!/bin/bash
# scripts/vault-context.sh
# Usage: vault-context.sh <query> [max_lines]

QUERY="$1"
MAX_LINES="${2:-500}"
VAULT_PATH="vault"

# Find relevant files
FILES=$(grep -rl "$QUERY" "$VAULT_PATH" --include="*.md" 2>/dev/null | head -10)

# Also check for wikilink references
WIKILINK_FILES=$(grep -rl "\[\[.*${QUERY}.*\]\]" "$VAULT_PATH" --include="*.md" 2>/dev/null | head -5)

# Deduplicate
ALL_FILES=$(echo -e "${FILES}\n${WIKILINK_FILES}" | sort -u)

# Always include core context files
CORE_FILES="${VAULT_PATH}/World Overview.md ${VAULT_PATH}/Timeline.md"

echo "# Vault Context for: ${QUERY}"
echo ""

# Core files first (abbreviated)
for f in $CORE_FILES; do
  if [ -f "$f" ]; then
    echo "## $(basename "$f")"
    head -30 "$f"
    echo "..."
    echo ""
  fi
done

# Relevant files
LINE_COUNT=0
for f in $ALL_FILES; do
  if [ $LINE_COUNT -ge $MAX_LINES ]; then
    echo "(context truncated at ${MAX_LINES} lines)"
    break
  fi
  echo "## $(basename "$f") ($(echo "$f" | sed "s|${VAULT_PATH}/||"))"
  CONTENT=$(cat "$f")
  echo "$CONTENT"
  echo ""
  LINE_COUNT=$((LINE_COUNT + $(echo "$CONTENT" | wc -l)))
done
```

**Usage by the Gamemaster:**

```bash
# Before delegating a task to a writer
CONTEXT=$(scripts/vault-context.sh "river merchants" 400)
ov sling seed-a1b2 --spec .grove/specs/worldwriter.yaml \
  --prompt "Create the river landmark. Context:\n${CONTEXT}"
```

### 3. Anti-Cliche Trope List (`.grove/anti-cliches.md`)

A living document loaded into Mulch and referenced by the Lorekeeper and idea agents.

**Initial content:**

```markdown
# Anti-Cliche Rules

## How To Use This List

These rules exist because AI defaults to the most common patterns in its
training data. The result is worlds that feel like a composite of every
fantasy wiki ever written. These rules force divergence.

The Lorekeeper checks against this list during audits. The idea agents
load it via `ml prime anti-cliches`. The Gamemaster references it when
curating brainstorm results.

---

## Hard Rejections (never use these)

### Cosmology & Divine
- Dead god bodies forming/becoming the landscape
- "Balance between light and dark" as cosmic framework
- Gods that map neatly to domains (god of war, god of death, god of the sea)
- A "trickster god" who is suspiciously Loki
- Cosmic evil that corrupts through proximity (corrupted crystals, dark energy, tainted wells)
- The world was "sung into existence" or "dreamed by a god"

### History & Lore
- Ancient evil awakening from slumber
- Mysterious ancient civilization more advanced than the current one
- A "great cataclysm" that conveniently explains why everything is ruins
- History divided into neat Ages (Age of Gods, Age of Man, Age of Shadow)
- A single war that defined everything ("The Sundering", "The Shattering", "The Breaking")
- Lost knowledge that is "too dangerous to be known"

### Characters & Prophecy
- Chosen one prophecy
- Amnesia as plot device
- The mysterious stranger who appears in a tavern with a quest
- The wise mentor who dies to motivate the heroes
- The villain who monologues their plan
- NPCs whose only personality is "mysterious"
- The secretly-royal orphan

### Worldbuilding Patterns
- Dark lord in a dark tower
- Elves in forests, dwarves in mountains, orcs in wastelands (without subversion)
- Monoculture nations (all desert people are nomads, all northerners are vikings)
- Evil races (an entire species is inherently evil)
- Medieval stasis (thousands of years of history but no technological progress)
- Magic corruption that turns people visibly evil (dark veins, glowing eyes, pale skin)
- "The old ways are fading" without specific mechanical consequence
- A thieves' guild that somehow operates openly
- A magic academy that is basically Hogwarts

### AI-Specific Tendencies (patterns LLMs default to)
- Everything is "ancient" (ancient ruins, ancient evil, ancient knowledge, ancient order)
- Purple prose (shimmering, ethereal, eldritch, ineffable, resplendent)
- Cosmic scope creep (a simple trade dispute becomes a world-ending threat)
- Overwrought naming (Shadowmere, Darkhollow, Grimwatch, Dreadspire, Ashenmoor)
- Every NPC has a "dark secret" or "hidden pain"
- Every location has a "dark history"
- Describing everything as "once great, now fallen"
- Symmetrical moral frameworks (for every light force there's a dark mirror)
- Instant gravitas (new locations described as if they've been important for millennia)
- Emotional inflation (every event is world-shaking, every loss is devastating)

---

## Soft Warnings (question these, sometimes okay with subversion)

- Prophecy (okay if wrong, ambiguous, manipulated, or a political tool)
- Undead (okay if they have agency, economic logic, or aren't just "evil army")
- Dragon hoards (okay if there's an economic or biological reason for hoarding)
- Ancient ruins with still-working magic (okay if someone maintains them or there's a reason)
- Forbidden knowledge (okay if the "forbidden" part is political, not cosmic)
- A resistance/rebellion against an empire (okay if both sides have legitimate grievances)
- Elemental magic system (okay if it has economic/social consequences, not just combat applications)
- Haunted locations (okay if the haunting has a specific, non-generic cause)
- A sealed evil (okay if the seal is failing for mundane reasons, like neglect or politics)
- Cursed bloodlines (okay if the "curse" is social/political, not magical)

---

## Structural Cliches (how content is organized, not what it contains)

These are patterns in how agents structure information, not world content:

- Every faction has exactly 3 goals and 1 secret
- Every NPC has a "what they seem" vs "what they really are" that's always darker
- Every location has ancient ruins underneath it
- Every settlement has a tavern as the social center
- Quest hooks that all follow "someone is missing / something was stolen / something is awakening"
- Adventures where Act 1 is investigation, Act 2 is travel, Act 3 is a boss fight
- Every region has exactly one dominant threat
- Factions that exist only in opposition to each other (rebels vs empire, order vs chaos)

---

## What To Do Instead

### Think mundane first
- What do people eat? How do they travel? What do they argue about at dinner?
- What's the most boring job in this town and why does someone still do it?
- What would a census-taker write about this place?

### Build conflict from competing reasonable interests
- Both sides should be partially right
- The best conflicts are between two goods or two necessities, not good vs evil
- Ask: "Could a player reasonably side with either faction?"

### Make magic feel like infrastructure
- Magic should have costs, logistics, supply chains, and labor disputes
- A healing potion requires ingredients someone has to harvest
- If teleportation exists, what happened to the road-building industry?

### Give monsters ecological niches
- What does it eat? Where does it sleep? How does it reproduce?
- Predators that aren't evil, they're just predators
- Monsters that are more pest than threat (rat-sized problems, not dragon-sized ones)

### Make history messy
- Multiple contradictory accounts of the same event
- "Historical fact" that is actually propaganda from the winning side
- Events that seemed important at the time but turned out not to matter
- Events nobody noticed at the time that changed everything

### Vary the emotional register
- Not everything is grim. Not everything is epic.
- Include boredom, pettiness, humor, mundane frustration
- A world where people laugh, complain about the weather, and have opinions about bread

### The Veteran DM Test
- Before accepting any idea, ask: "Would a veteran DM roll their eyes at this?"
- If the answer is "probably", rethink it
- If the answer is "they've seen it a hundred times", definitely rethink it
```

### 4. World Initialization Script (`scripts/init-world.sh`)

Sets up a new world in the current repo. Optionally accepts `--system` to override the default TTRPG system (Nimble).

```
$ ./scripts/init-world.sh
$ ./scripts/init-world.sh --system "D&D 5e"
```

Tone, themes, and everything else emerges from what the agents build. The init script creates a blank vault, wires up the os-eco tools, and seeds the TTRPG system reference into Mulch.

```bash
#!/bin/bash
# scripts/init-world.sh
# Usage: init-world.sh [--system <system>]

SYSTEM="Nimble"

# Parse optional flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    --system) SYSTEM="$2"; shift 2 ;;
    *) shift ;;
  esac
done

WORLD_NAME=$(basename "$(pwd)")
echo "Initializing world: ${WORLD_NAME}"

# Create vault structure
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
cat > "vault/World Overview.md" << EOF
---
tags:
  - meta
---

# World Overview

(The world will define itself as it is built.)
EOF

cat > "vault/Timeline.md" << EOF
---
tags:
  - meta
---

# Timeline
EOF

cat > "vault/NPCRegistry.md" << EOF
---
tags:
  - meta
---

# NPC Registry

| Name | Location | Role | Status | File |
|------|----------|------|--------|------|
EOF

cat > "vault/CHANGELOG.md" << EOF
# Changelog
EOF

# Initialize os-eco tools (idempotent)
ml init 2>/dev/null || true
sd init 2>/dev/null || true
cn init 2>/dev/null || true
ov init 2>/dev/null || true

# Create mulch domains
ml add tone --description "Emerging world tone and atmosphere"
ml add lore-rules --description "Established facts that constrain new content"
ml add anti-cliches --description "Trope blacklist and alternatives"
ml add writing-craft --description "Prose style, formatting, structure rules"
ml add obsidian --description "Obsidian vault conventions and schemas"
ml add ttrpg-system --description "${SYSTEM} rules, stat blocks, encounter balance"
ml add adventure-design --description "Narrative techniques and adventure structure"

# Seed TTRPG system reference
if [ "$SYSTEM" = "Nimble" ]; then
  ml record ttrpg-system --type reference \
    --description "Nimble TTRPG core rules — no AC (armor categories: None/M/H), no attack rolls (damage dice direct, 1=miss, max=crit), 5 stats (Str/Dex/Int/Wis/Cha, no Con), 3 saves (Str/Dex/Will), 3 heroic actions per turn, speed in spaces not feet"
  ml record ttrpg-system --type reference \
    --description "Nimble armor: None=full damage, M=dice only (no modifier), H=half all damage (crits/vulnerabilities bypass). Advantage stacks. Level replaces CR."
  ml record ttrpg-system --type reference \
    --description "Nimble stat block format: summary table (Name|Lvl|Armor|HP|Speed|Str|Dex|Will|Attacks), then Resistances/Immunities, Vision, Languages, Special Abilities, Special Actions, Bloodied (half HP, Lvl 1+), Last Stand (on death, Lvl 10+)"
  ml record ttrpg-system --type reference \
    --description "Nimble stat block callout: use [!example] Stat Block (Nimble). Speed in spaces (30ft=6, 40ft=8). NEVER use feet. Reactions: Defend (reduce damage), Interpose (push ally, take hit), opportunity attacks"
  ml record ttrpg-system --type reference \
    --description "Nimble references: nimblerpg.com, solorpgstudio.com/blog/5e-to-nimble-monster-converter-guide, frank-mitchell.com/rpg/dnd5e/nimble-monsters"
fi

# Create seeds templates
sd tpl create worldbuild --fields "implication,source_file,scope,agent"
sd tpl create lore-check --fields "target_area,audit_type"
sd tpl create adventure --fields "type,scale,hooks,locations"
sd tpl create npc --fields "context,location,faction,role"

# Create canopy prompts (if not already created)
cn create base-agent --body "$(cat .grove/prompts/base-agent.md)" 2>/dev/null || true
cn create gamemaster --parent base-agent --body "$(cat .grove/prompts/gamemaster.md)" 2>/dev/null || true
cn create lorekeeper --parent base-agent --body "$(cat .grove/prompts/lorekeeper.md)" 2>/dev/null || true
cn create worldwriter --parent base-agent --body "$(cat .grove/prompts/worldwriter.md)" 2>/dev/null || true
cn create characterwriter --parent base-agent --body "$(cat .grove/prompts/characterwriter.md)" 2>/dev/null || true
cn create adventuresmith --parent base-agent --body "$(cat .grove/prompts/adventuresmith.md)" 2>/dev/null || true
cn create idea-agent --parent base-agent --body "$(cat .grove/prompts/idea-agent.md)" 2>/dev/null || true

# Create canopy profile for this world
cn create "world" --body "World: ${WORLD_NAME}. System: ${SYSTEM}. Vault path: vault/" 2>/dev/null || true

echo ""
echo "World '${WORLD_NAME}' initialized."
echo "Start autonomous mode:  ./scripts/grove-auto.sh"
echo "Start interactive mode: ./scripts/grove-interactive.sh"
```

### 5. Interactive Mode Wrapper (`scripts/grove-interactive.sh`)

A thin wrapper that starts the Gamemaster in interactive mode — the human talks, the GM decomposes and delegates.

```bash
#!/bin/bash
# scripts/grove-interactive.sh

# Render the interactive gamemaster prompt
PROMPT=$(cn render gamemaster --profile world 2>/dev/null)

# Add interactive mode preamble
INTERACTIVE_PREAMBLE="
## Mode: Interactive

You are in INTERACTIVE mode. The human is your creative director.

**How this works:**
1. The human describes what they want — a region feel, an NPC concept, a plot thread, a correction, anything
2. You decompose their input into concrete tasks
3. You create seeds for each task
4. You sling agents to execute them
5. You report results back to the human
6. You suggest follow-up threads the human might want to explore

**Rules:**
- Never ask the human to run commands or create seeds themselves
- Translate vague creative direction into specific worldbuilding tasks
- Push back if the human's idea contradicts established lore (check with Lorekeeper first)
- Suggest alternatives when an idea feels tropey (reference anti-cliche list)
- Show the human what was built after each task completes — file paths and a brief summary
- The human can say 'go autonomous' at any time to switch to autonomous mode
"

# Start orchestrator with interactive prompt
ov orchestrator start \
  --system-prompt "${PROMPT}\n\n${INTERACTIVE_PREAMBLE}"
```

### 6. Autonomous Mode Launcher (`scripts/grove-auto.sh`)

Starts the Gamemaster in autonomous mode — the build loop from the existing system, adapted for Overstory.

```bash
#!/bin/bash
# scripts/grove-auto.sh

PROMPT=$(cn render gamemaster --profile world 2>/dev/null)

AUTO_PREAMBLE="
## Mode: Autonomous

You are in AUTONOMOUS mode. Build the world without human input.

**Continuous flow (repeat until stopped):**

1. **Discover** — Read the vault. Find an implication. Pick one thread.
2. **Brainstorm** — Run idea-swarm.sh with the implication. Read the ideas. Curate.
3. **Lore check** — Sling a Lorekeeper to verify the selected idea doesn't contradict existing lore or hit anti-cliche rules.
4. **Plan** — Decompose into seeds with dependencies. Determine which agents to sling.
5. **Build** — Sling agents. Wait for completion via ov mail. Verify output.
6. **Merge** — Use ov merge to bring agent branches into main.
7. **Commit** — Stage, commit, push. Update CHANGELOG.
8. **Next** — Find the next implication. Keep going.

**Triggers (based on vault state, not counters):**
- **Lore audit** — When 5+ new files have been committed since the last audit, sling a Lorekeeper for a full consistency check before continuing.
- **Tone synthesis** — When 3+ new regions or factions exist since the last synthesis, update World Overview with what's emerged.
- **Adventure creation** — When enough playable material has accumulated (multiple locations, NPCs, faction tensions), sling an Adventuresmith.
- **Commit** — After every completed implication (natural boundary). Each commit should leave the vault consistent.

**Token awareness:**
- Check your context usage. If you're above 60% capacity, compact before continuing.
- Prefer short, focused agent tasks over long complex ones.
- The idea swarm is cheap (3 turns per agent). Use it freely.
- Vault context assembly keeps context focused — don't read the entire vault.
"

ov orchestrator start \
  --system-prompt "${PROMPT}\n\n${AUTO_PREAMBLE}"
```

---

## File Structure

```
worldbuilding-agents/
├── .canopy/                    # Canopy prompt storage (git-tracked)
│   └── prompts/
│       ├── base-agent.md       # Shared rules (Obsidian, formatting, vault structure)
│       ├── gamemaster.md       # GM role + build loop
│       ├── lorekeeper.md       # Consistency guardian
│       ├── worldwriter.md      # Place builder
│       ├── characterwriter.md  # NPC builder
│       ├── adventuresmith.md   # Playable content builder (NEW)
│       └── idea-agent.md       # Minimal creative brainstorm agent
├── .grove/                     # Grove-specific config
│   ├── anti-cliches.md         # Trope blacklist
│   ├── guards/
│   │   ├── reader.json         # Read-only guard (Lorekeeper, idea agents)
│   │   └── writer.json         # Path-bounded guard (writers, adventuresmith)
│   ├── lenses/                 # Creative lens definitions for idea agents
│   │   ├── pragmatist.md
│   │   ├── weird.md
│   │   ├── local.md
│   │   └── player.md
│   └── specs/                  # Overstory task specs per agent type
│       ├── worldwriter.yaml
│       ├── characterwriter.yaml
│       ├── lorekeeper.yaml
│       └── adventuresmith.yaml
├── .mulch/                     # Mulch expertise storage (git-tracked)
├── .seeds/                     # Seeds task storage (git-tracked)
├── .overstory/                 # Overstory config and runtime state
├── scripts/
│   ├── init-world.sh           # Initialize a new world
│   ├── idea-swarm.sh           # Spawn parallel idea agents
│   ├── vault-context.sh        # Assemble relevant vault context
│   ├── grove-interactive.sh    # Start interactive mode
│   └── grove-auto.sh           # Start autonomous mode
└── vault/                      # Obsidian vault (the actual world content)
    ├── World Overview.md
            ├── Timeline.md
            ├── NPCRegistry.md
            ├── CHANGELOG.md
            ├── Compendium/
            │   ├── World Atlas/
            │   ├── Factions/
            │   ├── NPCs/
            │   ├── History/
            │   └── Bestiary/
            ├── Adventures/
            │   ├── One-Shots/
            │   └── Campaigns/
            ├── Sessions/
            └── Players/
```

---

## Autonomous Mode: Walkthrough

```
Gamemaster reads vault. 7 commits so far, 14 files in the vault.

DISCOVER
  GM reads CHANGELOG, recent files, World Overview.
  Finds: "The town exports grain via river merchants" — but no river detailed.
  Implication: there's a river system, merchants, and destinations.

BRAINSTORM
  GM runs: scripts/idea-swarm.sh "The town trades grain via river merchants.
    What is the river like? Who are the merchants? Where does the grain go?"

  Pragmatist: "The river is shallow and seasonal. Merchants use flat-bottomed
    barges. Grain goes to a larger town downstream that can't grow its own
    due to poor soil from old mining runoff."
  Weird: "The river flows backwards once a month during the tidal bore.
    Merchants time their trips around it. Some say cargo sent during the
    bore arrives... different."
  Local: "River merchants are a tight-knit family network, not a guild.
    They intermarry between river towns. An outsider trying to trade on
    the river would face social barriers, not legal ones."
  Player: "The river is a natural adventure corridor. Travel encounters,
    a mystery at a river town, maybe a blockade or toll dispute.
    Give it 3-4 points of interest along its length."

LORE CHECK
  GM combines: family network (not guild), seasonal shallow river,
    downstream mining town with poor soil, 3-4 points of interest.
  Slings Lorekeeper: "Check if any of this contradicts existing vault."
  Lorekeeper returns: "No conflicts. Note: existing NPC mentions
    'river folk' in passing — this connects."

PLAN
  GM creates seeds:
  - seed-01: River landmark file (Worldwriter)
  - seed-02: Downstream town settlement file (Worldwriter)
  - seed-03: River merchant family head NPC (Characterwriter)
  - seed-04: Update existing NPC to reference merchant family (Characterwriter)
  - seed-02 blocked-by seed-01 (need river before downstream town)
  - seed-03 blocked-by seed-01 (need river before river merchant)

BUILD
  GM slings Worldwriter for seed-01.
  Worldwriter completes → GM closes seed-01.
  Now seed-02 and seed-03 are unblocked.
  GM slings Worldwriter for seed-02 AND Characterwriter for seed-03 in parallel.
  Both complete → GM slings Characterwriter for seed-04.
  All done.

MERGE & COMMIT
  ov merge worldwriter-seed01
  ov merge worldwriter-seed02
  ov merge characterwriter-seed03
  ov merge characterwriter-seed04
  git add -A
  git commit -m "grove: grain trade implication → river system"
  git push
  Update CHANGELOG.

TRIGGER CHECK
  - 6 new files since last audit (river, downstream town, 3 NPCs,
    faction stub) → threshold is 5 → triggers lore audit
  - GM slings Lorekeeper for a full consistency check on recent content
  - Lorekeeper reports back, GM fixes any issues, commits fixes

  - Only 1 region exists → tone synthesis not triggered yet
  - No adventure trigger yet (need more locations + NPC depth)

NEXT
  New threads discovered: downstream town's mining history, tidal bore
    phenomenon, merchant family politics.
  GM picks the most interesting one. Keeps going.
```

---

## Interactive Mode: Conversation Example

```
Human: "I want a faction that controls information, but not in the
  typical 'shadow guild of spies' way."

Gamemaster (internally):
  → Runs idea-swarm with this prompt
  → Gets 3 ideas back:

  Pragmatist: "A postal service. They carry messages between towns and
    have a monopoly on reliable long-distance communication. Their power
    is logistical, not covert."
  Weird: "A group of people who memorize and recite the news. No written
    records — they ARE the records. Towns pay them to remember, and
    sometimes to forget."
  Local: "The ferry operators. They connect river towns and control who
    crosses. Information flows through their boats because travelers talk.
    They don't spy — they just listen."

Gamemaster (to human):
  "Three directions for an information faction:

  1. **Postal monopoly** — logistical power, not covert. They deliver
     messages and their leverage is that nobody else can.
  2. **Living records** — oral historians who ARE the archives. Towns
     pay them to remember. Power comes from being irreplaceable.
  3. **Ferry network** — control information passively through
     controlling transit. They don't spy, they're just always there
     when people talk.

  Any of these grab you? I can combine or push further."

---

## The Adventuresmith Agent (New)

This is the new agent that does not exist in the current system. It takes over the playable content responsibility that was previously buried in the Gamemaster's role.

**Responsibilities:**

- One-shots (3-act structure, runnable in a single session)
- Small adventures (3-8 sessions, chapter-based)
- Medium adventures and campaign arcs (8-35 sessions)
- Quest boards (region-specific hook collections)
- Campaign starters (enough material to launch a campaign)
- Player primers (world intro documents for new players)
- GM toolkits (random tables, encounter generators, NPC quick-reference)

**What makes it different from the Worldwriter:**

The Worldwriter builds the world. The Adventuresmith makes it playable. The Worldwriter writes "here is a dangerous mine." The Adventuresmith writes "here is a one-shot where the players investigate why miners are disappearing, with 3 encounters, an NPC ally, a moral dilemma, and a twist."

**Design principles baked into the prompt:**

- **Situations, not plots.** Present a scenario with tension. Never script what the players do.
- **But/Therefore, never And Then.** Every beat chains through complication or consequence.
- **Dramatic questions.** Every scene answers "Will the players...?" If there's no question, there's no tension.
- **Intention and Obstacle.** Define what PCs want and what blocks them. Never define the solution.
- **Scannable at the table.** A GM should be able to run it after 5 minutes of reading. Bullet points, tables, callout boxes. No prose walls.

**Adventure triggers (enforced by the Gamemaster based on vault state):**

| Vault state | Content type |
|------------|-------------|
| 2-3 locations + a handful of NPCs exist | First one-shot |
| 2+ new interesting locations or NPC conflicts since last adventure | New one-shot or small adventure |
| Multiple factions, 10+ NPCs, varied locations in a region | Medium adventure or campaign evaluation |
| A region has 5+ locations worth visiting | Quest board |
| Continuous | GM tools, encounter tables |

---

## What We Take from the Old System

The existing Aethermourne/Wylderan setup at `/home/aethermourne/gamemaster/` has battle-tested rules and methodology. We extract the **rules and patterns only** — no world content, no names, no lore, no vault files.

### Rules we extract (methodology only, no world-specific content)

**Into Canopy `base-agent` prompt:**
- Obsidian markdown rules: wikilink syntax, callout types, frontmatter schemas, tag hierarchy
- No em-dashes rule (use commas instead)
- Scannability requirements: headings, short paragraphs, lists, tables, callouts
- "A GM should be able to scan a file and run it at the table within 5 minutes"

**Into Canopy `gamemaster` prompt:**
- Bottom-up worldbuilding philosophy: follow implications, don't fill gaps
- Discovery questions: trade, threats, history, relationships, resources, culture, geography
- Delegation rules: GM never writes files, delegates to specialists
- Narrative techniques: but/therefore, dramatic questions, situations not plots, want vs need
- Adventure structure templates (one-shot 3-act, small/medium adventure chapter format)

**Into Canopy `lorekeeper` prompt:**
- Audit methodology: search everywhere, cross-reference, report
- Contradictions vs missing detail distinction ("gaps are natural, not problems")
- Never writes files, only researches and reports

**Into Canopy `worldwriter` prompt:**
- Implication-driven location creation process
- Geographic context requirements (direction, proximity, terrain)
- Creative mode vs execution mode distinction
- Settlement/landmark/faction file templates

**Into Canopy `characterwriter` prompt:**
- NPC creation process: research context, create, register
- Enriched NPC template: appearance, personality layers (first impression / deeper / hidden), backstory, relationships, want vs need, GM-only section with roleplay notes and sample dialogue
- Never creates NPCs that already exist (check registry first)

**Into Canopy `adventuresmith` prompt (new, written from scratch using extracted patterns):**
- Adventure design principles from the old Gamemaster role
- Structure templates adapted for each scale (one-shot, small, medium, campaign)
- Narrative techniques applied to playable content

**Into Mulch domains:**
- `obsidian`: wikilink conventions, frontmatter field schemas, callout syntax reference
- `writing-craft`: no em-dashes, scannability rules, no purple prose, structure requirements
- `adventure-design`: but/therefore, dramatic questions, intention/obstacle, situations not plots
- `anti-cliches`: trope blacklist (new, not from old system)
- `ttrpg-system`: Nimble TTRPG rules, stat block format, speed-in-spaces (from existing reference)

### What does NOT carry over

- **No vault content.** No world files, no lore, no NPCs, no locations, no timelines, no changelogs.
- **No world-specific names.** No "Aethermourne", "Wylderan", "Millhaven", "Ashflow", "The Twelve", etc.
- **No world-specific tone.** No "dark fantasy on the bones of dead gods" or any predetermined aesthetic.
- **No world-specific conventions.** No region tags, faction names, calendar systems, naming traditions.
- **No AI Maestro config.** No AMP scripts, no tmux session configs, no nudge scripts, no cycle-reset scripts.
- **No `.agents-*/*.md` files copied directly.** The rules are extracted and rewritten cleanly for Canopy — not copy-pasted with find-and-replace.

The new system starts from a blank vault. The world defines itself as it is built.

### Implementation steps

1. Initialize os-eco tools in this repo (`ml init`, `sd init`, `cn init`, `ov init`)
2. Write Canopy prompts from scratch, informed by the old rules (not copied)
3. Populate Mulch domains with extracted conventions
4. Write Overstory specs for each agent type
5. Write custom scripts (idea swarm, vault context, launchers)
6. Test with a fresh world from a blank vault

---

## Resolved Questions

### 1. Sapling guards — no content pattern matching
Guards only operate on tool call inputs (tool names, file paths, bash commands). No regex-on-output support. **Decision:** Anti-cliche enforcement is prompt-based via Mulch (`ml prime anti-cliches`). The Lorekeeper acts as a post-hoc filter. Guards are used only for sandboxing agents (path boundaries, blocked tools, read-only mode for Lorekeeper).

### 2. Overstory worktrees — branch-per-agent only
Every `ov sling` creates an isolated worktree and branch. No shared mode exists. `ov merge` brings branches back with a 4-tier strategy (clean → auto-resolve → AI-resolve → re-imagine). **Decision:** This works well. Writers get isolation, no file conflicts. The merge system handles concurrent writers touching different files.

### 3. Sapling context manager — fully generic
Zero file-type awareness. Tracks relevance by file paths, tool types, recency, and success/failure — not by language or extension. `.md` files get the same treatment as `.ts` files. **Decision:** Sapling works out of the box for writing agents. Use `--backend cc`.

### 4. One world per repo
Multi-world is out of scope. One repo = one world = one orchestrator. To build a second world, init a new repo.

## Open Questions

### Token budget for autonomous mode
The autonomous loop could run indefinitely. Need a token budget strategy:
- Per-implication budget (idea swarm + specialist agents + Gamemaster overhead)
- Per-session budget (total before the Gamemaster compacts/restarts)
- Cost alerting (Overstory's `ov costs` can help here)

---

## Implementation Order

| Phase | Work | Depends on |
|-------|------|------------|
| 1 | Initialize os-eco tools in repo | Nothing |
| 2 | Write base-agent + agent role prompts for Canopy | Phase 1 |
| 3 | Set up Mulch domains + seed initial expertise | Phase 1 |
| 4 | Write idea swarm script | Phase 2 (needs idea-agent prompt) |
| 5 | Write vault context assembler | Nothing |
| 6 | Write Overstory specs + configure orchestrator | Phase 2 |
| 7 | Write anti-cliche guards | Phase 3 |
| 8 | Write interactive + autonomous mode launchers | Phase 2, 6 |
| 9 | Write init-world.sh | All above |
| 10 | Test: initialize a fresh world and let it run autonomously for ~5 implications | Phase 9 |

Phases 1-3 can run in parallel. Phases 4-5 can run in parallel. Phase 6-8 can partially overlap.

Estimated custom code: ~500 lines of bash scripts + ~2000 lines of prompt/expertise markdown.