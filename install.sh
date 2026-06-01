#!/bin/bash
set -e

COMMANDS_DIR="$HOME/.claude/commands"
COMMAND_URL="https://raw.githubusercontent.com/ynevet/claude-pr-context/master/commands/create-pr.md"

mkdir -p "$COMMANDS_DIR"
curl -fsSL "$COMMAND_URL" -o "$COMMANDS_DIR/create-pr.md"

echo "Done. /create-pr command installed to $COMMANDS_DIR/create-pr.md"
echo "Restart Claude Code, then use /create-pr to open a PR with AI session context."
