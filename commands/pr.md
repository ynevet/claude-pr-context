---
description: Create a GitHub PR with AI session context included in the description
---

Create a GitHub Pull Request for the current branch. Your output must include both a technical summary of the changes AND a curated summary of how this work was done in this AI session.

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

Run `gh pr create` using a heredoc to pass the body, for example:

```
gh pr create --title "the title" --body "$(cat <<'EOF'
<body here>
EOF
)"
```

## Notes

- If the user provides arguments (e.g. `/pr --base develop`), pass them through to `gh pr create`.
- The AI Session Context section exists for reviewers who want to understand the AI-assisted workflow — be thorough and honest. A reviewer should be able to reconstruct the intent and key moments of the session from this section alone.
- If the session was short and straightforward, say so. Don't invent decisions or iterations.
- Confirm the PR URL at the end.
