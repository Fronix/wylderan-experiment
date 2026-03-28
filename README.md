# Grove

An autonomous TTRPG worldbuilding system powered by AI agent swarms. Start it, walk away, come back to a playable world.

Grove uses a team of specialized AI agents to build worlds from the ground up. It follows implications in existing content to expand organically, avoids fantasy cliches, and creates playable adventures alongside the lore.

## How It Works

One persistent agent (the **Gamemaster**) orchestrates everything. It discovers what to build next, brainstorms with ephemeral idea agents, delegates writing to specialists, and commits the results. All content is stored as an Obsidian vault and published as a static site via Quartz.

```
Gamemaster (persistent orchestrator)
  ├── Idea Agents (2-4, brainstorm with creative lenses, then die)
  ├── Lorekeeper (audits consistency, checks for cliches, then dies)
  ├── Worldwriter (creates locations, factions, history, then dies)
  ├── Characterwriter (creates NPCs, then dies)
  └── Adventuresmith (creates playable content, then dies)
```

### Two Modes

**Autonomous** — The Gamemaster runs a continuous loop: discover implications, brainstorm, plan, delegate, merge, commit, repeat. You start it and walk away.

**Interactive** — You talk to the Gamemaster like a creative director. Describe what you want, it decomposes your input into tasks and delegates to the agent team.

## Built On

- [Overstory](https://github.com/jayminwest/overstory) — Multi-agent orchestration (spawn, monitor, merge)
- [Mulch](https://github.com/jayminwest/mulch) — Expertise storage (tone, lore rules, anti-cliche list)
- [Seeds](https://github.com/jayminwest/seeds) — Task tracking with dependency graphs
- [Canopy](https://github.com/jayminwest/canopy) — Prompt management with inheritance
- [Sapling](https://github.com/jayminwest/sapling) — Headless agent runtime
- [Quartz](https://quartz.jzhao.xyz/) — Static site generator for Obsidian vaults
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) — AI runtime

## Quick Start

### Prerequisites

- [Bun](https://bun.sh/) >= 1.0
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) with an active subscription
- os-eco tools: `bun install -g @os-eco/mulch-cli @os-eco/seeds-cli @os-eco/canopy-cli @os-eco/sapling-cli @os-eco/overstory-cli`

### Setup

```bash
git clone https://github.com/Fronix/wylderan-experiment.git my-world
cd my-world
./scripts/init-world.sh "My World Name"
```

This creates the vault structure, initializes all os-eco tools, seeds the anti-cliche rules and TTRPG system reference into Mulch, and sets up Canopy prompts.

### Run

```bash
# Autonomous mode — agents build the world unattended
./scripts/grove-auto.sh

# Interactive mode — you steer, agents execute
./scripts/grove-interactive.sh
```

### Monitor

```bash
ov dashboard          # Live TUI showing agent status
ov feed -f            # Real-time event stream
ov costs              # Token usage breakdown
ov status             # Current agent states
```

### Stop

```bash
ov orchestrator stop
```

## Project Structure

```
.grove/                     # Grove-specific configuration
  prompts/                  # Agent role definitions (source of truth)
  lenses/                   # Creative lenses for idea agents
  guards/                   # Sapling guard files (sandboxing)
  specs/                    # Overstory agent specs
  anti-cliches.md           # Trope blacklist

.canopy/                    # Canopy prompt storage (versioned)
.mulch/                     # Mulch expertise records
.seeds/                     # Seeds task tracking
.overstory/                 # Overstory config and runtime

scripts/
  init-world.sh             # Initialize a new world
  grove-auto.sh             # Start autonomous mode
  grove-interactive.sh      # Start interactive mode
  build.sh                  # Build the Quartz site locally

vault/                      # Obsidian vault (the world content)
  World Overview.md
  Timeline.md
  NPCRegistry.md
  CHANGELOG.md
  Compendium/               # Locations, factions, NPCs, history, bestiary
  Adventures/               # One-shots, campaigns, quest boards

site/                       # Quartz framework (builds vault into a website)
Dockerfile                  # Docker build (Quartz + Nginx)
nginx.conf                  # Static file serving config
```

## Anti-Cliche System

Grove actively fights against generic fantasy output. The anti-cliche system works at three layers:

1. **At ideation** — Idea agents load the trope blacklist before brainstorming
2. **At curation** — The Gamemaster checks brainstorm results against the list
3. **At review** — The Lorekeeper audits new content for cliche violations

Hard rejections include: dead god bodies as landscape, ancient evil awakening, chosen one prophecy, monoculture nations, evil races, and common AI tendencies like purple prose, cosmic scope creep, and overwrought naming.

See `.grove/anti-cliches.md` for the full list.

## TTRPG System

Defaults to [Nimble TTRPG](https://nimblerpg.com/). The system reference (armor categories, stat block format, speed in spaces) is seeded into Mulch on init. Pass `--system "D&D 5e"` to `init-world.sh` to use a different system (you'll need to seed your own reference data).

## Publishing

The vault is published as a static website using Quartz. Pushes to `main` that change `vault/` or `site/` trigger a GitHub Actions workflow that builds and deploys to GitHub Pages.

Build locally:
```bash
./scripts/build.sh --title "My World"
```

Build with Docker:
```bash
docker build --build-arg PAGE_TITLE="My World" -t grove .
docker run -p 8080:80 grove
```

## Design Principles

1. **Playable over lore-rich.** Every implication followed should bring the world closer to something a GM can run at the table.
2. **Bottom-up, not top-down.** Follow implications from what exists. Never fill a predetermined template.
3. **Anti-cliche by default.** Multiple creative voices + explicit trope detection prevent generic output.
4. **Spawn on demand, kill when done.** Only the Gamemaster persists. Everything else is ephemeral.
5. **Human optional.** Autonomous mode runs unattended. Interactive mode is a conversation, not a command line.
