# claude-pr-context

A [Claude Code](https://claude.ai/claude-code) custom command that creates GitHub PRs with the AI session context baked into the description — so reviewers understand not just *what* changed, but *why*, and *how* the work was done with AI.

## What reviewers get

Every PR opened with `/pr` includes an **AI Session Context** section:

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
cp claude-pr-context/commands/pr.md ~/.claude/commands/pr.md
```

## Share with your team

Commit the command file into your repo so teammates get it automatically:

```bash
mkdir -p .claude/commands
cp ~/.claude/commands/pr.md .claude/commands/pr.md
git add .claude/commands/pr.md
git commit -m "add /pr command with AI session context"
```

Anyone who clones the repo can then use `/pr` — on macOS or Windows.

## Usage

```
/pr
```

Supports any `gh pr create` flags as arguments:

```
/pr --base develop
/pr --draft
```

## How it works

The `/pr` command runs inside Claude Code's context window, so Claude has access to the full conversation history of the current session. It extracts key prompts verbatim, surfaces non-obvious decisions and their rationale, lists files touched in order, and notes any iterations or pivots — then calls `gh pr create` with the enriched description.

> **Note:** Context is scoped to the current session. If work spanned multiple sessions, only the current session's context will be captured.

## License

MIT
