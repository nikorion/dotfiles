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

**⚠ Ce dépôt est public sur GitHub.** Avant tout commit, vérifier qu'aucun
fichier ajouté ne contient de mot de passe/token — certains logiciels
mélangent config et identifiants dans le même fichier « chiffré » de façon
réversible : dans ce cas, faire vivre le fichier entier dans `.secrets`
plutôt que de tenter de n'exclure qu'une ligne.

## Installation sur une nouvelle machine

```powershell
.\restore.ps1
```

Active le Mode développeur Windows au préalable si besoin (Paramètres →
Confidentialité et sécurité → Pour les développeurs), sinon la création de
liens symboliques échoue sans droits admin.

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
