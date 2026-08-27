# Agent Guidelines & Principles

These guidelines dictate how AI agents (including Antigravity and any invoked subagents) must behave when working on this project. These are heavily inspired by Andrej Karpathy's observations on LLM coding pitfalls.

## 1. Think Before Coding
**Don't assume. Don't hide confusion. Surface tradeoffs.**
- **State assumptions explicitly** — If uncertain, ask rather than guess.
- **Present multiple interpretations** — Don't pick silently when ambiguity exists.
- **Push back when warranted** — If a simpler approach exists, say so.
- **Stop when confused** — Name what's unclear and ask for clarification.

## 2. Simplicity First
**Minimum code that solves the problem. Nothing speculative.**
- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If 200 lines could be 50, rewrite it.
- **The test:** Would a senior engineer say this is overcomplicated? If yes, simplify.

## 3. Surgical Changes
**Touch only what you must. Clean up only your own mess.**
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it unless explicitly asked.

## 4. Goal-Driven Execution
**Verify your work systematically.**
- Always ensure the code is testable and actually runs.
- Rely on verifiable success criteria rather than assuming it works.

## 5. Language
**ALL code must be written in English.**
- This includes class names, variable names, function names, and inline code comments.
- This is a strict requirement to ensure synchronization with the development team.
- Communication with the user in the chat interface should remain in Vietnamese, but the codebase itself must be 100% English.

## 6. Target Platform: Mobile Game
**This project is a Mobile Game.** All design, UI, and UX decisions must prioritize mobile platforms (Android/iOS):
- **Mobile Touch UX**: Design touch controls, touch drag cancellation, tap-to-toggle modals, and press-and-hold interactions tailored for mobile touchscreens (finger-friendly hitboxes min 48-56px).
- **Mobile Resolutions & Portrait Orientation**: Respect mobile aspect ratios (e.g. 720x1600 portrait) and safe areas.
- **Mobile Performance**: Keep scenes lightweight, optimize draw calls, and avoid heavy CPU/GPU overhead suitable for mobile devices.

## 7. Template Routing Matrix
**When dispatching subagents for workflow stages, load the correct prompt template.**

Project-level templates (in `.agents/skills/agency-workflow-templates/`) override Superpowers defaults where available. Use Superpowers defaults for stages without a project-level override.

| Workflow Stage | Template to Load | Source |
|:---|:---|:---|
| **Feature Implementation / Bugfix / Coding** | `implementer-prompt.md` | Superpowers (default) |
| **Code Review / Validation** | `task-reviewer-prompt.md` | Superpowers (default) |
| **Re-review After Fix Round** | `re-review-prompt.md` | Superpowers (default) |
| **Planning & Architecture Review** | `plan-reviewer-prompt.md` | **Project override** |
| **Brainstorming / Spec Review** | `spec-reviewer-prompt.md` | **Project override** |
| **Godot Implementation Verification** | `godot-verification-prompt.md` | **Project (new)** |

**Rules:**
- Always output the transparency tag: `📋 [Template Applied]: Loaded <template-name> for <workflow-stage>`
- For Godot verification: dispatch **after** the implementer reports DONE, **before** the task reviewer. This replaces "run test suite" in the SDD workflow.
- The Godot verification step is **optional** when changes are documentation-only or data-only (.tres/.cfg files with no script changes).

## 8. Continuous Learning & Pitfall Prevention
**Never repeat a known mistake.**
- **Consult Before Coding**: AI agents must review [`.agents/LEARNINGS.md`](LEARNINGS.md) before implementing or modifying systems to avoid previously documented stumbles.
- **Log New Learnings**: When a non-trivial bug, subtle edge case, runtime crash, or architectural flaw is identified and fixed, append a new log entry to [`.agents/LEARNINGS.md`](LEARNINGS.md).
- **Rule of Evolution**: Over time, repeated lessons in `LEARNINGS.md` should be graduated into explicit rules or checklist items in `AGENTS.md` or relevant skill files.

## 9. 3-Tier Pipeline Complexity Gating (Anti-Token-Drain)
**Optimize token consumption by routing tasks based on architectural complexity.**

Layer 1 must classify every coding task before deciding whether to invoke Layer 2 (GPT Prompt Architect):

| Routing Path | Task Criteria | Execution Strategy | GPT Token Cost |
|:---|:---|:---|:---:|
| **Fast-Path** *(Lightweight)* | Touches $\le 2$ files, isolated bugfix, UI/layout tweaks, simple helper/math functions, or clear mechanical edits. | Bypass Layer 2 entirely. Dispatch directly to **DeepSeek Coder (Layer 3)** or handle locally. | **$0** *(100% saved)* |
| **Architect-Path** *(Complex)* | New gameplay subsystems, cross-file architectural refactors, combat/state/inventory mechanics, or algorithmic logic. | Trigger full 3-Tier pipeline: **GPT Architect (Layer 2)** creates blueprint & test assertions table $\rightarrow$ **DeepSeek Coder (Layer 3)** implements code. | Standard Blueprint Cost |

**Gating Invariants:**
- Never invoke Layer 2 for simple syntax errors, one-line bug fixes, or minor formatting changes.
- In fix loops (rounds 1-5), always keep Layer 2 out of the loop and rely strictly on Layer 3 / local verification.

### Reasoning Effort Routing (Anti-Token-Burn)
**Layer 1 MUST NOT judge task complexity to select `reasoning_effort`.** The value is determined mechanically by the first matching rule in priority order:

| Priority | Source | `reasoning_effort` | When |
|:---:|:---|:---:|:---|
| **1** | **User override** | User-specified | User explicitly states effort level in their request. |
| **2** | **GPT Blueprint** (Layer 2) | As specified in blueprint | Architect-Path: GPT includes `reasoning_effort` in its output for DeepSeek. |
| **3** | **Fast-Path rule** | `"low"` (hardcoded) | Fast-Path tasks: always `"low"`, no exceptions. |
| **4** | **Fallback** | `"medium"` | Architect-Path where GPT blueprint omits effort level. |

**Effort Profiles (configured in `deepseek_mcp.py`):**

| Level | Auto `max_tokens` Cap | Typical Use |
|:---|:---:|:---|
| `"low"` | $3{,}072$ | Surgical edits, add/fix 1-2 functions, UI tweaks. |
| `"medium"` | $4{,}096$ | Multi-step logic, state machines, serialization. |
| `"high"` | $8{,}192$ | Complex algorithms, deep debugging, system-wide refactors. |

**Invariants:**
- Layer 1 never selects `reasoning_effort` based on its own semantic assessment of task difficulty.
- User override always takes highest priority and can specify any level or a custom `max_tokens` value.
- The `max_tokens` cap can be overridden per-call via the `max_tokens` parameter when the auto cap is insufficient.
