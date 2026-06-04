# Spec Gap Analysis for /create-pr — Design

**Date:** 2026-06-04
**Status:** Approved

## Problem

`/create-pr` tells reviewers *what* changed and *how* the AI session went, but not whether the code actually matches the plan/spec/ticket it was built from. Reviewers have to reconstruct that comparison themselves — or worse, assume the AI did what was asked. The PR description should surface the gaps between the implementation and its spec so the reviewer knows exactly where to push back, comment, or reject.

## Solution Overview

Add a **Spec Gap Analysis** step and PR-body section to the `/create-pr` command (`commands/create-pr.md`). The command discovers the spec source(s) for the branch, freshly reads them, compares them against the actual branch diff, and reports divergences in four categories: Missing, Deviated, Extra, Partial.

Everything stays in the single command file — the repo's distribution model ("copy one file") is unchanged.

## Spec Discovery (new Step 2.5)

Sources are checked in priority order. **All formal sources found are used** (typically 0–2), each attributed in the output:

1. **`--spec <path | JIRA-KEY | #issue>` argument** — explicit override; skip auto-discovery entirely and use only this source.
2. **Plan/spec `.md` files** — design docs or implementation plans created or referenced in this session (e.g. `docs/specs/*.md`, `docs/superpowers/specs/*.md`), and the approved plan from plan mode if the session used it.
3. **Jira ticket** — key auto-detected from branch name (`PROJ-123-...`), commit messages, or the conversation. Fetched via the Atlassian MCP if available. If a key is detected but no Jira MCP tools are connected, tell the user and offer to have them paste the ticket text; if they decline, note the ticket as detected-but-unfetched in the output.
4. **GitHub issue** — `#N` / `fixes #N` / `closes #N` in branch name, commit messages, or conversation; fetched via `gh issue view N` (no MCP required).
5. **Fallback — session prompts** — when no formal source exists, the user's own prompts in the conversation are the implicit spec. The output must state both that no formal spec was found *and* that the analysis ran against session prompts.

## Grounding Rules (the part that makes the feature trustworthy)

The agent writing the gap analysis is the same agent that wrote the code — it is grading its own homework. Two failure modes must be designed against: bias toward "no gaps," and analyzing from session narrative memory instead of the actual artifacts. Therefore the command must:

1. **Freshly read the actual spec text** — re-read the `.md` file contents, the fetched ticket description/acceptance criteria, the plan text. Never rely on the conversation's memory of what the spec said.
2. **Compare against the actual Step-1 diff** — what the code *does*, not what the session *says was done*.
3. **Hunt adversarially** — the instruction explicitly directs the model to actively look for divergences. "No gaps" must be earned by a real pass over spec items vs. diff, not assumed.
4. **Honest framing** — gaps are "potential divergences for the reviewer to verify." The section never asserts an authoritative "✅ matches spec." When nothing is found, the output is "No divergences detected — reviewer should still verify against `<source>`."

## Gap Categories

| Category | Meaning |
|----------|---------|
| Missing  | In the spec, not in the code |
| Deviated | Implemented, but differently than specified (note why, if known from the session) |
| Extra    | In the code, not in the spec — scope creep; flag for reviewer attention |
| Partial  | Started but incomplete (e.g. happy path done, error handling skipped) |

## PR Body Section

Placed between **AI Session Context** and **Test plan**:

```
## Spec Gap Analysis

**Spec source(s):** PROJ-123 (Jira), docs/specs/2026-06-04-auth-design.md
<or: "No formal spec found — analyzed against session prompts">

| Category | Gap | Details |
|----------|-----|---------|
| Missing  | Rate limiting on retry | Spec §3 requires backoff; not in diff |
| Deviated | Redis instead of in-memory | User approved mid-session |
| Extra    | Added /health endpoint | Not in spec — flag for review |
| Partial  | Error handling | Happy path only; timeout case unhandled |
```

When no divergences are found, the table is replaced with:

```
No divergences detected — reviewer should still verify against <source>.
```

## Flags

- `--no-gaps` — skip the analysis and omit the section entirely.
- `--spec <path | JIRA-KEY | #issue>` — explicitly set the spec source (overrides auto-discovery).
- Both are consumed by the command (stripped before passing remaining args to `gh pr create`), same as `--dry-run` / `--preview` today.

The feature is **always on** by default — its value is reviewers seeing it on every PR; `--no-gaps` is the escape hatch.

## Touchpoints

- `commands/create-pr.md` — new Step 2.5 (discovery + analysis), new PR body section in the Step 3 template, flag handling in Modes/Notes.
- `README.md` — new section explaining the feature with an example, updated usage lines for `--spec` / `--no-gaps`.

## Out of Scope

- Confluence as a source rides on the same "if Atlassian MCP is available" logic as Jira but is not separately specified — a Confluence page explicitly referenced in the session may be treated like a session `.md` spec.
- Blocking or warning behavior — the analysis is purely informational for the reviewer; it never prevents PR creation.
- Cross-session spec tracking — like the rest of the command, context is scoped to the current session.

## Testing

Manual verification via `--dry-run` across the scenarios: `.md` spec in session, Jira key in branch name (with and without MCP connected), GitHub issue reference, no spec at all (prompt fallback), `--spec` override, and `--no-gaps`.
