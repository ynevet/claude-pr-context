# Spec Gap Analysis Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Spec Gap Analysis section to the `/create-pr` command that compares the branch's code against its spec (md file, Jira ticket, GitHub issue, or session prompts) and reports divergences for the reviewer.

**Architecture:** Everything lives in the single command file `commands/create-pr.md` (the repo distributes by copying that one file). A new Step 2.5 discovers spec sources and runs a grounded, adversarial comparison against the Step-1 diff; the Step 3 body template gains a new section; two new consumed flags (`--spec`, `--no-gaps`) join `--dry-run`. `README.md` documents the feature.

**Tech Stack:** Markdown prompt files only — no code, no test suite. Verification is manual via `/create-pr --dry-run`.

**Spec:** `docs/superpowers/specs/2026-06-04-spec-gap-analysis-design.md`

---

### Task 1: Add `--spec` / `--no-gaps` flag handling to the Modes section

**Files:**
- Modify: `commands/create-pr.md:7-14` (the `## Modes` section)

- [ ] **Step 1: Update the Modes section**

In `commands/create-pr.md`, replace this text:

```markdown
- **No mode flag** (default): Run all steps, including Step 4, to create the PR.

Strip `--dry-run` / `--preview` out before passing the remaining arguments through to `gh pr create`. Every other flag (e.g. `--draft`, `--base`, `--reviewer`) passes through untouched (see Notes).
```

with:

```markdown
- **No mode flag** (default): Run all steps, including Step 4, to create the PR.

Two more flags are consumed by this command (never passed to `gh pr create`):

- **`--spec <path | JIRA-KEY | #issue>`**: Explicitly sets the spec source for Step 2.5 — a file path, a Jira key like `PROJ-123`, or a GitHub issue like `#42`. Skips spec auto-discovery.
- **`--no-gaps`**: Skip Step 2.5 entirely and omit the "Spec Gap Analysis" section from the body.

Strip `--dry-run` / `--preview` / `--spec <value>` / `--no-gaps` out before passing the remaining arguments through to `gh pr create`. Every other flag (e.g. `--draft`, `--base`, `--reviewer`) passes through untouched (see Notes).
```

- [ ] **Step 2: Commit**

```bash
git add commands/create-pr.md
git commit -m "feat: consume --spec and --no-gaps flags in /create-pr"
```

---

### Task 2: Add Step 2.5 — spec discovery and gap analysis

**Files:**
- Modify: `commands/create-pr.md` (insert a new section between Step 2, which ends with the "**Iterations:**" bullet at line 41, and the `## Step 3 — Build the PR` heading at line 43)

- [ ] **Step 1: Insert the Step 2.5 section**

Insert the following between the end of Step 2 and the `## Step 3 — Build the PR` heading:

```markdown
## Step 2.5 — Spec gap analysis

> Skip this step entirely if `--no-gaps` was passed, and omit the "Spec Gap Analysis" section from the body.

Compare what the code on the branch actually does against the spec it was built from, so the reviewer knows exactly where to push back, comment, or reject.

### Find the spec source(s)

If `--spec <value>` was passed, use only that source and skip auto-discovery. Otherwise check all of the following and use **every formal source you find** (typically 0–2), attributing each in the output:

1. **Plan/spec `.md` files** — design docs or implementation plans created or referenced in this session (e.g. `docs/specs/*.md`, `docs/superpowers/specs/*.md`), and the approved plan if this session used plan mode.
2. **Jira ticket** — look for a key (e.g. `PROJ-123`) in the branch name, commit messages, or the conversation. If found and Jira tools (e.g. an Atlassian MCP server) are available, fetch the issue's description and acceptance criteria. If a key is found but no Jira tools are connected, ask the user to paste the ticket text; if they decline, list the ticket in the output as "detected but not fetched".
3. **GitHub issue** — look for `#N` / `fixes #N` / `closes #N` in the branch name, commit messages, or conversation, and fetch it with `gh issue view <N>`.
4. **Fallback — session prompts**: if no formal source exists, the user's own prompts in this conversation are the implicit spec. The output must state both that no formal spec was found *and* that the analysis ran against session prompts.

### Compare spec vs. diff — grounding rules

You wrote this code, so you are grading your own homework. Guard against the two failure modes — bias toward "no gaps", and analyzing from memory instead of artifacts:

- **Freshly read the actual spec text.** Read the `.md` file contents with the Read tool; use the fetched ticket description verbatim. Never rely on the conversation's memory of what the spec said.
- **Compare against the actual Step-1 diff** — what the code does, not what the session says was done.
- **Hunt for divergences.** Go item by item through the spec and check each one against the diff. "No divergences" must be earned by this pass, never assumed.

Classify each divergence found:

| Category | Meaning |
|----------|---------|
| Missing  | In the spec, not in the code |
| Deviated | Implemented differently than specified — note why, if the session shows the reason |
| Extra    | In the code, not in the spec — scope creep; flag for reviewer attention |
| Partial  | Started but incomplete (e.g. happy path done, error handling skipped) |
```

- [ ] **Step 2: Verify the file renders correctly**

Run: `sed -n '40,100p' commands/create-pr.md`
Expected: Step 2 → Step 2.5 → Step 3 appear in order, tables intact.

- [ ] **Step 3: Commit**

```bash
git add commands/create-pr.md
git commit -m "feat: add spec discovery and gap analysis step to /create-pr"
```

---

### Task 3: Add the Spec Gap Analysis section to the PR body template

**Files:**
- Modify: `commands/create-pr.md` (the body template inside `## Step 3 — Build the PR`)

- [ ] **Step 1: Insert the section into the template**

In the Step 3 fenced template, insert the following between the `**Iterations:** <what changed between attempts, or "none">` line and the `## Test plan` line:

```markdown
## Spec Gap Analysis

**Spec source(s):** <comma-separated, e.g. `PROJ-123 (Jira), docs/specs/auth-design.md` — or "No formal spec found — analyzed against session prompts">

| Category | Gap | Details |
|----------|-----|---------|
| <Missing/Deviated/Extra/Partial> | <short name> | <what diverged + where in the spec> |

<if no divergences were found, replace the table with:>
No divergences detected — reviewer should still verify against <source(s)>.
```

(Keep a blank line before `## Test plan`.)

- [ ] **Step 2: Commit**

```bash
git add commands/create-pr.md
git commit -m "feat: add Spec Gap Analysis section to PR body template"
```

---

### Task 4: Update the Notes section

**Files:**
- Modify: `commands/create-pr.md:90-95` (the `## Notes` section)

- [ ] **Step 1: Update the passthrough note and add framing notes**

Replace:

```markdown
- If the user provides arguments (e.g. `/create-pr --base develop` or `/create-pr --draft`), pass them through to `gh pr create` — only `--dry-run` / `--preview` are consumed as modes.
```

with:

```markdown
- If the user provides arguments (e.g. `/create-pr --base develop` or `/create-pr --draft`), pass them through to `gh pr create` — only `--dry-run` / `--preview` / `--spec <value>` / `--no-gaps` are consumed by this command.
- The Spec Gap Analysis is informational only — it never blocks PR creation. Frame gaps as potential divergences for the reviewer to verify; never assert an authoritative "matches spec".
```

- [ ] **Step 2: Commit**

```bash
git add commands/create-pr.md
git commit -m "feat: document gap-analysis flags and framing in /create-pr notes"
```

---

### Task 5: Document the feature in the README

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Add a feature section after "What reviewers get"**

Insert the following after the AI Session Context example code block (after `README.md:29`) and before `## Requirements`:

```markdown
## Spec Gap Analysis

Every PR also includes a **Spec Gap Analysis** — the command finds the spec the work was built from (a design/plan `.md` from the session, a Jira ticket detected from the branch name, a linked GitHub issue, or — if nothing formal exists — the session prompts themselves), re-reads it, and compares it against the actual branch diff:

​```
## Spec Gap Analysis

**Spec source(s):** PROJ-123 (Jira), docs/specs/auth-design.md

| Category | Gap | Details |
|----------|-----|---------|
| Missing  | Rate limiting on retry | Spec §3 requires backoff; not in diff |
| Deviated | Redis instead of in-memory | User approved mid-session |
| Extra    | Added /health endpoint | Not in spec — flag for review |
| Partial  | Error handling | Happy path only; timeout case unhandled |
​```

Gaps are framed as potential divergences for the reviewer to verify — so the reviewer knows exactly where to comment or push back.
```

(The inner code fence must be a real triple-backtick fence; shown here with zero-width separators only so this plan renders.)

- [ ] **Step 2: Add the new flags to the Usage section**

In the `## Usage` section, after the `--dry-run` example block, insert:

```markdown
Point the gap analysis at a specific spec, or skip it:

​```
/create-pr --spec docs/specs/auth-design.md
/create-pr --spec PROJ-123
/create-pr --no-gaps
​```
```

(Same note: real triple-backtick fence in the actual README.)

- [ ] **Step 3: Verify rendering**

Run: `grep -n "Spec Gap Analysis\|--no-gaps\|--spec" README.md`
Expected: matches in the new feature section and the Usage section.

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "docs: document Spec Gap Analysis feature in README"
```

---

### Task 6: Manual end-to-end verification

**Files:** none (verification only)

- [ ] **Step 1: Dry-run against this very branch**

In a Claude Code session on this repo's feature branch, run `/create-pr --dry-run` and confirm the printed body contains a `## Spec Gap Analysis` section that:
- names `docs/superpowers/specs/2026-06-04-spec-gap-analysis-design.md` as a spec source
- contains either a populated gap table or the "No divergences detected" line

- [ ] **Step 2: Check the flag paths**

Run `/create-pr --dry-run --no-gaps` → body must contain no `## Spec Gap Analysis` section.
Run `/create-pr --dry-run --spec docs/superpowers/specs/2026-06-04-spec-gap-analysis-design.md` → spec source line must list only that file.

- [ ] **Step 3: Report results**

Report each scenario's outcome to the user honestly — if a scenario misbehaves, fix the command text and re-verify before claiming done.

Note: the spec's remaining scenarios (Jira key in branch name with/without MCP, GitHub issue reference, no-spec prompt fallback) require a repo/branch with those artifacts and can't be exercised here — report them as untested rather than verified.
