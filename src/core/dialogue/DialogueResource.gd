## DialogueResource — Format de référence pour les fichiers .dialogue.json
##
## Ce fichier est de la DOCUMENTATION, pas du code exécutable.
## Il montre le format JSON attendu par le DialogueEngine.
##
## ─────────────────────────────────────────────────────────────────────────────
## STRUCTURE D'UN FICHIER .dialogue.json
## ─────────────────────────────────────────────────────────────────────────────
##
## {
##   "id": "a1_aldric_brennan",          // Identifiant unique de ce dialogue
##   "character": "aldric",              // Personnage POV
##   "act": 1,                           // Acte
##   "scene": "nuit_taverne",            // Scène dans la bible narrative
##   "nodes": {
##
##     "start": {
##       "type": "line",                 // "line" | "choice" | "auto"
##       "speaker": "Brennan",
##       "text": "Les lames qui n'ont pas eu de mauvaises nuits ne savent pas ce qu'elles coupent.",
##       "next": "aldric_repond"
##     },
##
##     "aldric_repond": {
##       "type": "choice",
##       "speaker": "",                  // Vide = pas de ligne avant les choix
##       "choices": [
##         {
##           "text": "J'ai eu des mauvaises nuits. Je sais ce que j'ai fait.",
##           "next": "brennan_ecoute",
##           "effects": []
##         },
##         {
##           "text": "On n'est pas là pour parler de ça.",
##           "next": "fin_seche",
##           "effects": []
##         }
##       ]
##     },
##
##     "brennan_ecoute": {
##       "type": "line",
##       "speaker": "Brennan",
##       "text": "— Il l'écoute sans commenter. Part sans répondre.",
##       "next": "fin_taverne"
##     },
##
##     "fin_taverne": {
##       "type": "auto",                 // Pas d'affichage, effets puis transition
##       "effects": [
##         { "type": "complete_scene", "character": "aldric", "act": 1, "scene_id": "brennan_nuit_taverne" }
##       ],
##       "next": "end"
##     },
##
##     "fin_seche": {
##       "type": "auto",
##       "effects": [
##         { "type": "complete_scene", "character": "aldric", "act": 1, "scene_id": "brennan_nuit_taverne" }
##       ],
##       "next": "end"
##     }
##   }
## }
##
##
## ─────────────────────────────────────────────────────────────────────────────
## FORMAT DES CONDITIONS
## ─────────────────────────────────────────────────────────────────────────────
##
## Condition simple sur un flag :
##   { "flag": 3, "value": true }        // NarrativeFlag enum value
##
## Condition sur le statut d'un compagnon :
##   { "companion_status": "brennan", "status": 2 }  // CompanionStatus.RECRUITED = 2
##
## Condition ET (tous doivent être vrais) :
##   { "all": [ { "flag": 3 }, { "flag": 7 } ] }
##
## Condition OU (au moins un vrai) :
##   { "any": [ { "flag": 3 }, { "flag": 7 } ] }
##
##
## ─────────────────────────────────────────────────────────────────────────────
## FORMAT DES EFFETS
## ─────────────────────────────────────────────────────────────────────────────
##
## Activer un flag narratif :
##   { "type": "set_flag", "flag": 0, "value": true }
##
## Marquer une scène complétée :
##   { "type": "complete_scene", "character": "aldric", "act": 1, "scene_id": "brennan_taverne" }
##
## Tuer un compagnon :
##   { "type": "kill_companion", "companion_id": "brennan", "scene_id": "combat_mine", "act": 3 }
##
## Recruter un compagnon (Aldric) :
##   { "type": "recruit_companion", "companion_id": "cain", "act": 1 }
##
## Seïra prépare un recrutement :
##   { "type": "seira_prepares_companion", "companion_id": "brennan" }
##
##
## ─────────────────────────────────────────────────────────────────────────────
## VALEURS ENUM — NarrativeFlag (ordre défini dans GameStateManager.gd)
## ─────────────────────────────────────────────────────────────────────────────
##
##  0 MIRA_PROTECTED
##  1 FALSE_DOCS_PLANTED
##  2 KIRA_DOSSIER_SENT
##  3 ALDRIC_OBSERVED
##  4 REFUGEE_NETWORK_FUNDED
##  5 BRENNAN_PAID_ONLY
##  6 BRENNAN_CONVINCED
##  7 CAIN_RECRUITED_SEIRA
##  8 RAEL_INTEGRATED
##  9 RAEL_REJECTED
## 10 ORWEN_CONVINCED
## 11 THESSA_SHOWN_EVIDENCE
## 12 THESSA_RECRUITED_SEIRA
## 13 PRISONER_POLICY_HUMANE
## 14 SEVENTH_REGIMENT_AMPLIFIED
## 15 ANONYMOUS_CHANNEL_ACTIVE
## 16 LYRIA_WARNED
## 17 KIRA_EXTRACTION_SUCCESS
## 18 KIRA_EXTRACTION_FAILED
## 19 KIRA_DOSSIER_ACTED_ON
## 20 LYRIA_CARNETS_RECEIVED
## 21 MINE_HISTORY_KNOWN_SEIRA
## 22 VEL_SHAN_SIGNED
## 23 VEL_SHAN_HAPPENED            ← LOCK NARRATIF, toujours true
## 24 ORVETH_UNCHECKED
## 25 ALDRIC_REFUSED_ORDER
## 26 ALDRIC_WATCHED_FROM_HILL
## 27 ALDRIC_DESERTED
## 28 SEIRA_TRUSTED_ALDRIC
## 29 DAVEN_COVER_BLOWN_VARETH
## 30 DAVEN_COVER_BLOWN_SEIRA
## 31 VAREK_KNOWS_SOTH
## 32 SEHN_FILTERING_DISCOVERED
## 33 ORVETH_ELIMINATED
## 34 LIRETH_REFUSED
## 35 RAEL_BECAME_DANGEROUS
## 36 MINE_DEEP_ROOMS_REACHED
## 37 SOTH_INSCRIPTIONS_READ
## 38 VAREK_ENDING_DESTROY
## 39 VAREK_ENDING_PROTECT
## 40 VAREK_ENDING_UNRESOLVED
##
## ─────────────────────────────────────────────────────────────────────────────
## CompanionStatus values
## ─────────────────────────────────────────────────────────────────────────────
##  0 UNKNOWN
##  1 AVAILABLE
##  2 RECRUITED
##  3 DEAD
##  4 INACCESSIBLE
