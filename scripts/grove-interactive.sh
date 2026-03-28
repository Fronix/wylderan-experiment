#!/bin/bash
# Start the Gamemaster in interactive mode.
# Usage: grove-interactive.sh

set -euo pipefail

# Render the gamemaster prompt (inherits base-agent via canopy)
PROMPT=$(cn render gamemaster 2>/dev/null || cat .grove/prompts/gamemaster.md)

# Prime expertise
EXPERTISE=$(ml prime tone anti-cliches adventure-design 2>/dev/null || true)

INTERACTIVE_PREAMBLE="
## Mode: Interactive

You are in INTERACTIVE mode. The human is your creative director.

**How this works:**
1. The human describes what they want, a region feel, an NPC concept, a plot thread, a correction, anything
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
- Show the human what was built after each task completes, file paths and a brief summary
- The human can say 'go autonomous' at any time to switch to autonomous mode
"

# Write the mode context into CLAUDE.md so the orchestrator picks it up
cat > CLAUDE.md << EOF
${PROMPT}

${EXPERTISE}

${INTERACTIVE_PREAMBLE}
EOF

echo "[grove] Starting interactive mode..."
echo "[grove] Stop: ov orchestrator stop"
echo ""

ov orchestrator start --attach
