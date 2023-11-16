extends Node


signal match_created(match_code)
signal match_creation_failed()
signal match_joined()
signal match_join_failed()
signal match_presences_changed()

var match_code: String = ""

@onready var match_: NakamaRTAPI.Match = null
@onready var matchmaker_ticket: NakamaRTAPI.MatchmakerTicket = null

## [code]key[/code]: [param user_id] as [String]
## | [code]value[/code]: [param presence] as [code]NakamaRTAPI.UserPresence[/code]
@onready var match_presences: Dictionary = {}


func _ready() -> void:
	pass


func _process(_delta: float) -> void:
	pass


func _physics_process(_delta: float) -> void:
	pass


func create_match() -> void:
	var response: NakamaAPI.ApiRpc = await Online.call_rpc_func("create_match")
	if response.is_exception():
		print("[match_error]: >", response.get_exception().message)
		match_creation_failed.emit()
		return
	var json = JSON.parse_string(response.payload)
	var match_id: String = json.get("match_id")
	var match_code: String = json.get("match_code")
	await _join_match_by_id(match_id, false)
	match_created.emit(match_code)
	Online.socket.received_match_presence.connect(_on_received_match_presence)


func _join_match_by_id(match_id: String, emit_signals: bool = true) -> bool:
	match_code = ""
	match_presences.clear()
	matchmaker_ticket = null
	match_ = await Online.socket.join_match_async(match_id)
	if match_.is_exception():
		print("[match_error]: >", OnlineMatch.match_.get_exception().message)
		match_ = null
		if emit_signals:
			match_join_failed.emit()
		return false
	var label_fields: PackedStringArray = match_.label.split(" ")
	for field in label_fields:
		if field.begins_with("code="):
			match_code = field.split("=")[1]
			break
	if emit_signals:
		match_joined.emit()
	return true


func join_match(match_code: String) -> void:
	var payload: Dictionary = {"match_code" : match_code}
	var response = await Online.call_rpc_func("get_match_id_by_code", payload)
	if response.is_exception():
		print("[match_error]: >", response.get_exception().message)
		match_ = null
		match_join_failed.emit()
		return
	var json = JSON.parse_string(response.payload)
	var match_id: String = json.get("match_id", "")
	if match_id.is_empty():
		print("[match_error]: Error retrieving match_id!")
		match_ = null
		match_join_failed.emit()
		return
	var joined: bool = await _join_match_by_id(match_id, true)
	if not joined:
		match_join_failed.emit()
		match_ = null
		return
	match_joined.emit()
	Online.socket.received_match_presence.connect(_on_received_match_presence)


func _on_received_match_presence(match_presence: NakamaRTAPI.MatchPresenceEvent) -> void:
	for presence in match_presence.leaves:
		OnlineMatch.match_presences.erase(presence.user_id)
	for presence in match_presence.joins:
		OnlineMatch.match_presences[presence.user_id] = presence
	var has_presences_changed: bool = not (
		match_presence.leaves.is_empty() or match_presence.joins.is_empty()
	)
	if has_presences_changed:
		match_presences_changed.emit()

