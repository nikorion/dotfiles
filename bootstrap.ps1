<#
    Point d'entree unique pour une nouvelle machine : clone les depots
    GitHub manquants (dotfiles, app-configs) puis enchaine les restore.ps1
    de .dotfiles, .app-configs et .secrets.

    .secrets n'a pas de remote (jamais publie) : ce depot doit deja avoir
    ete copie manuellement a cote des deux autres (cle USB, Nextcloud...)
    avant de lancer ce script. S'il est absent, son etape est juste
    signalee et sautee.

    Usage :
        .\bootstrap.ps1            (clone + demande confirmation dans chaque restore.ps1)
        .\bootstrap.ps1 -Force     (saute aussi les confirmations)
#>
param(
    [switch]$Force,
    [string]$Root = $HOME
)
$ErrorActionPreference = "Stop"

$repos = @(
    @{ Name = "dotfiles";    Path = Join-Path $Root ".dotfiles";    Url = "https://github.com/nikorion/dotfiles.git" }
    @{ Name = "app-configs"; Path = Join-Path $Root ".app-configs"; Url = "https://github.com/nikorion/app-configs.git" }
)

function Write-Banner($text, $color) {
    $width = [Math]::Max(66, $text.Length + 6)
    Write-Host ""
    Write-Host ("┌" + ("─" * ($width - 2)) + "┐") -ForegroundColor $color
    Write-Host ("│ " + $text.PadRight($width - 4) + " │") -ForegroundColor $color
    Write-Host ("└" + ("─" * ($width - 2)) + "┘") -ForegroundColor $color
    Write-Host ""
}

function Test-LaunchedFromExplorer {
    try {
        $parentId = (Get-CimInstance Win32_Process -Filter "ProcessId=$PID" -ErrorAction Stop).ParentProcessId
        $parentName = (Get-Process -Id $parentId -ErrorAction Stop).ProcessName
        return $parentName -eq 'explorer'
    } catch { return $false }
}

try {

Write-Banner "bootstrap — clonage des depots" "Cyan"

foreach ($r in $repos) {
    if (Test-Path -LiteralPath $r.Path) {
        Write-Host ("  {0,-14} deja present ({1})" -f $r.Name, $r.Path) -ForegroundColor DarkGray
        continue
    }
    Write-Host ("  {0,-14} clonage..." -f $r.Name) -ForegroundColor Cyan
    if (Get-Command gh -ErrorAction SilentlyContinue) {
        gh repo clone "nikorion/$($r.Name)" $r.Path
    } else {
        git clone $r.Url $r.Path
    }
}

$secretsPath = Join-Path $Root ".secrets"
if (-not (Test-Path -LiteralPath $secretsPath)) {
    Write-Host ""
    Write-Host "  ⚠ .secrets absent — pas de remote git, doit etre copie manuellement" -ForegroundColor Yellow
    Write-Host "    (cle USB, Nextcloud...) avant de relancer ce script pour cette etape." -ForegroundColor Yellow
}

Write-Banner "bootstrap — restauration" "Cyan"

$steps = @(
    @{ Name = "dotfiles";    Path = Join-Path $Root ".dotfiles" }
    @{ Name = "app-configs"; Path = Join-Path $Root ".app-configs" }
    @{ Name = "secrets";     Path = $secretsPath }
)

foreach ($s in $steps) {
    $script = Join-Path $s.Path "restore.ps1"
    if (-not (Test-Path -LiteralPath $script)) {
        Write-Host ("  {0,-14} restore.ps1 introuvable, ignore" -f $s.Name) -ForegroundColor DarkGray
        continue
    }
    Write-Host ("  → {0}" -f $s.Name) -ForegroundColor Cyan
    if ($Force) { & $script -Force } else { & $script }
}

Write-Host ""
Write-Host "Termine." -ForegroundColor Green
Write-Host ""

} catch {
    Write-Host ""
    Write-Host "✗ Erreur inattendue : $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
} finally {
    if (Test-LaunchedFromExplorer) {
        Write-Host "Appuie sur une touche pour fermer..." -ForegroundColor DarkGray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}
