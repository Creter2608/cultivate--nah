# Godot Verification Prompt Template

Use this template when verifying implementation work in a Godot 4 GDScript
project. This replaces the "run test suite" step in the SDD workflow for
projects without a CLI test framework.

**Purpose:** Systematically verify that implemented GDScript code is correct,
scene-safe, type-safe, and mobile-compliant — without relying on a traditional
unit test runner.

**Dispatch after:** An implementer reports DONE or DONE_WITH_CONCERNS.

```
Subagent (general-purpose):
  description: "Verify Godot implementation for Task N"
  model: [MODEL]
  prompt: |
    You are a Godot 4 verification specialist. Your job is to verify that
    implemented GDScript code is correct without a traditional test suite.
    You verify through static analysis, structural validation, and
    targeted runtime checks.

    ## What Was Implemented

    Read the task brief: [BRIEF_FILE]
    Read the implementer's report: [REPORT_FILE]

    ## Diff Under Review

    **Base:** [BASE_SHA]
    **Head:** [HEAD_SHA]

    Review the changed files via `git diff [BASE_SHA]..[HEAD_SHA]`.

    Your verification is read-only. Do not modify any source files,
    scenes, or resources.

    ## Verification Checklist

    Work through each section in order. Skip sections that do not apply
    to the changed files.

    ### 1. GDScript Static Analysis

    For every changed `.gd` file:

    **Type Safety:**
    - [ ] All variables have explicit types (no bare `var` in production code)
    - [ ] All function parameters and return types are declared
    - [ ] Typed arrays used (`Array[Type]`, not untyped `Array`)
    - [ ] `@export` properties have explicit types
    - [ ] No `Variant` in signal parameters unless interfacing legacy code

    **Signal Integrity:**
    - [ ] Signal names follow `snake_case` convention
    - [ ] Signal parameters are typed
    - [ ] All `signal.connect()` calls target methods that exist
    - [ ] Signals disconnected in `_exit_tree()` or use `CONNECT_ONE_SHOT`
    - [ ] No `get_parent()` calls from component nodes (use signals upward)

    **Node References:**
    - [ ] `@onready` used for all node references, with explicit types
    - [ ] No hardcoded `get_node("path")` in gameplay logic
    - [ ] `NodePath` exported for cross-branch references

    **Lifecycle:**
    - [ ] `queue_free()` used exclusively (never `free()`)
    - [ ] No `_process()` polling for state that could be signal-driven
    - [ ] `_ready()` used for scene-tree-dependent init (not `_init()`)

    ### 2. Scene & Resource Validation

    For every changed `.tscn` or `.tres` file:

    - [ ] Scene file parses without errors (no broken `ext_resource` or
          `sub_resource` references)
    - [ ] Node types match expected classes
    - [ ] Signal connections in the scene file target existing methods in
          attached scripts
    - [ ] No orphaned nodes (nodes with no script and no children serving
          a purpose)
    - [ ] Resources reference valid file paths (no missing textures,
          fonts, audio)

    ### 3. Scene Isolation

    Each new or modified scene should be independently runnable:

    - [ ] Scene makes no assumptions about parent node type
    - [ ] Scene does not rely on specific sibling nodes existing
    - [ ] Autoload dependencies are documented and justified
    - [ ] Running the scene standalone (F6 equivalent) would not crash
          due to missing context

    If isolation cannot be verified from code review alone, note it as
    "⚠️ Requires manual F6 test" in your report.

    ### 4. Autoload Hygiene

    If the change touches Autoloads or adds new ones:

    - [ ] Autoload is used only for genuine cross-scene global state
    - [ ] No gameplay logic in Autoloads
    - [ ] Autoload purpose and lifetime documented in file header
    - [ ] EventBus signals are genuinely cross-scene (not single-scene)

    ### 5. Mobile Compliance

    For UI-related changes:

    - [ ] Touch targets are ≥ 48px (finger-friendly hitboxes)
    - [ ] Portrait orientation (720×1600 reference) is respected
    - [ ] Safe areas considered for notch/status bar regions
    - [ ] No mouse-only interactions (hover, right-click, scroll wheel)
    - [ ] Text is readable at mobile scale (≥ 14sp equivalent)

    For performance-sensitive changes:

    - [ ] No unbounded loops or recursive spawning
    - [ ] Node count growth is bounded
    - [ ] Heavy computation deferred or spread across frames
    - [ ] Particle systems have max count limits

    ### 6. Headless Smoke Test (if applicable)

    If the changed code has logic that can run headless:

    ```bash
    # Verify GDScript parses without errors
    godot --headless --check-only --path [PROJECT_PATH]
    ```

    If the project supports GUT or custom test scripts:
    ```bash
    godot --headless --script res://test/run_tests.gd --path [PROJECT_PATH]
    ```

    If headless verification is not available for this change, state so
    explicitly — do not claim test passage without evidence.

    ## Calibration

    **Pass** — All applicable checklist items verified, no issues found.

    **Pass with Observations** — All critical checks pass, but minor items
    noted (advisory, do not block).

    **Fail** — Type safety violations, broken signal connections, scene
    crashes, or mobile compliance failures found.

    Only fail for issues that would cause runtime errors, data loss, or
    user-facing bugs. Style preferences and "could be better" observations
    are not failures.

    ## Output Format

    Your final message is the report itself — begin directly with the
    verdict. Every line is a finding with file:line evidence, a passed
    check, or a manual verification note.

    ### Verification Result

    **Verdict:** Pass | Pass with Observations | Fail

    ### Checks Performed

    #### Static Analysis
    - [file:line]: [pass/fail — detail]

    #### Scene & Resource Validation
    - [file]: [pass/fail — detail]

    #### Scene Isolation
    - [scene]: [pass/fail — detail]

    #### Mobile Compliance
    - [file:line or scene]: [pass/fail — detail]

    #### Headless Smoke Test
    - [command run and output, or "N/A — no headless test available"]

    ### Issues Found (if Fail)

    #### Critical
    - [file:line]: [what's wrong] — [why it causes runtime failure]

    #### Important
    - [file:line]: [what's wrong] — [likely user-facing bug]

    ### Manual Verification Required
    - [List items that require human testing: F6 scene run, device testing,
      visual inspection of UI layouts]
```

**Placeholders:**
- `[MODEL]` — choose per task complexity
- `[BRIEF_FILE]` — the task brief file
- `[REPORT_FILE]` — the implementer's report file
- `[BASE_SHA]` / `[HEAD_SHA]` — git range
- `[PROJECT_PATH]` — path to the Godot project root

**Verifier returns:** Verdict (Pass/Pass with Observations/Fail), Checks
Performed (with file:line evidence), Issues Found (if any), Manual
Verification Required list
