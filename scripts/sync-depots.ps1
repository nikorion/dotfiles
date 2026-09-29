<#
    Commit (et push si prevu) automatique des depots de config. Lance chaque
    jour par la tache planifiee "sync-depots" (voir README, section
    "Sauvegarde automatique des depots").

    - .dotfiles, .app-configs : commit + push vers origin (GitHub) et gitea.
    - raspberry               : commit + push vers gitea seulement (serveur perso, depot prive).
    - .secrets                : commit local seulement, jamais de push.

    Garde-fou : si le diff a commiter ressemble a un secret (cle privee,
    mot de passe/token/cle API renseigne), le commit est fait mais le push
    est bloque pour ce depot et signale dans le journal. Verifier, corriger
    (deplacer le fichier dans .secrets), puis pousser a la main.

    Journal : %LOCALAPPDATA%\sync-depots.log (ECHEC / ATTENTION = a traiter).
#>
$ErrorActionPreference = "Continue"
$env:GCM_INTERACTIVE = "never"      # jamais de fenetre d'identification en tache planifiee
$env:GIT_TERMINAL_PROMPT = "0"

$Log = Join-Path $env:LOCALAPPDATA "sync-depots.log"
$Depots = @(
    @{ Chemin = "$HOME\.dotfiles";    Push = @("origin", "gitea") }
    @{ Chemin = "$HOME\.app-configs"; Push = @("origin", "gitea") }
    @{ Chemin = "$HOME\raspberry";    Push = @("gitea") }
    @{ Chemin = "$HOME\.secrets";     Push = @() }
)
# Lignes ajoutees qui ressemblent a un secret renseigne
$MotifsSecret = @(
    '-----BEGIN [A-Z ]*PRIVATE KEY'
    '(?i)(pass(word|wd)?|secret|token|api[_-]?key)["'']?\s*[=:]\s*["'']?[^\s"'']{8,}'
    '^Own='
    '(?i)<Pass\b'
)

function Write-Log($msg) { Add-Content -Path $Log -Value ("{0} {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $msg) -Encoding utf8 }

Write-Log "=== debut ==="
foreach ($d in $Depots) {
    $nom = Split-Path $d.Chemin -Leaf
    if (-not (Test-Path (Join-Path $d.Chemin ".git"))) { Write-Log "ECHEC $nom : depot introuvable"; continue }
    Push-Location $d.Chemin
    try {
        # Blocage persistant : un commit suspect ne doit pas partir au passage suivant.
        # Pour debloquer apres verification : supprimer .git\sync-depots-bloque puis relancer.
        $marqueur = Join-Path $d.Chemin ".git\sync-depots-bloque"
        $pushBloque = Test-Path $marqueur
        if ($pushBloque) { Write-Log "ATTENTION $nom : push toujours bloque (supprimer .git\sync-depots-bloque apres verification)" }
        if (git status --porcelain) {
            git add -A 2>$null
            $fichiers = @(git diff --cached --name-only)
            # ce script contient lui-meme les motifs : exclu de l'analyse
            $ajouts = git diff --cached -U0 -- . ":(exclude)scripts/sync-depots.ps1" | Where-Object { $_ -match '^\+' -and $_ -notmatch '^\+\+\+ ' } | ForEach-Object { $_.Substring(1) }
            $suspects = foreach ($m in $MotifsSecret) { $ajouts | Where-Object { $_ -match $m } }
            if ($suspects -and $d.Push.Count -gt 0) {
                $pushBloque = $true
                New-Item -ItemType File -Path $marqueur -Force | Out-Null
                Write-Log "ATTENTION $nom : secret possible dans le diff, push bloque ($(@($suspects).Count) ligne(s)). Verifier avec 'git show', puis supprimer .git\sync-depots-bloque."
            }
            $message = "Sauvegarde auto $(Get-Date -Format 'yyyy-MM-dd') : $($fichiers.Count) fichier(s)`n`n" + (($fichiers | ForEach-Object { "- $_" }) -join "`n")
            git commit -q -m $message 2>$null
            if ($LASTEXITCODE -eq 0) { Write-Log "$nom : commit ($($fichiers.Count) fichier(s))" } else { Write-Log "ECHEC $nom : commit (code $LASTEXITCODE)" }
        }
        if ($pushBloque) { continue }
        foreach ($r in $d.Push) {
            # ne pousse que si le distant est en retard (evite une connexion inutile)
            $avance = git rev-list --count "$r/HEAD..HEAD" 2>$null
            if (-not $avance) { $avance = git rev-list --count "$r/master..HEAD" 2>$null }
            if ($avance -eq "0") {
                # rien a pousser : une lecture authentifiee suffit a renouveler le jeton OAuth (expire apres ~30 j sans usage)
                if ($r -eq "gitea") { git ls-remote -q $r HEAD *> $null; if ($LASTEXITCODE -ne 0) { Write-Log "ECHEC $nom : connexion $r (identifiants expires ? faire un git fetch a la main)" } }
                continue
            }
            $sortie = git push -q $r HEAD 2>&1
            if ($LASTEXITCODE -eq 0) { Write-Log "$nom : push $r ok" }
            else { Write-Log "ECHEC $nom : push $r ($(($sortie | Select-Object -Last 1)))" }
        }
    }
    finally { Pop-Location }
}
# Journal borne a 1000 lignes
$lignes = Get-Content $Log -ErrorAction SilentlyContinue
if ($lignes.Count -gt 1000) { $lignes | Select-Object -Last 1000 | Set-Content $Log -Encoding utf8 }
Write-Log "=== fin ==="
