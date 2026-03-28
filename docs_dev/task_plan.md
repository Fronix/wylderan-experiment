# Task Plan: Worldbuilding Agent System (Grove)

## Goal
Build an agentic TTRPG worldbuilding system using os-eco tools (mulch, seeds, canopy, overstory) with custom extensions for creative writing workflows. Replace AI Maestro with Overstory orchestration. Support autonomous and interactive modes.

## Status: SPECCING

## Phases
- [x] Phase 1: Research existing system and os-eco tools
- [ ] Phase 2: Write implementation spec
- [ ] Phase 3: Initialize os-eco tools in repo
- [ ] Phase 4: Build Canopy prompts (agent roles)
- [ ] Phase 5: Build Mulch expertise domains
- [ ] Phase 6: Build custom components (idea swarm, vault context, anti-cliche guards)
- [ ] Phase 7: Configure Overstory orchestration
- [ ] Phase 8: Build interactive mode wrapper
- [ ] Phase 9: Test with a fresh world

## Key Decisions
- Use Overstory as orchestrator (replaces AI Maestro)
- Use Sapling with custom system prompts for writing agents (no need to build "scribe")
- Mulch for expertise/conventions, Seeds for internal task tracking, Canopy for prompt management
- Gamemaster is the only persistent agent (Overstory orchestrator)
- All other agents spawned on demand via `ov sling`
- Idea agents are ephemeral brainstorm swarms

## Errors Encountered
(none yet)
