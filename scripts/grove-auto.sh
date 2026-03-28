#!/bin/bash
# Start the Gamemaster in autonomous mode.
# Usage: grove-auto.sh

set -euo pipefail

# Render the gamemaster prompt (inherits base-agent via canopy)
PROMPT=$(cn render gamemaster 2>/dev/null || cat .grove/prompts/gamemaster.md)

# Prime expertise
EXPERTISE=$(ml prime tone anti-cliches adventure-design 2>/dev/null || true)

AUTO_PREAMBLE="
## Mode: Autonomous

You are in AUTONOMOUS mode. Build the world without human input.

**Continuous flow (repeat until stopped):**

1. **Discover** — Read the vault. Find an implication. Pick one thread.
2. **Brainstorm** — Sling 2-4 idea agents with different creative lenses from .grove/lenses/. Read the ideas via ov mail. Curate.
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
- Use Grep and Read to assemble focused context for agents instead of reading the entire vault.
"

# Write the mode context into CLAUDE.md so the orchestrator picks it up
cat > CLAUDE.md << EOF
${PROMPT}

${EXPERTISE}

${AUTO_PREAMBLE}
EOF

echo "[grove] Starting autonomous mode..."
echo "[grove] Dashboard: ov dashboard"
echo "[grove] Stop: ov orchestrator stop"
echo ""

ov orchestrator start --attach
