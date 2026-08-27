---
name: agency-workflow-templates
description: Project-specific enhanced workflow templates for Godot 4 mobile game development. Overrides lightweight Superpowers defaults (plan-reviewer, spec-reviewer) and adds Godot-specific verification. Use when routing workflow stages per AGENTS.md Section 7.
---

# Workflow Templates for Godot 4 Project

Project-level enhanced prompt templates that complement or override the default Superpowers templates.

## Why Project-Level Templates?

The Superpowers plugin ships generic templates designed for any codebase. This project has specific needs:
- **Godot 4 GDScript** — no standard CLI test suite, scene-based architecture
- **Mobile-first** — touch UX constraints, portrait orientation, performance budgets
- **Signal-driven composition** — type-safe signals, node tree integrity

These templates encode those constraints so every subagent automatically respects them.

## Available Templates

### Enhanced Overrides (replace Superpowers defaults)

| Template | Replaces | Key Additions |
|:---|:---|:---|
| [plan-reviewer-prompt.md](plan-reviewer-prompt.md) | `writing-plans/plan-document-reviewer-prompt.md` | Severity levels, evidence requirement, dependency validation, Godot scene structure checks |
| [spec-reviewer-prompt.md](spec-reviewer-prompt.md) | `brainstorming/spec-document-reviewer-prompt.md` | Severity levels, evidence requirement, testability check, mobile constraint validation |

### New Templates

| Template | Purpose |
|:---|:---|
| [godot-verification-prompt.md](godot-verification-prompt.md) | Replaces "run test suite" step for Godot projects. Static analysis, scene isolation, resource validation, mobile compliance. |

### Unchanged (use Superpowers defaults)

These Superpowers templates are already production-grade and require no project-level override:
- `implementer-prompt.md` (9.5/10)
- `task-reviewer-prompt.md` (9.5/10)
- `re-review-prompt.md` (9/10)

## Routing

See [AGENTS.md Section 7](../../AGENTS.md) for the routing matrix that determines which template is loaded for each workflow stage.
