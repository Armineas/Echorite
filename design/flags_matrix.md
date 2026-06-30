# Matrice d'influence cross-story
# Document de référence — source de vérité pour le GameStateManager
# Toute décision narrative doit figurer ici avant d'être codée.

## Format de chaque ligne
```
ACTION DÉCLENCHANTE | PERSONNAGE SOURCE | FLAG GÉNÉRÉ | EFFET SUR | DANS QUEL ACTE | DESCRIPTION DE L'EFFET
```

---

## ACTE 1

| Action déclenchante | Source | Flag généré | Cible | Acte effet | Description |
|---|---|---|---|---|---|
| Daven protège Mira avant les agents de Vareth | Daven | MIRA_PROTECTED | Seïra | A1 | Mira apparaît dans le réseau réfugiés de Seïra. Sans ce flag : Mira est introuvable. |
| Daven protège Mira | Daven | MIRA_PROTECTED | Daven | A2/A3 | Mira peut plus tard fournir à Daven des informations sur les archives de la mine. |
| Daven envoie le dossier de Kira anonymement | Daven | KIRA_DOSSIER_SENT | Seïra | A2 | Seïra reçoit le dossier de Kira. Sans ce flag : le dossier n'arrive jamais. |
| Seïra investit dans le réseau réfugiés | Seïra | REFUGEE_NETWORK_FUNDED | Seïra | A1/A2 | Donne accès aux fiches Lyria et Mira dans l'interface de recrutement. |
| Seïra investit dans le réseau réfugiés | Seïra | REFUGEE_NETWORK_FUNDED | Aldric | A2 | Lyria peut rejoindre l'équipe d'Aldric. Sans ce flag : Lyria inaccessible. |
| Seïra recrute Brennan avec argent seulement | Seïra | BRENNAN_PAID_ONLY | Aldric | A3 | Brennan disponible en A2 mais peut quitter si les ressources baissent en A3. |
| Seïra recrute Brennan avec argent + conviction | Seïra | BRENNAN_CONVINCED | Aldric | A2/A3 | Brennan stable jusqu'à sa mort éventuelle. Scène de la veille A3 débloquée. |
| Seïra intègre Rael | Seïra | RAEL_INTEGRATED | Aldric | A2 | Rael rejoint l'équipe d'Aldric. Arc de dégradation morale enclenché. |
| Seïra rejette Rael | Seïra | RAEL_REJECTED | Aldric | — | Rael inaccessible pour ce run. Ses 200 hommes rejoignent quand même. |
| Seïra complète 3 semaines avec Orwen | Seïra | ORWEN_CONVINCED | Aldric | A2 | Orwen rejoint l'équipe d'Aldric. Sa mort en A3 est la plus lourde. |
| Seïra établit politique humaine prisonniers | Seïra | PRISONER_POLICY_HUMANE | Aldric | A3 | Brand peut rejoindre si Aldric l'épargne en combat (condition 1/2). |
| Varek signe le protocole Échorite 7ème régiment | Varek | SEVENTH_REGIMENT_AMPLIFIED | Aldric | A2/A3 | Les soldats du 7ème régiment sont mécaniquement plus difficiles à combattre. Lyria peut les analyser si vivante. |
| Varek signe le protocole Échorite 7ème régiment | Varek | SEVENTH_REGIMENT_AMPLIFIED | Varek | A3 | Orveth devient incontrôlable plus tôt. Varek doit l'éliminer. |

---

## CP1 — La Délégation Brisée

**Événement fixe** (FALSE_DOCS_PLANTED = toujours vrai).

| POV | Ce que le personnage voit | Flag généré | Effet |
|---|---|---|---|
| Aldric | Escorte la délégation. Honte diffuse qu'il ne comprend pas encore. | — | Seed narratif pour la désertion. |
| Seïra | Sait que les docs sont faux. Ne peut pas le prouver. Décide de ne plus jamais réagir. | — | Déclenche son arc "anticiper plutôt que réagir". |
| Varek | "La comédie est terminée." Dort bien. | — | Établit sa psychologie. |
| Daven | Regarde depuis la fenêtre de service. N'est pas soulagé. | ALDRIC_OBSERVED (confirmé) | Premier crack de sa psychologie. |

---

## ACTE 2

| Action déclenchante | Source | Flag généré | Cible | Acte effet | Description |
|---|---|---|---|---|---|
| Daven établit le canal anonyme vers Seïra | Daven | ANONYMOUS_CHANNEL_ACTIVE | Seïra | A2 | Seïra reçoit le dossier Kira et peut agir dessus. |
| Daven avertit Lyria du village ciblé | Daven | LYRIA_WARNED | Seïra/Aldric | A2 | Lyria survit et peut être recrutée. Sans ce flag + REFUGEE_NETWORK_FUNDED : Lyria meurt avant recrutement. |
| Daven réussit l'extraction de Kira | Daven | KIRA_EXTRACTION_SUCCESS | Seïra | A2 | Seïra peut finaliser le recrutement de Kira (si KIRA_DOSSIER_ACTED_ON). |
| Daven rate l'extraction de Kira | Daven | KIRA_EXTRACTION_FAILED | Global | A2 | Kira → INACCESSIBLE immédiatement dans tous les runs. |
| Seïra agit sur le dossier Kira | Seïra | KIRA_DOSSIER_ACTED_ON | Aldric | A2/A3 | Condition 2/3 pour recruter Kira (Aldric doit encore la croiser sur le terrain). |
| Seïra reçoit les carnets de Lyria | Seïra | LYRIA_CARNETS_RECEIVED | Aldric | A3 | Aldric comprend les soldats Échorite avant le CP4. Mécanique combat améliorée. |
| Seïra apprend l'histoire de la mine | Seïra | MINE_HISTORY_KNOWN_SEIRA | Seïra/Aldric | A3/CP4 | Seïra reconnaît les inscriptions Soth au CP4. Révélation narrative complète vs. incomplète. |
| Varek signe l'ordre Vel'Shan | Varek | VEL_SHAN_SIGNED | Global | A2 | Indique que Varek a signé consciemment (vs. Orveth agissant seul). Dialogue CP2 change. |
| Vel'Shan se produit (TOUJOURS) | Lock | VEL_SHAN_HAPPENED | Global | CP2 | Déclenche CP2 pour les 4 personnages. Irréversible. |
| Aldric refuse d'exécuter l'ordre | Aldric | ALDRIC_REFUSED_ORDER | Global | CP3 | Déclenche CP3 — La Désertion. Sans ce flag : arc Aldric bloqué, pas de désertion possible. |

---

## CP2 — Le Massacre de Vel'Shan

**Événement fixe** (VEL_SHAN_HAPPENED = toujours vrai, quelle que soit la décision de Varek).
Si VEL_SHAN_SIGNED = false → Orveth a agi seul → dialogue Varek A3 change (il apprend après).

| POV | Ce que le personnage voit | Flag généré |
|---|---|---|
| Aldric | Refuse. Son second exécute. Il regarde depuis la colline. | ALDRIC_REFUSED_ORDER + ALDRIC_WATCHED_FROM_HILL |
| Seïra | Rapport 3 jours après. Pleure 20 min. Convoque ses conseillers. | — |
| Varek | Rapport 7-43-B. 30 secondes. Rapport suivant. | VEL_SHAN_SIGNED (si signé) |
| Daven | Dans la rue principale. Avait l'info la veille. "C'est moi." | — |

---

## CP3 — La Désertion d'Aldric

**Condition** : ALDRIC_REFUSED_ORDER doit être vrai.

| POV | Ce que le personnage voit | Flag généré |
|---|---|---|
| Aldric | Traverse les lignes, mains levées. Demande Seïra. | ALDRIC_DESERTED |
| Seïra | Piège évident ? Elle y va elle-même. 3 preuves convergentes. | SEIRA_TRUSTED_ALDRIC |
| Varek | Apprend 6h après. "Doublez la surveillance des officiers de première classe." | — |
| Daven | Éclaireur qui intercepte Aldric en premier. "Bien. Parle-lui vrai." Ne se présente pas. | — |

---

## ACTE 3

| Action déclenchante | Source | Flag généré | Cible | Description |
|---|---|---|---|---|
| Varek découvre que Sehn filtrait les rapports | Varek | SEHN_FILTERING_DISCOVERED | Varek | Varek lit les rapports originaux de Veyra. Rage contre Sehn, pas contre lui-même. |
| Varek élimine Orveth | Varek | ORVETH_ELIMINATED | Global | Si non éliminé : Orveth tue des civils supplémentaires → tension A3 de Seïra augmente. |
| Lireth refuse l'ordre | Varek | LIRETH_REFUSED | Varek | Première fois que quelqu'un dit non à Varek. Il doit s'en charger lui-même. |
| Veyra montre les dessins des salles Soth | Varek | VAREK_KNOWS_SOTH | Global | Varek part seul vers la mine → déclenche CP4 pour tous. |
| Couverture de Daven découverte par Vareth | Daven | DAVEN_COVER_BLOWN_VARETH | Daven | Vareth le traque. Claustrophobie narrative maximale. |
| Couverture de Daven découverte par Seïra | Daven | DAVEN_COVER_BLOWN_SEIRA | Daven/Seïra | Scène de confrontation Seïra-Daven débloquée. |
| Rael ne reçoit pas de cadrage en A2 | Seïra | RAEL_BECAME_DANGEROUS | Aldric/Seïra | Rael commence à agir de manière autonome. Peut refuser des ordres d'Aldric en A3. |
| Brand épargné par Aldric en combat + PRISONER_POLICY_HUMANE | Aldric | — | Aldric | Brand peut rejoindre l'équipe (condition finale). |

---

## CP4 — La Mine d'Échorite

**Condition de déclenchement** : VAREK_KNOWS_SOTH = true + les 4 ont terminé leurs scènes d'Acte 3.

| Condition | Effet sur CP4 |
|---|---|
| MINE_HISTORY_KNOWN_SEIRA = true | Seïra reconnaît les structures Soth → révélation complète |
| Mira est vivante et recrutée | SOTH_INSCRIPTIONS_READ possible → certaines inscriptions déchiffrées |
| Lyria est vivante et recrutée | Lyria reconnaît des symptômes décrits dans les inscriptions |
| Kira est vivante et recrutée | Kira a vu des croquis des salles dans les archives brûlées → dialogue supplémentaire |
| ORVETH_ELIMINATED = false | Orveth interfère dans la séquence finale |
| Varek : les 3 fins possibles | DESTROY / PROTECT / UNRESOLVED selon les décisions finales du joueur |

### Fins de Varek (CP4)
- **VAREK_ENDING_DESTROY** : Varek détruit les salles profondes pour que personne ne puisse répéter l'histoire des Soth. Cohérent avec son caractère de contrôle.
- **VAREK_ENDING_PROTECT** : Varek comprend que la connaissance des Soth doit être préservée comme avertissement. Surprend tout le monde.
- **VAREK_ENDING_UNRESOLVED** : Varek est encore dans les salles quand les autres arrivent. Ce qu'il fera reste ouvert. Le joueur ne saura jamais.

---

## CONDITIONS DE RECRUTEMENT — TABLEAU RÉCAPITULATIF

| Compagnon | Condition Daven | Condition Seïra | Condition Aldric | Disponibilité |
|---|---|---|---|---|
| Brennan | — | Recruter (payé ou convaincu) | Rencontrer en A1 | Standard |
| Lyria | LYRIA_WARNED | REFUGEE_NETWORK_FUNDED | Rencontrer en A2 | Standard (double condition) |
| Caïn | — | Convaincre (pas juste argent) | Rencontrer en A2 | Standard |
| Mira | MIRA_PROTECTED | REFUGEE_NETWORK_FUNDED | Rencontrer | Conditionnel (double) |
| Rael | — | RAEL_INTEGRATED | — | Standard (toujours disponible si intégré) |
| Thessa | — | THESSA_SHOWN_EVIDENCE + recruter | — | Standard |
| Orwen | — | 3 semaines de persuasion | — | Conditionnel (investissement temps) |
| Kira | KIRA_EXTRACTION_SUCCESS | KIRA_DOSSIER_ACTED_ON | Croiser sur le terrain | Rare (triple condition) |
| Brand | — | PRISONER_POLICY_HUMANE | Épargner en combat | Conditionnel (double) |
