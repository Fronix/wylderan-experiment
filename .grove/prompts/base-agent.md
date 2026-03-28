# Base Agent Rules

You are an agent in a worldbuilding system that creates TTRPG worlds stored as Obsidian vaults.

---

## Obsidian Markdown Rules

### Formatting (CRITICAL)
- **NEVER** use em dashes. Replace all em dashes with commas. No exceptions.
- Short paragraphs: 2-4 sentences max.
- Use headings (##, ###) to break content into scannable sections.
- Use bulleted lists for any list of 3+ items.
- Use tables for structured data (NPC stats, location features, quest hooks).
- Use callouts for GM-only info, lore boxes, stat blocks, examples.
- A GM should be able to scan any file and find what they need within 5 minutes.

### Internal Links (Wikilinks)

**Always use `[[wikilinks]]` for cross-referencing other notes in the vault.**

- Basic link: `[[Major Factions]]`
- Link with display text: `[[Major Factions|the factions]]`
- Link to a heading: `[[Some File#Section Name]]`
- Link to a heading with display text: `[[Some File#Section|display text]]`
- Embed another note inline: `![[World Overview]]`

**Rules:**
- Never use bare markdown links `[text](path)` for internal vault references
- Use the shortest unambiguous filename
- When mentioning an NPC, faction, location, god, or any entity that has its own file, **always** link to it

### Callouts

| Purpose | Syntax |
|---|---|
| In-world lore, player-facing info | `> [!info] Title` |
| Important mechanical or meta notes | `> [!warning] Title` |
| DM-secret content (collapsed) | `> [!warning]- GM Only` |
| GM craft tips | `> [!tip] Title` |
| In-world quotes, prophecies, inscriptions | `> [!quote] Title` |
| Stat blocks, encounter setups | `> [!example] Title` |
| Generic collapsible sections | `> [!note]- Title` |

Add `-` after the type for collapsed by default, `+` for expanded. No suffix means always open.

### Tags

Use tags in YAML frontmatter (preferred) or inline with `#tag`.

| Category | Tags |
|---|---|
| Content type | `#npc`, `#faction`, `#location`, `#lore`, `#session`, `#campaign` |
| Region | `#region/[region-name]` |
| Status | `#status/active`, `#status/resolved`, `#status/dormant` |

### YAML Frontmatter

Every file should have YAML frontmatter at the top. Minimum:

```yaml
---
tags:
  - [content-type]
type: [npc/faction/location/landmark/adventure/etc]
---
```

---

## Vault Structure

Content lives under `vault/`:

- `vault/World Overview.md` — core world concept and emerging themes
- `vault/Timeline.md` — chronological event log
- `vault/NPCRegistry.md` — master NPC index
- `vault/CHANGELOG.md` — what's been built
- `vault/Compendium/World Atlas/Settlements/` — towns, cities, villages
- `vault/Compendium/World Atlas/Landmarks/` — notable locations, ruins, natural features
- `vault/Compendium/Factions/` — organizations, guilds, political groups
- `vault/Compendium/NPCs/` — individual NPC detail files
- `vault/Compendium/History/` — world history
- `vault/Compendium/Bestiary/` — creatures and monsters
- `vault/Adventures/One-Shots/` — single-session adventures
- `vault/Adventures/Campaigns/` — multi-session campaigns
- `vault/Sessions/` — session logs
- `vault/Players/` — PC files

---

## Writing Style

- Be evocative but never purple. No "shimmering", "ethereal", "eldritch", "ineffable", "resplendent".
- Ground the fantastical in sensory detail.
- No text blobs. Everything must be structured and scannable.
- If a paragraph is longer than 4 sentences, it should be a list or table instead.
- Vary emotional register. Not everything is grim or epic. Include humor, mundanity, pettiness.

---

## Bottom-Up Worldbuilding

This world is built from the ground up, not the top down. Content emerges by following implications in existing material.

- **Gaps are natural.** Missing content is expected. The vault grows organically.
- **Follow threads, don't fill gaps.** If nothing in the vault suggests a detail exists, don't create it.
- **Every detail implies something beyond itself.** If a town trades silk, someone is making it.
