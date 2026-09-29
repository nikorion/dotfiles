# Rédiger / organiser un CLAUDE.md
Objectif : réduire les tokens sans perdre d'info, en restant lisible par un humain ET par un modèle faible (ex. Sonnet effort low).

Ces règles valent aussi pour les CLAUDE.local.md (notes perso/machine, non versionnées) : mêmes règles de rédaction/compression, car eux aussi sont chargés à chaque conversation.

## Organisation
- Garder chaque CLAUDE.md léger : chargé à chaque conversation. N'y laisser que le tronc commun toujours utile.
- Sortir les procédures spécifiques vers un dossier `guides/` à côté du CLAUDE.md ; n'y laisser qu'un renvoi d'une ligne par guide (chemin + rôle), pour s'y référer si utile.
- **Factorisation hiérarchique** (workspace/parent ↔ sous-projets). Quand plusieurs sous-projets partagent un même CLAUDE.md parent : ce qui est commun à ≥2 sous-projets **monte** dans le CLAUDE.md parent ; chaque CLAUDE.md enfant ne garde que son **spécifique** et s'ouvre sur un renvoi d'en-tête vers le parent (« Avant toute tâche sur ce sous-projet, consulter d'abord `../CLAUDE.md` »). Règle de routage : commun → parent, spécifique → enfant, procédure détaillée → `guides/`. **Zéro duplication entre niveaux** — la même info ne vit qu'à un seul endroit. Ne pas confondre avec le tronc « toujours utile » qui, lui, reste inline (voir plus bas : ce qui s'applique à chaque tâche ne se redirige pas).
- Décider inline vs redirigé : **inline** ce qui doit s'appliquer sans réflexion à (presque) chaque tâche (conventions d'écriture, table de routage, pièges à échec silencieux) ; **redirigé** ce qui n'est consulté qu'occasionnellement (procédures, référence détaillée, rationale). Un guide est plus verbeux que son résumé inline : rediriger une info nécessaire à chaque tâche fait *dépenser plus* de tokens (aller-retour + guide), pas moins.

## Redirections impératives
Tout renvoi (vers un `guides/` ou vers le CLAUDE.md parent) s'écrit comme un **déclencheur conditionnel**, jamais une note passive — c'est ce qui le fait suivre même par un modèle faible / en effort bas (qui, sinon, agit sans lire).
- Forme : « **Avant de [tâche/condition déclenchante] → lire `guides/X`** ». Nommer d'abord *quand* le guide s'applique, puis l'action (*lire* / *consulter d'abord*).
- Proscrire la forme passive « détails : `guides/X` », « voir `guides/X` », « … est documenté dans `X` » : elle n'indique pas *quand* agir et se fait sauter.
- Ajouter « ne pas agir de mémoire » là où le risque est d'appliquer une convention approximative sans lire.
- Le **résumé actionnable** (« le quoi ») peut rester inline à côté du renvoi ; le renvoi pointe vers le **détail** (« le pourquoi/comment »).
- Une section « Guides » qui liste les renvois : en-tête impératif (« Lire le guide AVANT d'entreprendre la tâche qu'il couvre ») + chaque entrée en déclencheur, pas en `chemin — description` neutre.

## Structure du contenu
- Tableaux : réservés aux CLAUDE.md (chargés à chaque tour). Un guide de méthode se comprime comme un CLAUDE.md *sauf* ce point — il reste en prose/puces. Exception : un tableau est toléré dans un guide s'il sert de **référence de correspondance dense** (lookup à colonnes factorisant un contexte partagé, ex. dénominations d'un écosystème) — jamais pour des étapes de procédure, qui restent en puces. Préférer un tableau à un arbre ASCII (plus dense, plus facile à parser) : il gagne en volume total (les en-têtes portent le contexte une seule fois), même si ses symboles (`|`, `/`, backticks…) tokenisent un peu moins bien caractère par caractère.
- Préférer des puces courtes à la prose.
- Supprimer les redondances : dire chaque info une fois, renvoyer au tableau plutôt que relister.
- Éviter les caractères non-ASCII susceptibles d'être hors vocabulaire courant des modèles Claude (symboles mathématiques Unicode comme `−` U+2212, flèches exotiques, emojis) : souvent plusieurs tokens. Ne concerne pas les accents français ordinaires (é, è, à, ç…), bien couverts.

## Compression « mots-outils »
Gain modeste (~8–11 %) si le fichier est déjà surtout tableau/chemins/code. Style télégraphique, sans ambiguïté tant qu'on garde les mots relationnels. Stratégie : agressif sur les mots-outils, intangible sur les mots relationnels.
- Retirer librement : articles (le/la/les/un/des/du), verbes de liaison faibles (« sert de » → « = »), qualificatifs implicites (« futur », « séparé »), redondances (« versionnées (committées) » → « versionnées »).
- NE JAMAIS retirer : négations (pas, non, ne…pas), prépositions relationnelles/directionnelles (sous, vers, →, sinon, via, pour), mots porteurs de sens (« même identité »). Les retirer crée de l'ambiguïté pour un modèle faible.
- Ne pas toucher : tableaux, chemins, backticks, exemples de code.

## Passer en anglais (option)
Gain modeste (~5–10 % après compression). Perte de lisibilité humaine si ce n'est pas la langue maternelle : choix frugalité tokens vs confort de lecture.

## Vérification
- Relire : aucune négation ni préposition relationnelle perdue.
- Chaque fait de la version d'origine, s'il y en a une, reste présent.
- Compter et retourner les tokens approximatifs du CLAUDE.md modifié et de ses sous-fichiers (`guides/`) — ou comparer avec le CLAUDE.md d'avant s'il existe : `[math]::Round((Get-Content fichier -Raw).Length / 3.7)` (règle de pouce ~3,7 caractères/token ; approximatif).
