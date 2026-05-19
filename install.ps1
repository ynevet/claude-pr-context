$commandsDir = "$env:USERPROFILE\.claude\commands"
$commandUrl = "https://raw.githubusercontent.com/ynevet/claude-pr-context/master/commands/pr.md"

New-Item -ItemType Directory -Force $commandsDir | Out-Null
Invoke-WebRequest -Uri $commandUrl -OutFile "$commandsDir\pr.md"

Write-Host "Done. /pr command installed to $commandsDir\pr.md"
Write-Host "Restart Claude Code, then use /pr to open a PR with AI session context."
