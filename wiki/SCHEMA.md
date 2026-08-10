# Wiki Schema & Conventions

This wiki serves as the Knowledge Base, Lore Bible, and Game Design Document for our TextRPG game.
As an LLM, I will follow these conventions when maintaining this wiki.

## Directory Structure
- `index.md` - Catalog of all wiki pages, organized by categories (Entities, Locations, Concepts, Systems, etc.)
- `log.md` - Chronological log of all ingestions and significant updates.
- `raw/` - Directory containing raw, immutable source materials (ideas, chat logs, images, snippets).
- `entities/` - Pages for characters, NPCs, organizations.
- `locations/` - Pages for places, regions, cities.
- `concepts/` - Lore concepts, magic systems, history.
- `design/` - Game mechanics, UI specs, technical design notes.

## Ingestion Workflow
When a new raw source or idea is provided:
1. Read the source.
2. Extract key information.
3. Create new pages or update existing pages in the relevant subdirectories.
4. Update `index.md` with links and 1-line summaries for any new pages.
5. Append an entry to `log.md` in the format: `## [YYYY-MM-DD] ingest | <Title of Source or Idea>`
6. Add appropriate cross-references to maintain the graph. We use relative markdown links, e.g., `[Character Name](entities/character.md)`.

## Maintenance
- Keep files concise but comprehensive.
- Resolve contradictions gracefully or highlight them for the user to decide.
- Periodically check for orphan pages or missing cross-references.
