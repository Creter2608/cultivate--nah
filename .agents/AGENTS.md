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
