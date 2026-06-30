## CompanionDefinitions — Données statiques des 9 compagnons.
## Utilisé par CompanionRegistry quand les fichiers .tres ne sont pas encore créés.
## En production, préférer les ressources .tres pour l'édition dans Godot.
##
## Structure : [id, display_name, archetype, hp, atq, def, speed,
##              hp_per_act, atq_per_act, def_per_act, recruit_act, description]


class_name CompanionDefinitions


## Retourne un Array de CompanionData créés depuis les définitions hardcodées.
static func create_all() -> Array[CompanionData]:
	var all: Array[CompanionData] = []
	for row in _RAW:
		all.append(_make(row))
	return all


## Retourne un CompanionData pour un id donné, ou null.
static func create(companion_id: String) -> CompanionData:
	for row in _RAW:
		if row[0] == companion_id:
			return _make(row)
	return null


# ─────────────────────────────────────────────────────────────────────────────
# DONNÉES
# ─────────────────────────────────────────────────────────────────────────────
#
# Colonnes :
# 0  id
# 1  display_name
# 2  archetype          (0=PROTECTOR 1=ATTACKER 2=SUPPORT)
# 3  base_hp
# 4  base_atq
# 5  base_def
# 6  base_speed
# 7  hp_per_act
# 8  atq_per_act
# 9  def_per_act
# 10 recruit_act
# 11 description
#
# Philosophie des stats :
#   - Protecteurs : hp et def élevés, speed correcte
#   - Attaquants  : atq et speed élevés, def faible
#   - Support     : stats équilibrées + utilité narrative

const _RAW: Array = [
	# ── Brennan — Protecteur, A1 ──────────────────────────────────────────────
	# Mercenaire. Pas de convictions, juste du professionnalisme.
	# Recruté via Seïra (argent seul → BRENNAN_PAID_ONLY ; conviction → BRENNAN_CONVINCED)
	[
		"brennan",
		"Brennan",
		0,        # PROTECTOR
		95, 28, 22, 8,
		20, 4, 5, # croissance solide
		1,
		"Mercenaire sans illusions. Se bat comme une porte blindée. Coûte cher."
	],

	# ── Lyria — Support, A2 ───────────────────────────────────────────────────
	# Herboriste / archiviste de village. Ses carnets changent le combat contre les soldats Échorite.
	# Conditions : LYRIA_WARNED (Daven) + REFUGEE_NETWORK_FUNDED (Seïra)
	[
		"lyria",
		"Lyria",
		2,        # SUPPORT
		72, 18, 14, 12,
		15, 3, 3,
		2,
		"Herboriste réfugiée. Ses notes sur l'Échorite sont une carte des failles ennemies."
	],

	# ── Caïn — Attaquant, A2 ─────────────────────────────────────────────────
	# Déserteur d'un régiment de cavalerie impériale.
	# Recruté si Seïra l'a convaincu avec autre chose que de l'argent.
	[
		"cain",
		"Caïn",
		1,        # ATTACKER
		76, 38, 10, 15,
		14, 7, 2,
		2,
		"Déserteur impérial. Rapide et brutal. Attend qu'on lui montre pour quoi se battre."
	],

	# ── Mira — Support, A1 ───────────────────────────────────────────────────
	# Archiviste. Lit les inscriptions Soth au CP4.
	# Conditions : MIRA_PROTECTED (Daven) + REFUGEE_NETWORK_FUNDED (Seïra)
	[
		"mira",
		"Mira",
		2,        # SUPPORT
		68, 16, 12, 11,
		12, 3, 3,
		1,
		"Archiviste réfugiée. Calme même quand le monde brûle. Lit les langues mortes."
	],

	# ── Rael — Attaquant, A2 ─────────────────────────────────────────────────
	# Ex-chef de milice. Amenés ses 200 hommes. Dangereux si mal encadré.
	# Condition : RAEL_INTEGRATED (Seïra le recrute, sinon inaccessible)
	[
		"rael",
		"Rael",
		1,        # ATTACKER
		82, 42, 8, 13,
		16, 8, 2,
		2,
		"Commandant de milice. Efficace à court terme. Demande un cadre ou crée le sien."
	],

	# ── Thessa — Support, A2 ─────────────────────────────────────────────────
	# Espionne reconvertie. Accès aux réseaux d'information.
	# Condition : THESSA_SHOWN_EVIDENCE (Seïra lui montre les preuves)
	[
		"thessa",
		"Thessa",
		2,        # SUPPORT
		70, 22, 16, 14,
		13, 4, 4,
		2,
		"Informatrice aux deux tables. Travaille pour les bonnes raisons depuis peu."
	],

	# ── Orwen — Protecteur, A2 ───────────────────────────────────────────────
	# Vétéran endurci. Seïra met 3 semaines à le convaincre.
	# Sa mort en A3 est la plus narrative du jeu.
	[
		"orwen",
		"Orwen",
		0,        # PROTECTOR
		110, 30, 26, 7,
		22, 5, 6,
		2,
		"Vétéran qui pensait ne plus jamais servir. A mis 3 semaines à dire oui. Ne recule pas."
	],

	# ── Kira — Attaquant, A2 ─────────────────────────────────────────────────
	# Archiviste militaire retournée. La plus difficile à recruter (triple condition).
	# Conditions : KIRA_EXTRACTION_SUCCESS (Daven) + KIRA_DOSSIER_ACTED_ON (Seïra)
	#              + Aldric la croise sur le terrain
	[
		"kira",
		"Kira",
		1,        # ATTACKER
		78, 40, 12, 16,
		15, 8, 2,
		2,
		"Archiviste militaire. Sait où les squelettes sont rangés. A failli mourir deux fois pour ça."
	],

	# ── Brand — Protecteur, A3 ────────────────────────────────────────────────
	# Prisonnier de guerre. Aldric l'épargne en combat si PRISONER_POLICY_HUMANE.
	# Double condition : PRISONER_POLICY_HUMANE (Seïra) + Aldric l'épargne en combat
	[
		"brand",
		"Brand",
		0,        # PROTECTOR
		100, 32, 24, 9,
		18, 5, 5,
		3,
		"Ennemi épargné en combat. Dit peu. Remplit exactement ce qu'il promet."
	],
]


static func _make(row: Array) -> CompanionData:
	var d := CompanionData.new()
	d.companion_id  = row[0]
	d.display_name  = row[1]
	d.archetype     = row[2] as GameStateManager.CompanionArchetype
	d.base_hp       = row[3]
	d.base_atq      = row[4]
	d.base_def      = row[5]
	d.base_speed    = row[6]
	d.hp_per_act    = row[7]
	d.atq_per_act   = row[8]
	d.def_per_act   = row[9]
	d.recruit_act   = row[10]
	d.description   = row[11]
	return d
