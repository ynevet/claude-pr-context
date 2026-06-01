$commandsDir = "$env:USERPROFILE\.claude\commands"
$commandUrl = "https://raw.githubusercontent.com/ynevet/claude-pr-context/master/commands/create-pr.md"

New-Item -ItemType Directory -Force $commandsDir | Out-Null
Invoke-WebRequest -Uri $commandUrl -OutFile "$commandsDir\create-pr.md"

Write-Host "Done. /create-pr command installed to $commandsDir\create-pr.md"
Write-Host "Restart Claude Code, then use /create-pr to open a PR with AI session context."
