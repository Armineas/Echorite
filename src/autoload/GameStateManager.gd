extends Node
## GameStateManager — Autoload singleton (P0, tâche #2)
## Stocke l'intégralité de l'état narratif cross-story.
## Ajouter dans Project > Project Settings > Autoload avec le nom "GSM".


# ─────────────────────────────────────────────────────────────────────────────
# ENUMS
# ─────────────────────────────────────────────────────────────────────────────

## Tous les flags narratifs du jeu.
## Une décision = un flag. Nommer en MAJUSCULES_AVEC_UNDERSCORES.
enum NarrativeFlag {
	# ── Acte 1 · Daven ───────────────────────────────────────────────────────
	MIRA_PROTECTED,              # Daven a protégé Mira avant les agents de Vareth
	FALSE_DOCS_PLANTED,          # Daven a planté les faux documents (toujours vrai → lock CP1)
	KIRA_DOSSIER_SENT,           # Daven a envoyé anonymement les coordonnées de Kira à Seïra
	ALDRIC_OBSERVED,             # Daven a observé Aldric à la réception diplomatique

	# ── Acte 1 · Seïra ───────────────────────────────────────────────────────
	REFUGEE_NETWORK_FUNDED,      # Seïra a investi dans le réseau réfugiés (ouvre Lyria + Mira)
	BRENNAN_PAID_ONLY,           # Seïra a recruté Brennan avec argent seulement (instable)
	BRENNAN_CONVINCED,           # Seïra a recruté Brennan avec argent + conviction (stable)
	CAIN_RECRUITED_SEIRA,        # Seïra a convaincu Caïn de rejoindre
	RAEL_INTEGRATED,             # Seïra a intégré Rael avec ses 200 hommes
	RAEL_REJECTED,               # Seïra a renvoyé Rael
	ORWEN_CONVINCED,             # Seïra a terminé les 3 semaines de persuasion d'Orwen
	THESSA_SHOWN_EVIDENCE,       # Seïra a montré à Thessa comment Vareth a utilisé son travail
	THESSA_RECRUITED_SEIRA,      # Thessa a accepté de rejoindre
	PRISONER_POLICY_HUMANE,      # Seïra a établi une politique humaine pour les prisonniers

	# ── Acte 1 · Varek ───────────────────────────────────────────────────────
	SEVENTH_REGIMENT_AMPLIFIED,  # Varek a signé le protocole d'amplification Échorite du 7ème

	# ── Acte 2 · Daven ───────────────────────────────────────────────────────
	ANONYMOUS_CHANNEL_ACTIVE,    # Canal de transmission anonyme vers Seïra établi
	LYRIA_WARNED,                # Daven a prévenu Lyria du village ciblé
	KIRA_EXTRACTION_SUCCESS,     # Daven a réussi l'extraction de Kira
	KIRA_EXTRACTION_FAILED,      # Daven a échoué → Kira disparaît

	# ── Acte 2 · Seïra ───────────────────────────────────────────────────────
	KIRA_DOSSIER_ACTED_ON,       # Seïra a agi sur le dossier anonyme de Kira
	LYRIA_CARNETS_RECEIVED,      # Seïra a reçu les carnets médicaux de Lyria sur l'Échorite
	MINE_HISTORY_KNOWN_SEIRA,    # Seïra sait que la mine a été interdite par un ancien roi

	# ── Acte 2 · Varek ───────────────────────────────────────────────────────
	VEL_SHAN_SIGNED,             # Varek a signé l'ordre Vel'Shan (décision du joueur)
	VEL_SHAN_HAPPENED,           # Le massacre de Vel'Shan a eu lieu (TOUJOURS VRAI — lock narratif)
	ORVETH_UNCHECKED,            # Varek n'a pas recadré Orveth à temps

	# ── Acte 2 · Aldric ──────────────────────────────────────────────────────
	ALDRIC_REFUSED_ORDER,        # Aldric a refusé d'exécuter l'ordre à Vel'Shan
	ALDRIC_WATCHED_FROM_HILL,    # Aldric a regardé depuis la colline sans agir

	# ── Acte 3 · Global ──────────────────────────────────────────────────────
	ALDRIC_DESERTED,             # Aldric a traversé les lignes (CP3)
	SEIRA_TRUSTED_ALDRIC,        # Seïra a accepté Aldric après vérification convergente
	DAVEN_COVER_BLOWN_VARETH,    # Couverture de Daven découverte par Vareth
	DAVEN_COVER_BLOWN_SEIRA,     # Couverture de Daven découverte par Seïra
	VAREK_KNOWS_SOTH,            # Varek a appris l'existence des salles Soth (via Veyra)
	SEHN_FILTERING_DISCOVERED,   # Varek a découvert que Sehn filtrait les rapports
	ORVETH_ELIMINATED,           # Varek a éliminé Orveth
	LIRETH_REFUSED,              # Lireth a refusé l'ordre d'éliminer le 7ème régiment
	RAEL_BECAME_DANGEROUS,       # Rael est devenu incontrôlable (si intégré sans cadrage)

	# ── CP4 · La Mine ────────────────────────────────────────────────────────
	MINE_DEEP_ROOMS_REACHED,     # Les salles Soth intactes ont été atteintes
	SOTH_INSCRIPTIONS_READ,      # Les inscriptions ont été partiellement déchiffrées (besoin Mira)
	VAREK_ENDING_DESTROY,        # Varek a choisi de détruire les salles profondes
	VAREK_ENDING_PROTECT,        # Varek a choisi de protéger les salles profondes
	VAREK_ENDING_UNRESOLVED,     # Varek est resté sans réponse (fin ambiguë)
}


## Statut d'un compagnon dans ce run.
enum CompanionStatus {
	UNKNOWN,       # Pas encore rencontré dans l'histoire
	AVAILABLE,     # Seïra a préparé le recrutement, Aldric peut le rencontrer
	RECRUITED,     # Dans le pool actif d'Aldric
	DEAD,          # Mort définitivement (permadeath)
	INACCESSIBLE,  # Conditions non remplies — inaccessible pour ce run
}


## Archétype de combat d'un compagnon.
enum CompanionArchetype {
	PROTECTOR,  # Protège Aldric, peut mourir à sa place
	ATTACKER,   # Dégâts élevés
	SUPPORT,    # Soins, utilitaire, information
}


# ─────────────────────────────────────────────────────────────────────────────
# STRUCTURES DE DONNÉES
# ─────────────────────────────────────────────────────────────────────────────

## État complet d'un compagnon dans ce run.
class CompanionState:
	var id: String
	var status: CompanionStatus = CompanionStatus.UNKNOWN
	var seen_by_daven: bool = false      # Daven l'a repéré/protégé
	var prepared_by_seira: bool = false  # Seïra a finalisé le recrutement
	var met_aldric: bool = false         # Aldric l'a rencontré en jeu
	var act_recruited: int = -1          # Acte où il a rejoint (-1 = jamais)
	var act_died: int = -1               # Acte où il est mort (-1 = vivant)
	var scene_died: String = ""          # Identifiant de la scène de sa mort

	func _init(p_id: String) -> void:
		id = p_id

	func is_alive() -> bool:
		return status == CompanionStatus.RECRUITED

	func to_dict() -> Dictionary:
		return {
			"id": id,
			"status": status,
			"seen_by_daven": seen_by_daven,
			"prepared_by_seira": prepared_by_seira,
			"met_aldric": met_aldric,
			"act_recruited": act_recruited,
			"act_died": act_died,
			"scene_died": scene_died,
		}

	func from_dict(d: Dictionary) -> void:
		status = d.get("status", CompanionStatus.UNKNOWN)
		seen_by_daven = d.get("seen_by_daven", false)
		prepared_by_seira = d.get("prepared_by_seira", false)
		met_aldric = d.get("met_aldric", false)
		act_recruited = d.get("act_recruited", -1)
		act_died = d.get("act_died", -1)
		scene_died = d.get("scene_died", "")


# ─────────────────────────────────────────────────────────────────────────────
# SIGNAUX
# ─────────────────────────────────────────────────────────────────────────────

signal flag_changed(flag: NarrativeFlag, value: bool)
signal companion_status_changed(companion_id: String, new_status: CompanionStatus)
signal companion_died(companion_id: String, scene_id: String)
signal act_unlocked(act: int)
signal state_loaded()


# ─────────────────────────────────────────────────────────────────────────────
# ÉTAT INTERNE
# ─────────────────────────────────────────────────────────────────────────────

## Flags narratifs : NarrativeFlag (int) → bool
var _flags: Dictionary = {}

## États des compagnons : companion_id → CompanionState
var _companions: Dictionary = {}

## Progression par acte : personnage → acte courant (1, 2 ou 3)
var _act_progress: Dictionary = {
	"aldric": 1,
	"seira": 1,
	"varek": 1,
	"daven": 1,
}

## Scènes complétées : "personnage_acte" → Array[String] d'ids de scènes
var _scenes_completed: Dictionary = {}

## Acte courant global (le plus bas parmi les 4 personnages)
var current_act: int = 1

## ID des compagnons dans l'ordre
const COMPANION_IDS: Array[String] = [
	"brennan", "lyria", "cain", "mira", "rael",
	"thessa", "orwen", "kira", "brand"
]

## Slots actifs d'Aldric (max 2)
var _aldric_active_slots: Array[String] = []


# ─────────────────────────────────────────────────────────────────────────────
# INITIALISATION
# ─────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_initialize_companions()
	_apply_narrative_locks()


func _initialize_companions() -> void:
	for cid in COMPANION_IDS:
		_companions[cid] = CompanionState.new(cid)


## Certains flags sont toujours vrais — locks narratifs.
func _apply_narrative_locks() -> void:
	# Vel'Shan se produit toujours, quelle que soit la décision de Varek.
	_flags[NarrativeFlag.VEL_SHAN_HAPPENED] = true
	# Les faux documents sont plantés avant que le joueur prenne le contrôle de Daven.
	_flags[NarrativeFlag.FALSE_DOCS_PLANTED] = true


# ─────────────────────────────────────────────────────────────────────────────
# API PUBLIQUE — FLAGS
# ─────────────────────────────────────────────────────────────────────────────

## Définit un flag narratif. Émet flag_changed si la valeur change.
func set_flag(flag: NarrativeFlag, value: bool = true) -> void:
	var prev: bool = _flags.get(flag, false)
	if prev == value:
		return
	_flags[flag] = value
	flag_changed.emit(flag, value)
	_on_flag_changed(flag, value)


## Retourne la valeur d'un flag (false par défaut).
func get_flag(flag: NarrativeFlag) -> bool:
	return _flags.get(flag, false)


## Retourne true si tous les flags du tableau sont vrais.
func all_flags(flags_list: Array) -> bool:
	for f in flags_list:
		if not get_flag(f):
			return false
	return true


## Retourne true si au moins un flag du tableau est vrai.
func any_flag(flags_list: Array) -> bool:
	for f in flags_list:
		if get_flag(f):
			return true
	return false


# ─────────────────────────────────────────────────────────────────────────────
# API PUBLIQUE — COMPAGNONS
# ─────────────────────────────────────────────────────────────────────────────

func get_companion(cid: String) -> CompanionState:
	assert(cid in _companions, "Companion ID inconnu : " + cid)
	return _companions[cid]


func get_companion_status(cid: String) -> CompanionStatus:
	return get_companion(cid).status


## Seïra finalise le recrutement d'un compagnon → devient AVAILABLE pour Aldric.
func seira_prepares_companion(cid: String) -> void:
	var c: CompanionState = get_companion(cid)
	if c.status != CompanionStatus.UNKNOWN:
		return
	c.prepared_by_seira = true
	c.status = CompanionStatus.AVAILABLE
	companion_status_changed.emit(cid, CompanionStatus.AVAILABLE)


## Aldric rencontre et recrute un compagnon disponible.
func aldric_recruits(cid: String, act: int) -> void:
	var c: CompanionState = get_companion(cid)
	assert(c.status == CompanionStatus.AVAILABLE, "Compagnon non disponible : " + cid)
	c.status = CompanionStatus.RECRUITED
	c.met_aldric = true
	c.act_recruited = act
	companion_status_changed.emit(cid, CompanionStatus.RECRUITED)


## Tue un compagnon définitivement. Retire des slots actifs si besoin.
## scene_id : identifiant de la scène où il est mort (pour le log narratif).
func kill_companion(cid: String, scene_id: String = "", act: int = -1) -> void:
	var c: CompanionState = get_companion(cid)
	if c.status == CompanionStatus.DEAD:
		return
	c.status = CompanionStatus.DEAD
	c.act_died = act if act > 0 else current_act
	c.scene_died = scene_id
	_aldric_active_slots.erase(cid)
	companion_status_changed.emit(cid, CompanionStatus.DEAD)
	companion_died.emit(cid, scene_id)


## Rend un compagnon inaccessible pour ce run (conditions ratées).
func make_companion_inaccessible(cid: String) -> void:
	var c: CompanionState = get_companion(cid)
	if c.status in [CompanionStatus.RECRUITED, CompanionStatus.DEAD]:
		return
	c.status = CompanionStatus.INACCESSIBLE
	companion_status_changed.emit(cid, CompanionStatus.INACCESSIBLE)


## Retourne les compagnons vivants dans le pool d'Aldric.
func get_aldric_living_companions() -> Array[String]:
	var result: Array[String] = []
	for cid in COMPANION_IDS:
		if _companions[cid].status == CompanionStatus.RECRUITED:
			result.append(cid)
	return result


## Retourne les slots actifs d'Aldric (max 2).
func get_aldric_active_slots() -> Array[String]:
	return _aldric_active_slots.duplicate()


## Change les compagnons actifs d'Aldric (hors combat uniquement).
func set_aldric_active_slots(slot1: String, slot2: String) -> void:
	var living := get_aldric_living_companions()
	assert(slot1 in living or slot1 == "", "Compagnon slot1 invalide : " + slot1)
	assert(slot2 in living or slot2 == "", "Compagnon slot2 invalide : " + slot2)
	assert(slot1 != slot2 or slot1 == "", "Les deux slots ne peuvent pas être identiques")
	_aldric_active_slots = []
	if slot1 != "":
		_aldric_active_slots.append(slot1)
	if slot2 != "":
		_aldric_active_slots.append(slot2)


## Vérifie si les conditions de recrutement d'un compagnon sont remplies.
## Utilisé par l'UI de Seïra pour griser les fiches.
func can_seira_recruit(cid: String) -> bool:
	match cid:
		"brennan":
			return true  # Toujours accessible, conditions varient
		"lyria":
			return get_flag(NarrativeFlag.REFUGEE_NETWORK_FUNDED)
		"cain":
			return true  # Accessible sans condition de Daven
		"mira":
			return (get_flag(NarrativeFlag.MIRA_PROTECTED)
					and get_flag(NarrativeFlag.REFUGEE_NETWORK_FUNDED))
		"rael":
			return true  # Se présente spontanément
		"thessa":
			return get_flag(NarrativeFlag.THESSA_SHOWN_EVIDENCE)
		"orwen":
			return true  # Dépend du temps investi (3 semaines)
		"kira":
			return (get_flag(NarrativeFlag.KIRA_DOSSIER_ACTED_ON)
					and get_flag(NarrativeFlag.KIRA_EXTRACTION_SUCCESS))
		"brand":
			return get_flag(NarrativeFlag.PRISONER_POLICY_HUMANE)
		_:
			push_warning("can_seira_recruit : ID inconnu " + cid)
			return false


# ─────────────────────────────────────────────────────────────────────────────
# API PUBLIQUE — PROGRESSION PAR ACTES
# ─────────────────────────────────────────────────────────────────────────────

## Marque une scène comme complétée pour un personnage.
func complete_scene(character: String, act: int, scene_id: String) -> void:
	var key: String = "%s_%d" % [character, act]
	if key not in _scenes_completed:
		_scenes_completed[key] = []
	if scene_id not in _scenes_completed[key]:
		_scenes_completed[key].append(scene_id)


## Retourne true si une scène a été complétée.
func is_scene_done(character: String, act: int, scene_id: String) -> bool:
	var key: String = "%s_%d" % [character, act]
	return scene_id in _scenes_completed.get(key, [])


## Marque un personnage comme ayant terminé un acte.
## Vérifie si l'acte suivant peut être déverrouillé.
func finish_act(character: String, act: int) -> void:
	_act_progress[character] = act + 1
	_check_act_unlock()


## Vérifie si tous les personnages ont terminé l'acte courant → déverouille le suivant.
func _check_act_unlock() -> void:
	var min_act: int = 99
	for char_name in _act_progress:
		min_act = min(min_act, _act_progress[char_name])
	if min_act > current_act:
		current_act = min_act
		act_unlocked.emit(current_act)


## Retourne l'acte courant d'un personnage.
func get_character_act(character: String) -> int:
	return _act_progress.get(character, 1)


## Retourne true si un personnage peut commencer l'acte demandé.
func can_start_act(character: String, act: int) -> bool:
	if act == 1:
		return true
	# Un personnage peut commencer l'Acte N si tous ont au moins terminé N-1
	for char_name in _act_progress:
		if _act_progress[char_name] < act:
			return false
	return true


# ─────────────────────────────────────────────────────────────────────────────
# RÉACTIONS AUX FLAGS (effets croisés automatiques)
# ─────────────────────────────────────────────────────────────────────────────

func _on_flag_changed(flag: NarrativeFlag, value: bool) -> void:
	if not value:
		return
	match flag:
		NarrativeFlag.KIRA_EXTRACTION_FAILED:
			# Si Daven rate l'extraction, Kira devient inaccessible immédiatement.
			make_companion_inaccessible("kira")

		NarrativeFlag.RAEL_INTEGRATED:
			# Rael se présente → devient available pour Aldric si Seïra le gère.
			pass  # Traité dans la scène de recrutement de Seïra

		NarrativeFlag.RAEL_REJECTED:
			make_companion_inaccessible("rael")

		NarrativeFlag.LYRIA_WARNED:
			# Lyria survit et peut être recrutée par Seïra.
			pass

		NarrativeFlag.VEL_SHAN_HAPPENED:
			# CP2 se déclenche pour les 4 personnages.
			# Le SceneRouter gère le déclenchement des scènes CP.
			pass


# ─────────────────────────────────────────────────────────────────────────────
# SÉRIALISATION (utilisée par SaveSystem)
# ─────────────────────────────────────────────────────────────────────────────

func to_dict() -> Dictionary:
	var companions_data: Dictionary = {}
	for cid in _companions:
		companions_data[cid] = _companions[cid].to_dict()

	return {
		"flags": _flags.duplicate(),
		"companions": companions_data,
		"act_progress": _act_progress.duplicate(),
		"scenes_completed": _scenes_completed.duplicate(),
		"aldric_active_slots": _aldric_active_slots.duplicate(),
		"current_act": current_act,
	}


func from_dict(data: Dictionary) -> void:
	_flags = data.get("flags", {})
	_act_progress = data.get("act_progress", {"aldric":1,"seira":1,"varek":1,"daven":1})
	_scenes_completed = data.get("scenes_completed", {})
	_aldric_active_slots = data.get("aldric_active_slots", [])
	current_act = data.get("current_act", 1)

	var companions_data: Dictionary = data.get("companions", {})
	for cid in COMPANION_IDS:
		if cid in companions_data:
			_companions[cid].from_dict(companions_data[cid])

	# Toujours réappliquer les locks narratifs après chargement.
	_apply_narrative_locks()
	state_loaded.emit()


func reset() -> void:
	_flags.clear()
	_companions.clear()
	_scenes_completed.clear()
	_aldric_active_slots.clear()
	_act_progress = {"aldric": 1, "seira": 1, "varek": 1, "daven": 1}
	current_act = 1
	_initialize_companions()
	_apply_narrative_locks()
