# .dotfiles

Configs des **outils de dev** versionnées. Chaque fichier ici est l'original ;
à son emplacement d'origine se trouve un **lien symbolique** qui pointe vers
ce dépôt. Les logiciels n'ont rien à reconfigurer : de leur point de vue, le
fichier est toujours au même endroit.

Les configs des logiciels non liés au dev (calibre, digiKam, MusicBee,
OBS, Mp3tag, KeePassXC…) vivent dans le dépôt séparé
[`.app-configs`](../.app-configs/README.md) (privé) — hors du périmètre
habituel d'un repo "dotfiles" et sans intérêt à exposer publiquement.
Notepad++ et FileZilla restent ici : ce sont des outils de dev (édition de
code, transfert de fichiers vers des serveurs).

Les secrets (clés, tokens, mots de passe) sont dans le dépôt séparé
[`.secrets`](../.secrets/README.md), jamais ici.

**⚠ Ce dépôt est public sur GitHub et Gitea.** Avant tout commit, vérifier qu'aucun
fichier ajouté ne contient de mot de passe/token — certains logiciels
mélangent config et identifiants dans le même fichier « chiffré » de façon
réversible : dans ce cas, faire vivre le fichier entier dans `.secrets`
plutôt que de tenter de n'exclure qu'une ligne.

## Installation sur une nouvelle machine

Point d'entrée unique (clone `.dotfiles`/`.app-configs` depuis GitHub s'ils
manquent, puis lance les 3 `restore.ps1` à la suite) :

```powershell
.\bootstrap.ps1
```

`.secrets` n'a pas de remote (jamais publié, push refusé par un hook `pre-push`) : il doit être copié
manuellement à côté des deux autres (clé USB, Nextcloud…) avant de lancer
`bootstrap.ps1` pour que son étape soit prise en compte — sinon elle est
juste signalée et sautée.

Pour restaurer un seul dépôt : `.\restore.ps1` depuis son dossier.

Active le Mode développeur Windows au préalable si besoin (Paramètres →
Confidentialité et sécurité → Pour les développeurs), sinon la création de
liens symboliques échoue sans droits admin.

## Sauvegarde automatique des dépôts

[`scripts/sync-depots.ps1`](scripts/sync-depots.ps1), lancé chaque jour à
21:00 par la tâche planifiée Windows `sync-depots` (rattrapée à l'ouverture
de session si le PC était éteint) :

- `.dotfiles` (public), `.app-configs` (privé) : commit auto + push vers `origin` (GitHub) et `gitea`.
- `raspberry`, `.secrets` : commit local seulement, jamais de push — aucune remote, et un hook `.git/hooks/pre-push` refuse tout push (hooks non versionnés : à recréer sur une nouvelle machine).

Garde-fou : si le diff ressemble à un secret (clé privée, mot de passe/token
renseigné, mot de passe de site FileZilla, clé privée KeeShare), le commit est fait mais le
push est bloqué, et le reste tant que `.git\sync-depots-bloque` existe
dans le dépôt (le supprimer après vérification). Journal : `%LOCALAPPDATA%\sync-depots.log` — `ECHEC` ou
`ATTENTION` = à traiter.

Recréer la tâche sur une nouvelle machine :

```powershell
$a = New-ScheduledTaskAction -Execute "conhost.exe" -Argument "--headless pwsh.exe -NoProfile -File `"$HOME\.dotfiles\scripts\sync-depots.ps1`""
$t = New-ScheduledTaskTrigger -Daily -At 21:00
Register-ScheduledTask -TaskName "sync-depots" -Action $a -Trigger $t -Settings (New-ScheduledTaskSettingsSet -StartWhenAvailable)
```

Le push vers `gitea` exige des identifiants mémorisés : faire un premier
`git push gitea` à la main dans chaque dépôt (fenêtre du Git Credential Manager).

## Hiérarchie

```
.dotfiles/
├── git/
│   └── .gitconfig                     → C:\Users\Nico\.gitconfig
│       Config git globale (email, éditeur).
│
├── ssh/
│   └── config                         → C:\Users\Nico\.ssh\config
│       Config client SSH (hosts, options). Les clés vivent dans .secrets/ssh/.
│
├── powershell/
│   └── Microsoft.PowerShell_profile.ps1 → Documents\PowerShell\Microsoft.PowerShell_profile.ps1
│       Prompt custom (drive/dossier/flèches colorées), alias pn=pnpm.
│
├── windows-terminal/
│   └── settings.json                  → %LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json
│       Profils, thèmes, raccourcis clavier.
│
├── vscode/
│   └── settings.json                  → %APPDATA%\Code\User\settings.json
│       Préférences utilisateur VSCode.
│
├── scoop/
│   └── config.json                    → C:\Users\Nico\.config\scoop\config.json
│       Config du gestionnaire de paquets scoop.
│       Pour la liste des apps installées : régénérer avec `scoop export > scoopfile.json`
│       (pas versionné automatiquement, change souvent).
│
├── claude/
│   ├── CLAUDE.md                      → C:\Users\Nico\.claude\CLAUDE.md
│   │   Instructions globales Claude Code (partagées, versionnées).
│   │   NB : CLAUDE.local.md reste volontairement HORS dotfiles (perso/machine).
│   ├── guides/                        → C:\Users\Nico\.claude\guides
│   │   Guides annexes (rédaction CLAUDE.md, feuille de style Calibre).
│   ├── agents/                        → C:\Users\Nico\.claude\agents
│   │   Définitions d'agents personnalisés.
│   └── settings.json                  → C:\Users\Nico\.claude\settings.json
│       Réglages Claude Code (thème, modèle, plugins actifs).
│       Vérifié : ne contient pas de clé API en clair. Re-vérifier avant
│       chaque commit si ce fichier évolue (.credentials.json reste à part,
│       dans .secrets/claude/).
│
├── notepad++/
│   └── config.xml, contextMenu.xml, shortcuts.xml, stylers.xml, userDefineLang.xml
│       → %APPDATA%\Notepad++\*
│       (langs.xml exclu : fichier par défaut de l'appli, pas personnalisé)
│
└── filezilla/
    └── sitemanager.xml, filezilla.xml, bookmarks.xml, layout.xml
        → %APPDATA%\FileZilla\*
        sitemanager.xml référence la clé SSH (.secrets/ssh/id_ed25519.ppk)
        mais ne stocke aucun mot de passe en clair (auth par clé).
```

## Non traité / à revoir manuellement

- **`Database.kdbx`** : volontairement laissé en dehors de tout dépôt. La
  base active reste dans `~/cloud.nikorion.fr/database keepass/database.kdbx`,
  gérée uniquement par la synchro Nextcloud.
