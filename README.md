# .dotfiles

Configs logicielles versionnées. Chaque fichier ici est l'original ; à son
emplacement d'origine se trouve un **lien symbolique** qui pointe vers ce
dépôt. Les logiciels n'ont rien à reconfigurer : de leur point de vue, le
fichier est toujours au même endroit.

Les secrets (clés, tokens, mots de passe) sont dans le dépôt séparé
[`.secrets`](../.secrets/README.md), jamais ici.

**⚠ Ce dépôt est public sur GitHub.** Avant tout commit, vérifier qu'aucun
fichier ajouté ne contient de mot de passe/token — certains logiciels
(digiKam notamment) mélangent config et identifiants dans le même fichier
« chiffré » de façon réversible : dans ce cas, faire vivre le fichier
entier dans `.secrets` plutôt que de tenter de n'exclure qu'une ligne.

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
└── apps/
    ├── digikam/
    │   └── digikam_systemrc           → %LOCALAPPDATA%\digikam_systemrc
    │       Layout des fenêtres. digikamrc reste dans .secrets/digikam/ :
    │       il contient le mot de passe (chiffré faiblement) de connexion
    │       à la base MariaDB. La bibliothèque photo (~/parties) et la
    │       base elle-même ne sont pas ici (données, pas config).
    │
    ├── showfoto/
    │   └── favorites.xml              → %APPDATA%\showfoto\favorites.xml
    │
    ├── calibre/
    │   └── *.json                     → %APPDATA%\calibre\*.json
    │       Préférences (plugins, GUI, export, visionneuse). Les bibliothèques
    │       elles-mêmes (~/lecture, ~/Calibre Library) ne sont pas ici.
    │
    ├── musicbee/
    │   └── MusicBee3Settings.ini      → %APPDATA%\MusicBee\MusicBee3Settings.ini
    │       Le token Spotify associé est dans .secrets/musicbee/.
    │
    ├── notepad++/
    │   └── config.xml, contextMenu.xml, shortcuts.xml, stylers.xml, userDefineLang.xml
    │       → %APPDATA%\Notepad++\*
    │       (langs.xml exclu : fichier par défaut de l'appli, pas personnalisé)
    │
    ├── obs-studio/
    │   └── global.ini, user.ini       → %APPDATA%\obs-studio\*
    │       ⚠ Le dossier basic/ (profils/scènes) n'est PAS versionné : peut
    │       contenir des clés de stream. À vérifier manuellement si besoin.
    │
    ├── mp3tag/
    │   └── mp3tag.cfg                 → %APPDATA%\Mp3tag\mp3tag.cfg
    │
    ├── filezilla/
    │   └── sitemanager.xml, filezilla.xml, bookmarks.xml, layout.xml
    │       → %APPDATA%\FileZilla\*
    │       sitemanager.xml référence la clé SSH (.secrets/ssh/id_ed25519.ppk)
    │       mais ne stocke aucun mot de passe en clair (auth par clé).
    │
    └── keepassxc/
        └── keepassxc.ini               → %APPDATA%\KeePassXC\keepassxc.ini
            Config de l'appli uniquement, PAS la base .kdbx elle-même.
```

## Non traité / à revoir manuellement

- **Thunderbird** : profils trop volumineux/complexes (cache, sessions) pour
  un symlink simple fichier par fichier. À faire à part si besoin un jour.
- **qBittorrent** : config quasi entièrement faite d'état d'interface
  binaire (géométries de fenêtres), aucune valeur à versionner.
- **`Database.kdbx`** (racine du home) : il existe DEUX fichiers différents,
  celui à la racine (`~/Database.kdbx`, 119 Ko, modifié 27/04/2026) et celui
  synchronisé dans `~/cloud.nikorion.fr/database keepass/database.kdbx`
  (237 Ko, modifié 03/07/2026, plus récent). Volontairement non touché ici —
  décider laquelle est la version de référence avant toute action.
- **D:\scripts\dump digikam\*.ps1** : scripts de dump MariaDB, laissés en
  place sur D: (des raccourcis .lnk dans ~/parties pointent dessus) —
  pourraient rejoindre `.dotfiles/apps/mariadb-digikam/` dans une passe future.
