# Calibre — feuille de style visionneuse contrôlable (thème VSCode pour les .md)

Objectif : dans la visionneuse Calibre, obtenir un rendu Markdown proche de la preview VSCode (clair/sombre auto), avec une feuille de style perso qui fait **autorité** sur un maximum de propriétés.

Contexte : `.md` ouvert dans la visionneuse = converti à la volée (entrée TXT/Markdown, Python-Markdown), avec options de conversion par défaut de Calibre. Rendu proche de markdown-it (VSCode), pas identique.

## Extensions Markdown (blocs ``` etc.)

Par défaut seulement `footnotes`, `tables`, `toc` → blocs ``` non reconnus (`powershell` affiché en texte, lignes collées). Réglage : Calibre (appli principale, pas la visionneuse) → Préférences → Conversion → Options d'entrée → TXT → extensions Markdown. Rouvrir/modifier le `.md` après changement (visionneuse garde en cache la version convertie).
- Activer : `extra` (= `fenced_code`, `tables`, `footnotes`, `attr_list`, `def_list`, `abbr`, `md_in_html`), `sane_lists` (listes comme VSCode), `toc`.
- Optionnel : `codehilite` (coloration syntaxe, couleurs propres → risque de jurer avec la feuille clair/sombre ; tester).
- Ne pas cocher :
  - `nl2br` : chaque retour ligne → `<br>` (VSCode/GitHub recollent les lignes) ;
  - `meta` : premières lignes `clé: valeur` avalées comme métadonnées, disparaissent ;
  - `wikilinks` : `[[texte]]` → lien mort (gênant pour notes TiddlyWiki) ;
  - `legacy_attrs`, `legacy_em` : anciens comportements, inutiles ;
  - `smarty` : guillemets/tirets typographiques → modifie le texte affiché.
- Docs à lire dans la visionneuse sans dépendre de ce réglage : blocs de code indentés de 4 espaces (reconnus partout) plutôt que ```.

## Où se règle la feuille

Préférences (⚙) → **Styles** → « Feuille de style personnalisée ». Elle est appliquée à **tout** livre ouvert, en direct.

Mécanisme (dépôt `kovidgoyal/calibre`, `src/pyj/read_book/settings.pyj`) : la feuille est injectée dans un `<style id="calibre-browser-viewer-user-stylesheet">` ajouté à `documentElement`, **après** les règles de couleur du thème (`apply_colors()` puis `apply_stylesheet()` dans `apply_settings()`). Ce n'est **pas** un reliquat d'ancien système : c'est le point d'injection courant. Étant injectée en dernier, elle gagne à spécificité égale — mais perd contre les mécanismes ci-dessous.

## Ce qui est contrôlable vs surchargé

| La feuille pilote | Surchargé par la visionneuse (piloté ailleurs) |
|---|---|
| Polices (`font-family`), graisses, `letter-spacing` | **Couleur de texte** (`color`) → thème de couleurs |
| `line-height`, espacements internes, `font-size` (agit) | **Couleur des liens** (`:link`, en `!important`) → thème de couleurs |
| Bordures, `background` des `code` / `pre` / tableaux | **Fond global** de page → thème de couleurs |
| Puces, `border-radius`, `overflow` | **Marges de page** (bords ↔ texte) → mode paginé / Mise en page |

### Pourquoi le texte résiste alors que le fond répond

`apply_colors()` pose la couleur de texte de deux façons :
1. Style **inline** sur `<html>` et `<body>` : `elem.style.color = foreground`.
2. Quand « Remplacer les couleurs du livre » est actif : une règle **`* { color: … !important; background-color: … !important }`** + `html > body :link, html > body :link * { color: … !important }`.

Le point clé est la règle `*` : elle pose la couleur **directement sur chaque élément** (`<p>`, `<li>`, `<span>`…). Une valeur posée directement l'emporte **toujours** sur une valeur **héritée**, quelle que soit la spécificité — donc même `body { color: … !important }` perd, car il ne colore que l'élément `body` (dont les enfants n'héritent jamais, la règle `*` les servant directement). Le fond, lui, est posé une seule fois (body / iframe) sans `*` concurrent qui te bloque → il répond. D'où l'asymétrie observée : `background` pris en compte, `color` non.

Séparément, les **marges de page** sont imposées par le mode paginé (`src/pyj/read_book/paged_mode.pyj` écrit `column-rule`/géométrie en `!important` dans `element.style` du body) → `max-width` / `margin: auto` / `padding` sur `body` sont ignorés. Régler les marges dans la GUI (Mise en page), pas en CSS.

## Principe : hors-feuille d'abord, CSS en dernier recours

Bonne pratique : **tout ce que le thème de couleurs Calibre sait exprimer, le régler dans le thème — pas dans la feuille.** La feuille ne garde que ce que le thème ne peut pas dire.

Pourquoi le thème gagne pour ces couleurs-là :
- il **atteint les marges** (fond global de page) — la CSS non ;
- il **bascule clair/sombre tout seul** (« Suivre le système » alterne deux jeux fond + texte + lien) → ni `@media` ni `!important` à gérer pour elles ;
- il évite la bagarre de la règle `*` (plus besoin de `!important` sur `color`).

Le thème sait exprimer **trois** couleurs, une par mode : **fond global, couleur de texte, couleur de lien**. Tout le reste (structure + couleurs par-élément) reste obligatoirement en CSS : le thème n'a qu'un fond/texte/lien uniques, il ne distingue pas un `h6`, un `blockquote`, un fond de `code`.

Réglages thème (Préférences → Apparence → Couleurs, mode **« Suivre le système »**) :

| | Clair | Sombre |
|---|---|---|
| Fond | `#ffffff` | `#1e1e1e` |
| Texte | `#1f2328` | `#b8b8b8` |
| Lien | `#0969da` | `#4daafc` |

⚠️ Garder **« Remplacer les couleurs du livre » désactivé** : sinon la règle `*` écrase les couleurs par-élément de la feuille (`h6`, `blockquote`, fonds de `code`/`pre`…).

Autres réglages GUI (hors couleurs) :
- **Taille de police** : `font-size` en CSS **agit bien** (elle n'est pas surchargée) — on peut la piloter dans la feuille. Par cohérence avec le principe « hors-feuille d'abord », on préfère régler la **taille de base** dans Préférences → Polices, et ne garder en CSS que les tailles **relatives** (`em`, ratios des titres). La feuille ci-dessous n'impose donc pas de `font-size` absolue sur `body` — décommenter au besoin.
- **Marges** : gauche/droite dans Préférences → Mise en page (jamais en CSS). Comme le fond du thème couvre désormais les marges, elles prennent la bonne couleur automatiquement.

### Ce qui reste non contrôlable

- **Marges/géométrie de page** en mode paginé : toujours GUI (Mise en page). Le mode **défilement** (scroll) rend la main au box-model — `body { padding }` marche alors — mais le paginé impose sa géométrie en `!important`.
- **Sélection** (`::selection`) : gérée par le thème.
- **Liens visités/actifs** : peuvent rester forcés selon le thème ; si besoin, les éditer dans le thème de couleurs.

## Feuille de style — thème VSCode clair/sombre auto (allégée)

Fond/texte/lien sont dans le thème (voir ci-dessus) ; la feuille ne pilote que la **structure** et les **couleurs par-élément**. Aucun `!important`. Titres serif (Sitka, Windows 11), corps sans-serif (Segoe UI Variable). Le `@media` sombre ne reprend que les couleurs par-élément (le thème gère fond/texte/lien).

```css
/* ---- Structure + couleurs par-élément (le thème gère fond/texte/lien) ---- */
body {
    font-family: "Segoe UI Variable Text", "Segoe UI", system-ui,
                 -apple-system, "Selawik", sans-serif;
    /* font-size: 17px;  taille de base réglée dans la GUI (Préférences → Polices) ; agit aussi en CSS si décommenté */
    line-height: 1.6;
    word-wrap: break-word;
}

h1, h2, h3, h4, h5, h6 {
    font-family: "Sitka Heading", "Sitka Display", Constantia,
                 "Palatino Linotype", Cambria, Georgia, serif;
    font-weight: 600;
    letter-spacing: -.01em;
    line-height: 1.25;
    margin: 1.4em 0 .6em;
}
h1 { font-size: 2em;    border-bottom: 1px solid #d8dee4; padding-bottom: .3em; }
h2 { font-size: 1.5em;  border-bottom: 1px solid #d8dee4; padding-bottom: .3em; }
h3 { font-size: 1.25em; }
h4 { font-size: 1em; }
h5 { font-size: .875em; }
h6 { font-size: .85em; color: #656d76; }

a { text-decoration: none; }
a:hover { text-decoration: underline; }

code {
    font-family: "Cascadia Code", "Cascadia Mono", Consolas, monospace;
    font-size: .9em;
    background: #f6f8fa;
    padding: .2em .4em;
    border-radius: 6px;
}
pre {
    background: #f6f8fa;
    padding: 1em;
    border-radius: 8px;
    border: 1px solid #d8dee4;
    overflow: auto;
}
pre code { background: transparent; padding: 0; }

blockquote {
    color: #656d76;
    border-left: 4px solid #d0d7de;
    padding: 0 1em;
    margin: 0 0 1em;
}

table { border-collapse: collapse; }
th, td { border: 1px solid #d8dee4; padding: .4em .8em; }
tr:nth-child(2n) { background: #f6f8fa; }

hr { height: 2px; border: 0; background: #d8dee4; }

/* ---- Sombre : uniquement les couleurs par-élément ---- */
@media (prefers-color-scheme: dark) {
    h1, h2, h3, h4, h5, h6 { color: #d0d0d0; }
    h1, h2 { border-bottom-color: #3c3c3c; }
    h6 { color: #9d9d9d; }
    code { background: rgba(255, 255, 255, .1); }
    pre { background: #0d1117; border-color: #30363d; }
    blockquote { color: #9d9d9d; border-left-color: #4c4c4c; }
    th, td { border-color: #3c3c3c; }
    tr:nth-child(2n) { background: #262626; }
    hr { background: #3c3c3c; }
}
```

Ajuster le gris de texte sombre au goût dans le **thème** (repères : `#c0c0c0` léger, `#b8b8b8` confortable, `#a8a8a8` doux ; ne pas descendre sous `#9d9d9d`, réservé aux `h6`/citations en CSS).

### Embarquer les polices (cohérence multi-appareils)

`@font-face` ne se charge **pas** fiablement depuis la feuille perso de la visionneuse. Pour figer les polices dans l'EPUB : Préférences → Conversion → Apparence → **CSS supplémentaire** (baked à la conversion), qui est aussi le bon endroit pour `@font-face`.
