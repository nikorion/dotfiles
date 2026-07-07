<#
    Recree les liens symboliques vers les fichiers de ce depot, a leurs
    emplacements d'origine attendus par chaque logiciel.

    Fonctionnement : affiche d'abord un APERCU de ce qui serait fait (rien
    n'est modifie), demande confirmation, puis applique et affiche le
    resultat reel. Utiliser -Force pour sauter la confirmation.

    Necessite le Mode developpeur actif (ou une session admin) pour la
    creation de liens symboliques sans elevation.
#>
param(
    [switch]$Force
)
$ErrorActionPreference = "Stop"
$Repo = $PSScriptRoot

function Test-Installed {
    param($Check)
    if (-not $Check) { return $true }
    switch ($Check.Type) {
        "Command"  { return [bool](Get-Command $Check.Value -ErrorAction SilentlyContinue) }
        "Path"     { return (Test-Path -LiteralPath $Check.Value) }
        "Appx"     { return [bool](Get-AppxPackage -Name $Check.Value -ErrorAction SilentlyContinue) }
        "Registry" {
            $roots = @(
                "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
                "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
                "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
            )
            foreach ($r in $roots) {
                $hit = Get-ItemProperty $r -ErrorAction SilentlyContinue |
                    Where-Object { $_.DisplayName -like $Check.Value }
                if ($hit) { return $true }
            }
            return $false
        }
    }
    return $false
}

# Etat actuel, sans rien modifier : ABSENT (pas dans le depot), DEJA_LIE,
# CONFLIT (fichier non-lien present), ou TODO (a creer).
function Get-LinkPlan {
    param($Target, $Link)
    if (-not (Test-Path -LiteralPath $Link)) { return "ABSENT" }
    if (Test-Path -LiteralPath $Target) {
        $existing = Get-Item -LiteralPath $Target -Force
        if ($existing.LinkType -eq "SymbolicLink") { return "DEJA_LIE" }
        return "CONFLIT"
    }
    return "TODO"
}

function New-Link {
    param($Target, $Link)
    try {
        $parent = Split-Path $Target -Parent
        if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        New-Item -ItemType SymbolicLink -Path $Target -Target $Link -ErrorAction Stop | Out-Null
        return "CREE"
    } catch {
        return "ERREUR"
    }
}

$groups = @(
    @{ Name = "Git";            Check = @{Type="Command";  Value="git"};             Files = @(
        @{ target = "$env:USERPROFILE\.gitconfig"; link = "$Repo\git\.gitconfig" } ) }
    @{ Name = "OpenSSH (config)";Check = @{Type="Command";  Value="ssh"};             Files = @(
        @{ target = "$env:USERPROFILE\.ssh\config"; link = "$Repo\ssh\config" } ) }
    @{ Name = "PowerShell";      Check = $null;                                       Files = @(
        @{ target = "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"; link = "$Repo\powershell\Microsoft.PowerShell_profile.ps1" } ) }
    @{ Name = "Windows Terminal";Check = @{Type="Appx";     Value="Microsoft.WindowsTerminal*"}; Files = @(
        @{ target = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"; link = "$Repo\windows-terminal\settings.json" } ) }
    @{ Name = "VSCode";          Check = @{Type="Command";  Value="code"};            Files = @(
        @{ target = "$env:APPDATA\Code\User\settings.json"; link = "$Repo\vscode\settings.json" } ) }
    @{ Name = "Scoop";           Check = @{Type="Command";  Value="scoop"};           Files = @(
        @{ target = "$env:USERPROFILE\.config\scoop\config.json"; link = "$Repo\scoop\config.json" } ) }
    @{ Name = "Claude Code";     Check = @{Type="Command";  Value="claude"};          Files = @(
        @{ target = "$env:USERPROFILE\.claude\CLAUDE.md";    link = "$Repo\claude\CLAUDE.md" }
        @{ target = "$env:USERPROFILE\.claude\guides";       link = "$Repo\claude\guides" }
        @{ target = "$env:USERPROFILE\.claude\agents";       link = "$Repo\claude\agents" }
        @{ target = "$env:USERPROFILE\.claude\settings.json";link = "$Repo\claude\settings.json" } ) }
    @{ Name = "Notepad++";       Check = @{Type="Registry";  Value="*Notepad++*"};    Files = @(
        @{ target = "$env:APPDATA\Notepad++\config.xml";         link = "$Repo\notepad++\config.xml" }
        @{ target = "$env:APPDATA\Notepad++\contextMenu.xml";    link = "$Repo\notepad++\contextMenu.xml" }
        @{ target = "$env:APPDATA\Notepad++\shortcuts.xml";      link = "$Repo\notepad++\shortcuts.xml" }
        @{ target = "$env:APPDATA\Notepad++\stylers.xml";        link = "$Repo\notepad++\stylers.xml" }
        @{ target = "$env:APPDATA\Notepad++\userDefineLang.xml"; link = "$Repo\notepad++\userDefineLang.xml" } ) }
    @{ Name = "FileZilla";       Check = @{Type="Registry";  Value="*FileZilla*"};    Files = @(
        @{ target = "$env:APPDATA\FileZilla\sitemanager.xml"; link = "$Repo\filezilla\sitemanager.xml" }
        @{ target = "$env:APPDATA\FileZilla\filezilla.xml";   link = "$Repo\filezilla\filezilla.xml" }
        @{ target = "$env:APPDATA\FileZilla\bookmarks.xml";   link = "$Repo\filezilla\bookmarks.xml" }
        @{ target = "$env:APPDATA\FileZilla\layout.xml";      link = "$Repo\filezilla\layout.xml" } ) }
)

# ---------------------------------------------------------------- helpers TUI
function Write-Banner($text, $color) {
    $width = [Math]::Max(66, $text.Length + 6)
    Write-Host ""
    Write-Host ("┌" + ("─" * ($width - 2)) + "┐") -ForegroundColor $color
    Write-Host ("│ " + $text.PadRight($width - 4) + " │") -ForegroundColor $color
    Write-Host ("└" + ("─" * ($width - 2)) + "┘") -ForegroundColor $color
    Write-Host ""
}

function Get-NameWidth { [Math]::Max(14, ($groups | ForEach-Object { $_.Name.Length } | Measure-Object -Maximum).Maximum + 2) }

$nameWidth = Get-NameWidth

function Write-TableHeader($col2Title) {
    Write-Host ("  {0}  {1,-13} {2}" -f "Application".PadRight($nameWidth), "Détectée", $col2Title) -ForegroundColor DarkGray
    Write-Host ("  " + ("─" * ($nameWidth + 45))) -ForegroundColor DarkGray
}

function Get-DetLabel($installed, $check) {
    if ($null -eq $check) { return @{ Label = "n/a";   Color = "DarkGray" } }
    if ($installed)       { return @{ Label = "✓ oui";  Color = "Green" } }
    return @{ Label = "✗ non"; Color = "Yellow" }
}

# Detecte un lancement par double-clic / "Executer avec PowerShell" (la
# fenetre se ferme sinon dès la fin du script, sans que rien ne soit lisible).
function Test-LaunchedFromExplorer {
    try {
        $parentId = (Get-CimInstance Win32_Process -Filter "ProcessId=$PID" -ErrorAction Stop).ParentProcessId
        $parentName = (Get-Process -Id $parentId -ErrorAction Stop).ProcessName
        return $parentName -eq 'explorer'
    } catch { return $false }
}

try {

# ---------------------------------------------------------------- 1) aperçu
Write-Banner ".dotfiles — aperçu" "Cyan"
Write-TableHeader "Action prévue"

$plan = @()
$planTodo = 0; $planAlready = 0; $planConflit = 0; $planAbsent = 0
foreach ($g in $groups) {
    $installed = Test-Installed $g.Check
    $statuses = $g.Files | ForEach-Object { Get-LinkPlan -Target $_.target -Link $_.link }
    $plan += , @{ Group = $g; Installed = $installed; Statuses = $statuses }

    foreach ($s in $statuses) {
        switch ($s) {
            "TODO"     { $planTodo++ }
            "DEJA_LIE" { $planAlready++ }
            "CONFLIT"  { $planConflit++ }
            "ABSENT"   { $planAbsent++ }
        }
    }

    $det = Get-DetLabel $installed $g.Check
    if ($statuses -contains "CONFLIT") {
        $actLabel = "⚠ conflit (fichier existant non-lien)"; $actColor = "Red"
    } elseif ($statuses -contains "ABSENT") {
        $actLabel = "⚠ config absente du dépôt"; $actColor = "Red"
    } elseif ($statuses -contains "TODO") {
        $n = ($statuses | Where-Object { $_ -eq "TODO" }).Count
        $actLabel = "→ sera créé ($n)"; $actColor = "Cyan"
    } else {
        $actLabel = "• déjà en place"; $actColor = "DarkGray"
    }

    Write-Host ("  {0}  " -f $g.Name.PadRight($nameWidth)) -NoNewline
    Write-Host ("{0,-13} " -f $det.Label) -NoNewline -ForegroundColor $det.Color
    Write-Host $actLabel -ForegroundColor $actColor
}

Write-Host ""
Write-Host ("  " + ("─" * ($nameWidth + 45))) -ForegroundColor DarkGray
Write-Host ("  {0} lien(s) à créer · {1} déjà en place · {2} conflit(s) · {3} config(s) absente(s)" -f $planTodo, $planAlready, $planConflit, $planAbsent) -ForegroundColor DarkGray

if ($planConflit -gt 0 -or $planAbsent -gt 0) {
    Write-Host "  Les conflits et configs absentes ne seront pas touchés automatiquement." -ForegroundColor DarkYellow
}

if ($planTodo -eq 0) {
    Write-Host "`nRien à faire : tout est déjà en place." -ForegroundColor Green
    Write-Host ""
    return
}

# ---------------------------------------------------------------- 2) confirmation
if (-not $Force) {
    Write-Host ""
    $resp = Read-Host "Créer les $planTodo lien(s) manquant(s) ? (o/N)"
    if ($resp -notmatch '^(o|oui|y|yes)$') {
        Write-Host "`nAnnulé — aucun changement effectué." -ForegroundColor Yellow
        Write-Host ""
        return
    }
}

# ---------------------------------------------------------------- 3) application
Write-Banner ".dotfiles — résultat" "Green"
Write-TableHeader "Résultat"

$countCree = 0; $countDejaLie = 0; $countAbsent = 0; $countErreur = 0; $countConflit = 0
$countInstalled = 0; $countMissing = 0

foreach ($p in $plan) {
    $g = $p.Group
    if ($p.Installed) { $countInstalled++ } else { $countMissing++ }

    $results = @()
    foreach ($f in $g.Files) {
        $planStatus = Get-LinkPlan -Target $f.target -Link $f.link
        if ($planStatus -eq "TODO") {
            $results += New-Link -Target $f.target -Link $f.link
        } else {
            $results += $planStatus
        }
    }

    foreach ($s in $results) {
        switch ($s) {
            "CREE"     { $countCree++ }
            "DEJA_LIE" { $countDejaLie++ }
            "ABSENT"   { $countAbsent++ }
            "ERREUR"   { $countErreur++ }
            "CONFLIT"  { $countConflit++ }
        }
    }

    $det = Get-DetLabel $p.Installed $g.Check
    if ($results -contains "ERREUR") {
        $actLabel = "✗ erreur"; $actColor = "Red"
    } elseif ($results -contains "CONFLIT") {
        $actLabel = "⚠ conflit (fichier existant non-lien)"; $actColor = "Red"
    } elseif ($results -contains "ABSENT") {
        $actLabel = "⚠ config absente du dépôt"; $actColor = "Red"
    } elseif ($results -contains "CREE") {
        $n = ($results | Where-Object { $_ -eq "CREE" }).Count
        $actLabel = "✓ lien créé ($n)"; $actColor = "Green"
    } else {
        $actLabel = "• déjà en place"; $actColor = "DarkGray"
    }

    Write-Host ("  {0}  " -f $g.Name.PadRight($nameWidth)) -NoNewline
    Write-Host ("{0,-13} " -f $det.Label) -NoNewline -ForegroundColor $det.Color
    Write-Host $actLabel -ForegroundColor $actColor
}

Write-Host ""
Write-Host ("  " + ("─" * ($nameWidth + 45))) -ForegroundColor DarkGray
Write-Host ("  {0} applis détectées installées · {1} non installées (config restaurée quand même)" -f $countInstalled, $countMissing) -ForegroundColor DarkGray
Write-Host ("  {0} lien(s) créé(s) · {1} déjà en place · {2} conflit(s) · {3} config(s) absente(s) · {4} erreur(s)" -f $countCree, $countDejaLie, $countConflit, $countAbsent, $countErreur) -ForegroundColor DarkGray
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
