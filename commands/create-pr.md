---
description: Create a GitHub PR with AI session context included in the description
---

Create a GitHub Pull Request for the current branch. Your output must include both a technical summary of the changes AND a curated summary of how this work was done in this AI session.

## Modes

Inspect the arguments for a mode flag before doing anything else:

- **`--dry-run` / `--preview`**: Run Steps 0–3 normally (preflight, understand the changes, extract session context, build the title and body), then **stop**. Instead of creating the PR, print the full title and the rendered body to the user for review — do NOT run `gh pr create`. End by noting they can re-run without the flag to create it for real.
- **No mode flag** (default): Run all steps, including Step 4, to create the PR.

Strip `--dry-run` / `--preview` out before passing the remaining arguments through to `gh pr create`. Every other flag (e.g. `--draft`, `--base`, `--reviewer`) passes through untouched (see Notes).

## Step 0 — Preflight checks

Before doing anything else, confirm there's actually something to PR:

1. **In a git repo?** Run `git rev-parse --is-inside-work-tree`. If it fails, stop and tell the user this command must be run inside a git repository.
2. **Branch ahead of base?** Determine the base (`origin/HEAD`, else `main`/`master`) and run `git rev-list --count $(git merge-base HEAD <base>)..HEAD`. If it's `0`, stop and tell the user the branch has no commits ahead of the base — there's nothing to open a PR for.
3. **Existing PR?** Run `gh pr view --json url,state 2>/dev/null`. If a PR already exists for this branch, do NOT create a new one. Instead, build the title/body as normal and **update** the existing PR with `gh pr edit --body "..."` (and `--title` if it changed), then tell the user you updated the existing PR rather than creating a new one. In `--dry-run` mode, just note that an existing PR was found and would be updated.

## Step 1 — Understand the changes

Run these to understand what's on the branch:
- `git log $(git merge-base HEAD origin/HEAD)..HEAD --oneline` (commits)
- `git diff $(git merge-base HEAD origin/HEAD)..HEAD` (full diff)

If `origin/HEAD` is not available, fall back to `main` or `master`.

## Step 2 — Extract session context from this conversation

Look back through the entire current conversation and extract:

- **Intent**: One sentence — what the user was ultimately trying to accomplish
- **Key prompts**: The user's actual words, verbatim or near-verbatim. Include corrections and direction changes — don't sanitize them. These are the most valuable part for reviewers.
- **Skills invoked**: Any `/skill` commands used (e.g. `/simplify`, `/security-review`). Note when/why each was used.
- **Key decisions**: Non-obvious choices and their rationale. Focus on tradeoffs, things that could have gone differently, constraints that shaped the approach.
- **Files touched**: Files read, created, or modified — in the order they were worked on.
- **Iterations**: Pivots, revisions, or "actually do it this way" moments. If none, say so.

## Step 3 — Build the PR

Generate a title (under 70 chars, conventional commits style: `fix:`, `feat:`, `refactor:`, etc.) and body using this exact structure:

```
## Summary
- <bullet: what changed>
- <bullet: what changed>

## AI Session Context

**Intent:** <one sentence>

**Key prompts:**
- "<verbatim prompt>"
- "<verbatim prompt>"

**Skills used:** <comma-separated list, or "none">

**Key decisions:**
- <decision> — <rationale>

**Files touched:** <comma-separated, in order>

**Iterations:** <what changed between attempts, or "none">

## Test plan
- [ ] <item>
- [ ] <item>

🤖 Generated with [Claude Code](https://claude.ai/claude-code)
```

## Step 4 — Create the PR

> Skip this step entirely in `--dry-run` / `--preview` mode — print the title and body instead and stop.
> If Step 0 found an existing PR, use `gh pr edit` here instead of `gh pr create`.

Run `gh pr create` using a heredoc to pass the body, for example:

```
gh pr create --title "the title" --body "$(cat <<'EOF'
<body here>
EOF
)"
```

## Notes

- If the user provides arguments (e.g. `/create-pr --base develop` or `/create-pr --draft`), pass them through to `gh pr create` — only `--dry-run` / `--preview` are consumed as modes.
- The AI Session Context section exists for reviewers who want to understand the AI-assisted workflow — be thorough and honest. A reviewer should be able to reconstruct the intent and key moments of the session from this section alone.
- If the session was short and straightforward, say so. Don't invent decisions or iterations.
- Confirm the PR URL at the end.
