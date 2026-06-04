# claude-pr-context

A [Claude Code](https://claude.ai/claude-code) custom command that creates GitHub PRs with the AI session context baked into the description — so reviewers understand not just *what* changed, but *why*, and *how* the work was done with AI.

## What reviewers get

Every PR opened with `/create-pr` includes an **AI Session Context** section:

```
## AI Session Context

**Intent:** Fix auth middleware flagged by legal for non-compliant token storage

**Key prompts:**
- "the auth middleware stores session tokens in plain memory, legal flagged it — we need to move to encrypted storage"
- "keep the interface the same so callers don't need to change"
- "simplify the token lifecycle logic you just wrote"

**Skills used:** /simplify

**Key decisions:**
- Redis TTL over app-level expiry — simpler, survives process restarts
- Hard cutover, no in-flight session migration — legal confirmed acceptable
- Interface unchanged — user directive, no callers needed updating

**Files touched:** middleware/auth.go, store/redis.go, store/interface.go

**Iterations:** Initial impl used sync.Map, revised to Redis after user clarified persistence requirement
```

## Spec Gap Analysis

Every PR also includes a **Spec Gap Analysis** — the command finds the spec the work was built from (a design/plan `.md` from the session, a Jira ticket detected from the branch name, a linked GitHub issue, or — if nothing formal exists — the session prompts themselves), re-reads it, and compares it against the actual branch diff:

```
## Spec Gap Analysis

**Spec source(s):** PROJ-123 (Jira), docs/specs/auth-design.md

| Category | Gap | Details |
|----------|-----|---------|
| Missing  | Rate limiting on retry | Spec §3 requires backoff; not in diff |
| Deviated | Redis instead of in-memory | User approved mid-session |
| Extra    | Added /health endpoint | Not in spec — flag for review |
| Partial  | Error handling | Happy path only; timeout case unhandled |
```

Gaps are framed as potential divergences for the reviewer to verify — so the reviewer knows exactly where to comment or push back.

## Requirements

- [Claude Code](https://claude.ai/claude-code)
- [GitHub CLI (`gh`)](https://cli.github.com/) — authenticated

## Installation

**macOS / Linux**
```bash
curl -fsSL https://raw.githubusercontent.com/ynevet/claude-pr-context/master/install.sh | bash
```

**Windows (PowerShell)**
```powershell
irm https://raw.githubusercontent.com/ynevet/claude-pr-context/master/install.ps1 | iex
```

**Or clone and copy**
```bash
git clone https://github.com/ynevet/claude-pr-context
cp claude-pr-context/commands/create-pr.md ~/.claude/commands/create-pr.md
```

## Share with your team

Commit the command file into your repo so teammates get it automatically:

```bash
mkdir -p .claude/commands
cp ~/.claude/commands/create-pr.md .claude/commands/create-pr.md
git add .claude/commands/create-pr.md
git commit -m "add /create-pr command with AI session context"
```

Anyone who clones the repo can then use `/create-pr` — on macOS or Windows.

## Usage

```
/create-pr
```

Preview without creating the PR — builds the title and body, prints them, and stops:

```
/create-pr --dry-run
```

Point the gap analysis at a specific spec, or skip it:

```
/create-pr --spec docs/specs/auth-design.md
/create-pr --spec PROJ-123
/create-pr --no-gaps
```

Supports any `gh pr create` flags as arguments:

```
/create-pr --base develop
/create-pr --draft
```

## How it works

The `/create-pr` command runs inside Claude Code's context window, so Claude has access to the full conversation history of the current session. It extracts key prompts verbatim, surfaces non-obvious decisions and their rationale, lists files touched in order, and notes any iterations or pivots — then calls `gh pr create` with the enriched description.

> **Note:** Context is scoped to the current session. If work spanned multiple sessions, only the current session's context will be captured.

## License

MIT
