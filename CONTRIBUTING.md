# Contributing

## What to contribute

- Improvements to the `/pr` command prompt (`commands/pr.md`)
- Better install scripts
- README clarifications
- Bug reports and feature requests via Issues

## How to test a change

The command is a markdown file that Claude Code loads as a prompt. To test a change:

1. Copy your modified `commands/pr.md` to `~/.claude/commands/pr.md`
2. Open a real repo in Claude Code that has uncommitted changes or a branch ahead of main
3. Run `/pr` and verify the generated PR description looks correct
4. Check that the AI Session Context section is populated accurately

## Submitting a PR

Use the `/pr` command itself to open your pull request. The PR template will prompt you for the AI session context — fill it in honestly. That's the whole point.

## Keeping it simple

The command is intentionally one file. Avoid adding dependencies, configuration files, or abstractions. If a change requires more than editing `commands/pr.md`, think carefully about whether it belongs here.
