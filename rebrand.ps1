$ErrorActionPreference = 'Continue'
$root = "c:\Users\33627\Downloads\multica-main\multica-main"
Set-Location $root

$files = Get-ChildItem -Path $root -Recurse -File -Include *.go,*.ts,*.tsx,*.js,*.jsx,*.json,*.yaml,*.yml,*.md,*.html,*.css,*.sh,*.ps1,*.mjs,*.cjs,*.mts | Where-Object {
    $_.FullName -notmatch '[\\/](\.git|node_modules|\.next|dist|\.turbo|\.vercel)[\\/]' -and
    $_.Name -ne 'pnpm-lock.yaml' -and
    $_.Name -ne 'go.sum' -and
    $_.Name -ne 'skills-lock.json' -and
    $_.Name -ne 'rebrand.ps1'
}

# Also add Makefile, Dockerfile, LICENSE, .env files, entrypoint.sh
$extras = @(
    "$root\Makefile",
    "$root\Dockerfile",
    "$root\Dockerfile.web",
    "$root\LICENSE",
    "$root\docker\entrypoint.sh"
)
$extraFiles = $extras | Where-Object { Test-Path $_ } | ForEach-Object { Get-Item $_ }
$files = @($files) + @($extraFiles)

Write-Host "Processing $($files.Count) files..."

$changed = 0
$goModuleOld = 'github.com/multica-ai/multica/server'

# Ordered replacements as array of pairs - specific patterns first, then generic
$replacements = @(
    ,@('multica-static.copilothub.ai', 'aurion-static.copilothub.ai')
    ,@('app.multica.ai', 'app.aurion.studio')
    ,@('www.multica.ai', 'www.aurion.studio')
    ,@('api.multica.ai', 'api.aurion.studio')
    ,@('multica.ai', 'aurion.studio')
    ,@('ai.multica.desktop.dev', 'studio.aurion.desktop.dev')
    ,@('ai.multica.desktop', 'studio.aurion.desktop')
    ,@('multica://', 'aurion://')
    ,@('multica-ai/tap/multica', 'aurion-ai/tap/aurion')
    ,@('multica-ai/scoop-bucket', 'aurion-ai/scoop-bucket')
    ,@('multica-ai/multica', 'aurion-ai/aurion')
    ,@('@multica/', '@aurion/')
    ,@('MULTICA_', 'AURION_')
    ,@('multica_auth', 'aurion_auth')
    ,@('multica_csrf', 'aurion_csrf')
    ,@('multica_logged_in', 'aurion_logged_in')
    ,@('multica-locale', 'aurion-locale')
    ,@('multica_token', 'aurion_token')
    ,@('multica_comment_collapse', 'aurion_comment_collapse')
    ,@('multica_issues_view', 'aurion_issues_view')
    ,@('multica_recent_issues', 'aurion_recent_issues')
    ,@('multica_my_issues_view', 'aurion_my_issues_view')
    ,@('multica_issues_scope', 'aurion_issues_scope')
    ,@('multica_issue_draft', 'aurion_issue_draft')
    ,@('multica_tabs', 'aurion_tabs')
    ,@('multica_inbox_layout', 'aurion_inbox_layout')
    ,@('multica_inbox_issue_detail_layout', 'aurion_inbox_issue_detail_layout')
    ,@('multica_agents_layout', 'aurion_agents_layout')
    ,@('multica_skills_layout', 'aurion_skills_layout')
    ,@('multica:chat:', 'aurion:chat:')
    ,@('multica:navigate', 'aurion:navigate')
    ,@('Multica-Agent', 'Aurion-Agent')
    ,@('multica-agent-sdk', 'aurion-agent-sdk')
    ,@('multica-agent', 'aurion-agent')
    ,@('MulticaAI', 'AurionAI')
    ,@('MulticaIcon', 'AurionIcon')
    ,@('MulticaIconProps', 'AurionIconProps')
    ,@('MulticaLanding', 'AurionLanding')
    ,@('multica-landing', 'aurion-landing')
    ,@('@multica_hq', '@aurion_hq')
    ,@('multica-sandbox', 'aurion-sandbox')
    ,@('/.multica/', '/.aurion/')
    ,@('\.multica\', '\.aurion\')
    ,@('~/.multica', '~/.aurion')
    ,@('%USERPROFILE%\.multica', '%USERPROFILE%\.aurion')
    ,@('postgres://multica:multica@', 'postgres://aurion:aurion@')
    ,@('POSTGRES_DB: multica', 'POSTGRES_DB: aurion')
    ,@('POSTGRES_USER: multica', 'POSTGRES_USER: aurion')
    ,@('POSTGRES_PASSWORD: multica', 'POSTGRES_PASSWORD: aurion')
    ,@('POSTGRES_DB=multica', 'POSTGRES_DB=aurion')
    ,@('POSTGRES_USER=multica', 'POSTGRES_USER=aurion')
    ,@('POSTGRES_PASSWORD=multica', 'POSTGRES_PASSWORD=aurion')
    ,@('bin/multica', 'bin/aurion')
    ,@('cmd/multica', 'cmd/aurion')
    ,@('multica.exe', 'aurion.exe')
    ,@('./multica ', './aurion ')
    ,@('name: multica', 'name: aurion')
    ,@('noreply@multica', 'noreply@aurion')
    ,@('Multica, Inc.', 'Aurion, Inc.')
    ,@('Multica', 'Aurion')
    ,@('multica', 'aurion')
    ,@('MULTICA', 'AURION')
)

foreach ($file in $files) {
    try {
        $content = [System.IO.File]::ReadAllText($file.FullName)
        $original = $content
        
        foreach ($pair in $replacements) {
            $old = $pair[0]
            $new = $pair[1]
            if ($content.Contains($old)) {
                $content = $content.Replace($old, $new)
            }
        }
        
        if ($content -ne $original) {
            [System.IO.File]::WriteAllText($file.FullName, $content)
            $changed++
        }
    } catch {
        Write-Host "ERROR: $($file.FullName): $_"
    }
}

Write-Host "`nRebranded $changed files."

# Step 2: Fix Go module path - revert import paths back to original
# The Go module path must match the actual GitHub repo
Write-Host "`nFixing Go module imports..."
$goFiles = Get-ChildItem -Path "$root\server" -Recurse -File -Include *.go,*.mod | Where-Object {
    $_.FullName -notmatch '[\\/]vendor[\\/]'
}

$goFixed = 0
foreach ($file in $goFiles) {
    try {
        $content = [System.IO.File]::ReadAllText($file.FullName)
        $original = $content
        
        # Revert Go module path: aurion-ai/aurion/server -> multica-ai/multica/server
        $content = $content.Replace('github.com/aurion-ai/aurion/server', $goModuleOld)
        
        if ($content -ne $original) {
            [System.IO.File]::WriteAllText($file.FullName, $content)
            $goFixed++
        }
    } catch {
        Write-Host "ERROR: $($file.FullName): $_"
    }
}
Write-Host "Fixed Go imports in $goFixed files."
Write-Host "Done!"
