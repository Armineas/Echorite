extends Node
## SceneSequencer — Autoload singleton (nom : "SceneSequencer")
## Source de vérité de l'ordre chronologique des scènes.
## Le joueur ne choisit plus le personnage — le jeu avance dans la timeline.
##
## Principe :
##   - Chaque scène a un seq_id unique et une position dans la timeline.
##   - advance() charge la prochaine scène non encore jouée.
##   - Les Points de Croisement jouent leurs 4 POVs dans l'ordre défini ici.
##   - Un acte se déverrouille quand toutes ses scènes sont complétées.


signal scene_ready(entry: Dictionary)    # Prochain seq_id, character, dialogue_path…
signal act_transition(from_act: int, to_act: int)


# ─────────────────────────────────────────────────────────────────────────────
# FORMAT D'UNE ENTRÉE DE SÉQUENCE
# ─────────────────────────────────────────────────────────────────────────────
#
# {
#   "seq_id":       String  — identifiant unique (= scene_id dans GSM)
#   "character":    String  — "aldric" | "seira" | "varek" | "daven" | "shared"
#   "act":          int     — 1, 2 ou 3
#   "dialogue_path":String  — chemin relatif depuis res://design/dialogues/
#   "scene_id":     String  — clé dans "scenes" si multi-scènes, "" sinon
#   "entry_node":   String  — nœud de départ (défaut "start")
#   "condition":    Dictionary — condition optionnelle (même format que DialogueEngine)
#                               si non remplie, la scène est sautée (skip silencieux)
# }

# ─────────────────────────────────────────────────────────────────────────────
# SÉQUENCE COMPLÈTE
# ─────────────────────────────────────────────────────────────────────────────

## Acte 1 — ordre chronologique complet. 22 entrées.
## J-14 à J0 (CP1). Les commentaires indiquent le repère temporel approximatif.
##
## Règle de simultanéité : quand plusieurs scènes se passent au même moment,
## on joue d'abord celle à l'impact le plus faible (préparation du plus fort).
## Varek CP1 est toujours dernier : sa sérénité glaciale est la révélation finale.
const ACT1_SEQUENCE: Array[Dictionary] = [

	# J-14 ── Varek lit les rapports de nuit (routine, premier établissement)
	{
		"seq_id":        "varek_a1_s1_rapport",
		"character":     "varek",
		"act":           1,
		"dialogue_path": "acte1/varek_a1.dialogue.json",
		"scene_id":      "varek_a1_s1_rapport",
		"entry_node":    "start",
		"condition":     {}
	},

	# J-13 ── Varek + Orveth : le protocole d'amplification (décision centrale)
	{
		"seq_id":        "varek_a1_s2_protocole",
		"character":     "varek",
		"act":           1,
		"dialogue_path": "acte1/varek_a1.dialogue.json",
		"scene_id":      "varek_a1_s2_protocole",
		"entry_node":    "start",
		"condition":     {}
	},

	# J-12 ── Seïra, premier contact Orwen au consulat (3 semaines avant CP1)
	{
		"seq_id":        "seira_a1_s6_orwen",
		"character":     "seira",
		"act":           1,
		"dialogue_path": "acte1/seira_a1.dialogue.json",
		"scene_id":      "seira_a1_s6_orwen",
		"entry_node":    "start",
		"condition":     {}
	},

	# J-11 (aube) ── Aldric au poste frontière (premier établissement)
	{
		"seq_id":        "aldric_a1_s1_frontiere",
		"character":     "aldric",
		"act":           1,
		"dialogue_path": "acte1/aldric_a1.dialogue.json",
		"scene_id":      "aldric_a1_s1_frontiere",
		"entry_node":    "start",
		"condition":     {}
	},

	# J-10 (1h du matin) ── Seïra dans les rues, note la lumière administrative
	{
		"seq_id":        "seira_a1_s1_nuit",
		"character":     "seira",
		"act":           1,
		"dialogue_path": "acte1/seira_a1.dialogue.json",
		"scene_id":      "seira_a1_s1_nuit",
		"entry_node":    "start",
		"condition":     {}
	},

	# J-10 (journée) ── Daven au bureau d'enregistrement, 82 dossiers
	{
		"seq_id":        "daven_a1_s1_couverture",
		"character":     "daven",
		"act":           1,
		"dialogue_path": "acte1/daven_a1.dialogue.json",
		"scene_id":      "daven_a1_s1_couverture",
		"entry_node":    "start",
		"condition":     {}
	},

	# J-10 (minuit) ── Daven protège Mira dans le couloir
	{
		"seq_id":        "daven_a1_s2_mira",
		"character":     "daven",
		"act":           1,
		"dialogue_path": "acte1/daven_a1.dialogue.json",
		"scene_id":      "daven_a1_s2_mira",
		"entry_node":    "start",
		"condition":     {}
	},

	# J-8 ── Seïra, camp de réfugiés : décision d'investissement réseau
	{
		"seq_id":        "seira_a1_s2_refugies",
		"character":     "seira",
		"act":           1,
		"dialogue_path": "acte1/seira_a1.dialogue.json",
		"scene_id":      "seira_a1_s2_refugies",
		"entry_node":    "start",
		"condition":     {}
	},

	# J-8 (midi) ── Seïra approche Brennan dans la taverne
	{
		"seq_id":        "seira_a1_s3_brennan",
		"character":     "seira",
		"act":           1,
		"dialogue_path": "acte1/seira_a1.dialogue.json",
		"scene_id":      "seira_a1_s3_brennan",
		"entry_node":    "start",
		"condition":     {}
	},

	# J-7 ── Aldric, quartier de transit : rencontre Nira
	{
		"seq_id":        "aldric_a1_s2_nira",
		"character":     "aldric",
		"act":           1,
		"dialogue_path": "acte1/aldric_a1.dialogue.json",
		"scene_id":      "aldric_a1_s2_nira",
		"entry_node":    "start",
		"condition":     {}
	},

	# J-6 ── Seïra rencontre Caïn dans les archives
	{
		"seq_id":        "seira_a1_s4_cain",
		"character":     "seira",
		"act":           1,
		"dialogue_path": "acte1/seira_a1.dialogue.json",
		"scene_id":      "seira_a1_s4_cain",
		"entry_node":    "start",
		"condition":     {}
	},

	# J-5 ── Seïra évalue Rael, l'imprimeur aux formulaires vierges
	{
		"seq_id":        "seira_a1_s5_rael",
		"character":     "seira",
		"act":           1,
		"dialogue_path": "acte1/seira_a1.dialogue.json",
		"scene_id":      "seira_a1_s5_rael",
		"entry_node":    "start",
		"condition":     {}
	},

	# J-3 (2h du matin) ── Daven prépare les faux documents de la délégation
	{
		"seq_id":        "daven_a1_s3_faux_documents",
		"character":     "daven",
		"act":           1,
		"dialogue_path": "acte1/daven_a1.dialogue.json",
		"scene_id":      "daven_a1_s3_faux_documents",
		"entry_node":    "start",
		"condition":     {}
	},

	# J-3 (3h du matin) ── Daven trouve le dossier Kira (même nuit)
	{
		"seq_id":        "daven_a1_s4_kira",
		"character":     "daven",
		"act":           1,
		"dialogue_path": "acte1/daven_a1.dialogue.json",
		"scene_id":      "daven_a1_s4_kira",
		"entry_node":    "start",
		"condition":     {}
	},

	# J-1 ── Aldric, réception officielle : "la délégation arrive demain"
	{
		"seq_id":        "aldric_a1_s3_reception",
		"character":     "aldric",
		"act":           1,
		"dialogue_path": "acte1/aldric_a1.dialogue.json",
		"scene_id":      "aldric_a1_s3_reception",
		"entry_node":    "start",
		"condition":     {}
	},

	# J-1 (soir) ── Aldric et Brennan à l'auberge (même soir que la réception)
	{
		"seq_id":        "aldric_a1_s4_brennan",
		"character":     "aldric",
		"act":           1,
		"dialogue_path": "acte1/aldric_a1.dialogue.json",
		"scene_id":      "aldric_a1_s4_brennan",
		"entry_node":    "start",
		"condition":     {}
	},

	# J-1 (nuit) ── Varek prépare et signe les documents de la délégation
	{
		"seq_id":        "varek_a1_s3_delegation_prep",
		"character":     "varek",
		"act":           1,
		"dialogue_path": "acte1/varek_a1.dialogue.json",
		"scene_id":      "varek_a1_s3_delegation_prep",
		"entry_node":    "start",
		"condition":     {}
	},

	# J-1 (tard la nuit) ── Varek seul avec le cristal
	{
		"seq_id":        "varek_a1_s4_usage_prive",
		"character":     "varek",
		"act":           1,
		"dialogue_path": "acte1/varek_a1.dialogue.json",
		"scene_id":      "varek_a1_s4_usage_prive",
		"entry_node":    "start",
		"condition":     {}
	},

	# ── CP1 — La Délégation ─────────────────────────────────────────────────
	# J0 — 4 POVs dans l'ordre d'impact croissant.
	# Aldric escorte sans comprendre → Daven reconnaît ses propres documents →
	# Seïra lit la délégation et note Orwen → Varek reçoit la confirmation.
	# Varek en dernier : sa tranquillité est la révélation finale.
	#
	# Note : seq_id = "cp1_done" pour chaque POV, character différent.
	# GSM.is_scene_done(character, act, "cp1_done") les distingue individuellement.

	{
		"seq_id":        "cp1_done",
		"character":     "aldric",
		"act":           1,
		"dialogue_path": "acte1/aldric_a1.dialogue.json",
		"scene_id":      "aldric_a1_cp1",
		"entry_node":    "start",
		"condition":     {}
	},
	{
		"seq_id":        "cp1_done",
		"character":     "daven",
		"act":           1,
		"dialogue_path": "acte1/daven_a1.dialogue.json",
		"scene_id":      "daven_a1_cp1",
		"entry_node":    "start",
		"condition":     {}
	},
	{
		"seq_id":        "cp1_done",
		"character":     "seira",
		"act":           1,
		"dialogue_path": "acte1/seira_a1.dialogue.json",
		"scene_id":      "seira_a1_cp1",
		"entry_node":    "start",
		"condition":     {}
	},
	{
		"seq_id":        "cp1_done",
		"character":     "varek",
		"act":           1,
		"dialogue_path": "acte1/varek_a1.dialogue.json",
		"scene_id":      "varek_a1_cp1",
		"entry_node":    "start",
		"condition":     {}
	},
]


## Acte 2 — ordre chronologique. 19 entrées régulières + 4 POVs CP2.
## De l'après-CP1 jusqu'à la nuit de Vel'Shan et ses lendemains.
##
## Chronologie approximative :
##   Semaine 1 : Daven canal, Seïra bastion, Varek rapports, Aldric Vel'Ardane
##   Semaine 2 : Lyria carnets, mine visite, Vel'Shan ordre → nuit avant
##   Semaine 3 : après Vel'Shan, Kira extraction, décision confiance
##   CP2        : Vel'Shan — 4 POVs dans l'ordre de proximité à l'événement
const ACT2_SEQUENCE: Array[Dictionary] = [

	# Semaine 1 — établissements post-CP1
	{
		"seq_id":        "daven_a2_s1_canal_anonyme",
		"character":     "daven",
		"act":           2,
		"dialogue_path": "acte2/daven_a2.dialogue.json",
		"scene_id":      "daven_a2_s1_canal_anonyme",
		"entry_node":    "start",
		"condition":     {}
	},
	{
		"seq_id":        "seira_a2_s1_bastion_est",
		"character":     "seira",
		"act":           2,
		"dialogue_path": "acte2/seira_a2.dialogue.json",
		"scene_id":      "seira_a2_s1_bastion_est",
		"entry_node":    "start",
		"condition":     {}
	},
	{
		"seq_id":        "varek_a2_s1_activite_rebelle",
		"character":     "varek",
		"act":           2,
		"dialogue_path": "acte2/varek_a2.dialogue.json",
		"scene_id":      "varek_a2_s1_activite_rebelle",
		"entry_node":    "start",
		"condition":     {}
	},
	{
		"seq_id":        "aldric_a2_s1_siege_velardane",
		"character":     "aldric",
		"act":           2,
		"dialogue_path": "acte2/aldric_a2.dialogue.json",
		"scene_id":      "aldric_a2_s1_siege_velardane",
		"entry_node":    "start",
		"condition":     {}
	},

	# Semaine 2 — montée des preuves et de la pression
	{
		"seq_id":        "seira_a2_s2_lyria_carnets",
		"character":     "seira",
		"act":           2,
		"dialogue_path": "acte2/seira_a2.dialogue.json",
		"scene_id":      "seira_a2_s2_lyria_carnets",
		"entry_node":    "start",
		"condition":     {}
	},
	{
		"seq_id":        "aldric_a2_s2_mine_premiere_visite",
		"character":     "aldric",
		"act":           2,
		"dialogue_path": "acte2/aldric_a2.dialogue.json",
		"scene_id":      "aldric_a2_s2_mine_premiere_visite",
		"entry_node":    "start",
		"condition":     {}
	},
	{
		"seq_id":        "varek_a2_s2_velshan_ordre",
		"character":     "varek",
		"act":           2,
		"dialogue_path": "acte2/varek_a2.dialogue.json",
		"scene_id":      "varek_a2_s2_velshan_ordre",
		"entry_node":    "start",
		"condition":     {}
	},
	{
		"seq_id":        "daven_a2_s2_nuit_avant_velshan",
		"character":     "daven",
		"act":           2,
		"dialogue_path": "acte2/daven_a2.dialogue.json",
		"scene_id":      "daven_a2_s2_nuit_avant_velshan",
		"entry_node":    "start",
		"condition":     {}
	},
	{
		"seq_id":        "seira_a2_s3_mira_histoire_mine",
		"character":     "seira",
		"act":           2,
		"dialogue_path": "acte2/seira_a2.dialogue.json",
		"scene_id":      "seira_a2_s3_mira_histoire_mine",
		"entry_node":    "start",
		"condition":     {}
	},
	{
		"seq_id":        "varek_a2_s3_protocole_pression",
		"character":     "varek",
		"act":           2,
		"dialogue_path": "acte2/varek_a2.dialogue.json",
		"scene_id":      "varek_a2_s3_protocole_pression",
		"entry_node":    "start",
		"condition":     {}
	},
	{
		"seq_id":        "aldric_a2_s3_cain_rencontre",
		"character":     "aldric",
		"act":           2,
		"dialogue_path": "acte2/aldric_a2.dialogue.json",
		"scene_id":      "aldric_a2_s3_cain_rencontre",
		"entry_node":    "start",
		"condition":     {}
	},

	# Semaine 3 — convergence vers Vel'Shan
	# Dossier Kira conditionnel (flag 2 = KIRA_DOSSIER_SENT, posé dans daven_a1_s4_kira)
	{
		"seq_id":        "seira_a2_s4_dossier_kira",
		"character":     "seira",
		"act":           2,
		"dialogue_path": "acte2/seira_a2.dialogue.json",
		"scene_id":      "seira_a2_s4_dossier_kira",
		"entry_node":    "start",
		"condition":     {"flag": 2, "value": true}
	},
	{
		"seq_id":        "daven_a2_s3_lyria_avertissement",
		"character":     "daven",
		"act":           2,
		"dialogue_path": "acte2/daven_a2.dialogue.json",
		"scene_id":      "daven_a2_s3_lyria_avertissement",
		"entry_node":    "start",
		"condition":     {}
	},
	{
		"seq_id":        "seira_a2_s5_brand_prisonniers",
		"character":     "seira",
		"act":           2,
		"dialogue_path": "acte2/seira_a2.dialogue.json",
		"scene_id":      "seira_a2_s5_brand_prisonniers",
		"entry_node":    "start",
		"condition":     {}
	},
	{
		"seq_id":        "aldric_a2_s4_l_ordre",
		"character":     "aldric",
		"act":           2,
		"dialogue_path": "acte2/aldric_a2.dialogue.json",
		"scene_id":      "aldric_a2_s4_l_ordre",
		"entry_node":    "start",
		"condition":     {}
	},
	{
		"seq_id":        "varek_a2_s4_sehn_premier_doute",
		"character":     "varek",
		"act":           2,
		"dialogue_path": "acte2/varek_a2.dialogue.json",
		"scene_id":      "varek_a2_s4_sehn_premier_doute",
		"entry_node":    "start",
		"condition":     {}
	},
	{
		"seq_id":        "daven_a2_s4_kira_extraction",
		"character":     "daven",
		"act":           2,
		"dialogue_path": "acte2/daven_a2.dialogue.json",
		"scene_id":      "daven_a2_s4_kira_extraction",
		"entry_node":    "start",
		"condition":     {}
	},
	{
		"seq_id":        "seira_a2_s6_decision_confiance",
		"character":     "seira",
		"act":           2,
		"dialogue_path": "acte2/seira_a2.dialogue.json",
		"scene_id":      "seira_a2_s6_decision_confiance",
		"entry_node":    "start",
		"condition":     {}
	},

	# ── CP2 — Vel'Shan ──────────────────────────────────────────────────────
	# 4 POVs dans l'ordre de proximité à l'événement :
	# Aldric sur la colline (direct) → Daven dans la rue (indirect mais présent) →
	# Varek (résultat immédiat) → Seïra (rapport trois jours après, résolution finale).
	# seq_id = "cp2_done" différencié par character, comme CP1.
	{
		"seq_id":        "cp2_done",
		"character":     "aldric",
		"act":           2,
		"dialogue_path": "acte2/aldric_a2.dialogue.json",
		"scene_id":      "aldric_a2_cp2",
		"entry_node":    "start",
		"condition":     {}
	},
	{
		"seq_id":        "cp2_done",
		"character":     "daven",
		"act":           2,
		"dialogue_path": "acte2/daven_a2.dialogue.json",
		"scene_id":      "daven_a2_cp2",
		"entry_node":    "start",
		"condition":     {}
	},
	{
		"seq_id":        "cp2_done",
		"character":     "varek",
		"act":           2,
		"dialogue_path": "acte2/varek_a2.dialogue.json",
		"scene_id":      "varek_a2_cp2",
		"entry_node":    "start",
		"condition":     {}
	},
	{
		"seq_id":        "cp2_done",
		"character":     "seira",
		"act":           2,
		"dialogue_path": "acte2/seira_a2.dialogue.json",
		"scene_id":      "seira_a2_cp2",
		"entry_node":    "start",
		"condition":     {}
	},
]

## Acte 3 — ordre chronologique. 18 entrées régulières + CP3 (conditionnel) + 4 POVs CP4.
## De l'après-Vel'Shan jusqu'à la mine finale.
##
## Chronologie approximative :
##   Phase 1 : reconstructions et découvertes (couverture tombée, archives, déserteurs)
##   Phase 2 : convergences (Daven/Aldric, Seïra/Daven, Varek/Veyra)
##   Phase 3 : veille, préparation
##   CP3     : la désertion d'Aldric (conditionnel flag 25 = ALDRIC_REFUSED_ORDER)
##   CP4     : la mine — 4 POVs, fin de l'histoire
const ACT3_SEQUENCE: Array[Dictionary] = [

	# Phase 1 — après Vel'Shan, reconstructions
	{
		"seq_id":        "seira_a3_s1_coalition_vacille",
		"character":     "seira",
		"act":           3,
		"dialogue_path": "acte3/seira_a3.dialogue.json",
		"scene_id":      "seira_a3_s1_coalition_vacille",
		"entry_node":    "start",
		"condition":     {}
	},
	{
		"seq_id":        "daven_a3_s1_couverture_decouverture",
		"character":     "daven",
		"act":           3,
		"dialogue_path": "acte3/daven_a3.dialogue.json",
		"scene_id":      "daven_a3_s1_couverture_decouverture",
		"entry_node":    "start",
		"condition":     {}
	},
	{
		"seq_id":        "aldric_a3_s1_apprendre_commander",
		"character":     "aldric",
		"act":           3,
		"dialogue_path": "acte3/aldric_a3.dialogue.json",
		"scene_id":      "aldric_a3_s1_apprendre_commander",
		"entry_node":    "start",
		"condition":     {"flag": 25, "value": true}
	},
	{
		"seq_id":        "varek_a3_s1_sehn_cache",
		"character":     "varek",
		"act":           3,
		"dialogue_path": "acte3/varek_a3.dialogue.json",
		"scene_id":      "varek_a3_s1_sehn_cache",
		"entry_node":    "start",
		"condition":     {}
	},
	{
		"seq_id":        "seira_a3_s2_allies_partent",
		"character":     "seira",
		"act":           3,
		"dialogue_path": "acte3/seira_a3.dialogue.json",
		"scene_id":      "seira_a3_s2_allies_partent",
		"entry_node":    "start",
		"condition":     {}
	},
	{
		"seq_id":        "aldric_a3_s2_rael_miroir",
		"character":     "aldric",
		"act":           3,
		"dialogue_path": "acte3/aldric_a3.dialogue.json",
		"scene_id":      "aldric_a3_s2_rael_miroir",
		"entry_node":    "start",
		"condition":     {"flag": 25, "value": true}
	},

	# Phase 2 — convergences
	{
		"seq_id":        "varek_a3_s2_7eme_ordre_elimination",
		"character":     "varek",
		"act":           3,
		"dialogue_path": "acte3/varek_a3.dialogue.json",
		"scene_id":      "varek_a3_s2_7eme_ordre_elimination",
		"entry_node":    "start",
		"condition":     {}
	},
	{
		"seq_id":        "daven_a3_s2_aldric_trouve",
		"character":     "daven",
		"act":           3,
		"dialogue_path": "acte3/daven_a3.dialogue.json",
		"scene_id":      "daven_a3_s2_aldric_trouve",
		"entry_node":    "start",
		"condition":     {"flag": 25, "value": true}
	},
	{
		"seq_id":        "varek_a3_s3_veyra_dessins",
		"character":     "varek",
		"act":           3,
		"dialogue_path": "acte3/varek_a3.dialogue.json",
		"scene_id":      "varek_a3_s3_veyra_dessins",
		"entry_node":    "start",
		"condition":     {}
	},
	{
		"seq_id":        "aldric_a3_s3_soldats_7eme",
		"character":     "aldric",
		"act":           3,
		"dialogue_path": "acte3/aldric_a3.dialogue.json",
		"scene_id":      "aldric_a3_s3_soldats_7eme",
		"entry_node":    "start",
		"condition":     {"flag": 25, "value": true}
	},
	{
		"seq_id":        "seira_a3_s3_confrontation_daven",
		"character":     "seira",
		"act":           3,
		"dialogue_path": "acte3/seira_a3.dialogue.json",
		"scene_id":      "seira_a3_s3_confrontation_daven",
		"entry_node":    "start",
		"condition":     {}
	},
	{
		"seq_id":        "daven_a3_s3_secret_mine",
		"character":     "daven",
		"act":           3,
		"dialogue_path": "acte3/daven_a3.dialogue.json",
		"scene_id":      "daven_a3_s3_secret_mine",
		"entry_node":    "start",
		"condition":     {}
	},
	{
		"seq_id":        "aldric_a3_s4_ancien_second",
		"character":     "aldric",
		"act":           3,
		"dialogue_path": "acte3/aldric_a3.dialogue.json",
		"scene_id":      "aldric_a3_s4_ancien_second",
		"entry_node":    "start",
		"condition":     {"flag": 25, "value": true}
	},
	{
		"seq_id":        "varek_a3_s4_lireth_porte",
		"character":     "varek",
		"act":           3,
		"dialogue_path": "acte3/varek_a3.dialogue.json",
		"scene_id":      "varek_a3_s4_lireth_porte",
		"entry_node":    "start",
		"condition":     {}
	},
	{
		"seq_id":        "daven_a3_s4_traque",
		"character":     "daven",
		"act":           3,
		"dialogue_path": "acte3/daven_a3.dialogue.json",
		"scene_id":      "daven_a3_s4_traque",
		"entry_node":    "start",
		"condition":     {}
	},
	{
		"seq_id":        "daven_a3_s5_seira_question",
		"character":     "daven",
		"act":           3,
		"dialogue_path": "acte3/daven_a3.dialogue.json",
		"scene_id":      "daven_a3_s5_seira_question",
		"entry_node":    "start",
		"condition":     {}
	},

	# Phase 3 — veille et préparation
	{
		"seq_id":        "seira_a3_s4_victoire_signifie",
		"character":     "seira",
		"act":           3,
		"dialogue_path": "acte3/seira_a3.dialogue.json",
		"scene_id":      "seira_a3_s4_victoire_signifie",
		"entry_node":    "start",
		"condition":     {}
	},
	{
		"seq_id":        "varek_a3_s5_chemin_mine",
		"character":     "varek",
		"act":           3,
		"dialogue_path": "acte3/varek_a3.dialogue.json",
		"scene_id":      "varek_a3_s5_chemin_mine",
		"entry_node":    "start",
		"condition":     {}
	},
	# Veille avec Brennan — conditionnel flag 0 (MIRA_PROTECTED, proxy "Brennan vivant")
	{
		"seq_id":        "aldric_a3_s5_veille",
		"character":     "aldric",
		"act":           3,
		"dialogue_path": "acte3/aldric_a3.dialogue.json",
		"scene_id":      "aldric_a3_s5_veille",
		"entry_node":    "start",
		"condition":     {"all": [{"flag": 25, "value": true}, {"flag": 0, "value": true}]}
	},

	# ── CP3 — La Désertion ──────────────────────────────────────────────────
	# Conditionnel : flag 25 (ALDRIC_REFUSED_ORDER). Si Aldric a signé, CP3 n'existe pas.
	# 3 POVs : Daven (intercepte), Aldric (traverse), Seïra (reçoit).
	# Varek n'a pas de POV CP3 — il apprend la désertion d'Aldric 6h plus tard, hors scène.
	{
		"seq_id":        "cp3_done",
		"character":     "daven",
		"act":           3,
		"dialogue_path": "acte3/daven_a3.dialogue.json",
		"scene_id":      "daven_a3_cp3",
		"entry_node":    "start",
		"condition":     {"flag": 25, "value": true}
	},
	{
		"seq_id":        "cp3_done",
		"character":     "aldric",
		"act":           3,
		"dialogue_path": "acte3/aldric_a3.dialogue.json",
		"scene_id":      "aldric_a3_cp3",
		"entry_node":    "start",
		"condition":     {"flag": 25, "value": true}
	},
	{
		"seq_id":        "cp3_done",
		"character":     "seira",
		"act":           3,
		"dialogue_path": "acte3/seira_a3.dialogue.json",
		"scene_id":      "seira_a3_cp3",
		"entry_node":    "start",
		"condition":     {"flag": 25, "value": true}
	},

	# ── CP4 — La Mine ───────────────────────────────────────────────────────
	# 4 POVs dans l'ordre d'arrivée dans la mine :
	# Daven (seul le matin, reconnait les carnets) → Aldric (galerie principale, assaut) →
	# Seïra (passage secret, inscriptions) → Varek (chambre centrale, attendait).
	# Tous sans condition — la mine est l'inévitable, quelle que soit la route prise.
	{
		"seq_id":        "cp4_done",
		"character":     "daven",
		"act":           3,
		"dialogue_path": "acte3/daven_a3.dialogue.json",
		"scene_id":      "daven_a3_cp4_mine",
		"entry_node":    "start",
		"condition":     {}
	},
	{
		"seq_id":        "cp4_done",
		"character":     "aldric",
		"act":           3,
		"dialogue_path": "acte3/aldric_a3.dialogue.json",
		"scene_id":      "aldric_a3_cp4_mine",
		"entry_node":    "start",
		"condition":     {}
	},
	{
		"seq_id":        "cp4_done",
		"character":     "seira",
		"act":           3,
		"dialogue_path": "acte3/seira_a3.dialogue.json",
		"scene_id":      "seira_a3_cp4_mine",
		"entry_node":    "start",
		"condition":     {}
	},
	{
		"seq_id":        "cp4_done",
		"character":     "varek",
		"act":           3,
		"dialogue_path": "acte3/varek_a3.dialogue.json",
		"scene_id":      "varek_a3_cp4_mine",
		"entry_node":    "start",
		"condition":     {}
	},
]

const ALL_SEQUENCES: Array = [ACT1_SEQUENCE, ACT2_SEQUENCE, ACT3_SEQUENCE]


# ─────────────────────────────────────────────────────────────────────────────
# API PUBLIQUE
# ─────────────────────────────────────────────────────────────────────────────

## Retourne la prochaine entrée de séquence non encore complétée, ou {}.
func get_next() -> Dictionary:
	var seq := _current_sequence()
	for entry in seq:
		if not _is_done(entry) and _condition_met(entry):
			return entry
	return {}


## Avance et déclenche scene_ready avec l'entrée suivante.
## Appelé par SceneRouter après la fin d'une scène.
func advance() -> void:
	var entry := get_next()
	if entry.is_empty():
		_check_act_transition()
		return
	scene_ready.emit(entry)


## Retourne true si toutes les scènes de l'acte courant sont complétées.
func is_act_complete(act: int) -> bool:
	var seq := _sequence_for_act(act)
	for entry in seq:
		if not _is_done(entry):
			return false
	return true


## Retourne l'acte courant (le premier acte non encore complet).
func current_act() -> int:
	for act in [1, 2, 3]:
		if not is_act_complete(act):
			return act
	return 3  # Jeu terminé


# ─────────────────────────────────────────────────────────────────────────────
# LOGIQUE INTERNE
# ─────────────────────────────────────────────────────────────────────────────

func _current_sequence() -> Array:
	return _sequence_for_act(current_act())


func _sequence_for_act(act: int) -> Array:
	match act:
		1: return ACT1_SEQUENCE
		2: return ACT2_SEQUENCE
		3: return ACT3_SEQUENCE
	return []


## Une scène est "done" si GSM.is_scene_done() retourne true pour son seq_id.
## Le seq_id est utilisé directement comme scene_id dans GSM.complete_scene().
func _is_done(entry: Dictionary) -> bool:
	return GSM.is_scene_done(
		entry.get("character", ""),
		entry.get("act", 1),
		entry.get("seq_id", "")
	)


## Évalue la condition d'une entrée (même format que DialogueEngine).
func _condition_met(entry: Dictionary) -> bool:
	var cond: Dictionary = entry.get("condition", {})
	if cond.is_empty():
		return true
	if cond.has("flag"):
		return GSM.get_flag(cond["flag"]) == cond.get("value", true)
	if cond.has("all"):
		for sub in cond["all"]:
			if not _condition_met({"condition": sub}):
				return false
		return true
	if cond.has("any"):
		for sub in cond["any"]:
			if _condition_met({"condition": sub}):
				return true
		return false
	return true


func _check_act_transition() -> void:
	var act := current_act()
	if is_act_complete(act) and act < 3:
		act_transition.emit(act, act + 1)
