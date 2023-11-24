extends Node


signal match_created(match_code)
signal match_creation_failed()
signal match_joined()
signal match_join_failed()
signal match_quickjoin_failed()
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
	print("[join_match]: Joined match: (", match_code, ") ", match_id)
	match_joined.emit()


func quick_join_match() -> void:
	match_ = null
	var joined: bool = await _quickjoin_attempt_find()
	if joined:
		print("[quickjoin_match]: Joined match: (", match_code, ") ", match_.match_id)
		match_joined.emit()
		return
	Online.socket.received_matchmaker_matched.connect(_on_received_matchmaker_matched)
	var min_players: int = 2
	var max_players: int = 8
	var query: String = ""
	var string_properties: Dictionary = {}
	var numeric_properties: Dictionary = {}
	print("[quickjoin_match]: Starting matchmaking...")
	matchmaker_ticket = await Online.socket.add_matchmaker_async(
		query, min_players, max_players, string_properties, numeric_properties
	)


func _quickjoin_attempt_find() -> bool:
	var response = await Online.call_rpc_func("find_available_match")
	if response.is_exception():
		print("[match_error]: Error finding available match")
		match_quickjoin_failed.emit()
		return false
	var json = JSON.parse_string(response.payload)
	var match_id: String = json.get("match_id", "")
	if match_id.is_empty():
		return false
	print("[quickjoin_match]: Found available match: (", match_code, ") ", match_id)
	var joined: bool = await _join_match_by_id(match_id, true)
	if not joined:
		match_join_failed.emit()
		return false
	return true


func _join_match_by_id(match_id: String, emit_signals: bool = true) -> bool:
	match_code = ""
	matchmaker_ticket = null
	match_ = await Online.socket.join_match_async(match_id)
	if match_.is_exception():
		print("[match_error]: >", OnlineMatch.match_.get_exception().message)
		match_ = null
		if emit_signals:
			match_join_failed.emit()
		return false
	Online.socket.received_match_presence.connect(_on_received_match_presence)
	print("[match_code]: Parsing label: ", match_.label)
	var json = JSON.parse_string(match_.label)
	match_code = json.get("code", "")
	_update_match_presences()
	if emit_signals:
		match_joined.emit()
	return true


func _update_match_presences() -> void:
	match_presences.clear()
	if not match_ == null:
		match_presences[match_.self_user.user_id] = match_.self_user
		for presence in match_.presences:
			match_presences[presence.user_id] = presence
		match_presences_changed.emit()


func _on_received_match_presence(match_presence: NakamaRTAPI.MatchPresenceEvent) -> void:
	print("[match_presence (", match_.self_user.username, ")]: received signal: ", match_presence)
	for presence in match_presence.leaves:
		print("\t> Player ", presence.username, " left match")
		OnlineMatch.match_presences.erase(presence.user_id)
	for presence in match_presence.joins:
		print("\t> Player ", presence.username, " joined match")
		OnlineMatch.match_presences[presence.user_id] = presence
	var has_presences_changed: bool = (
		not match_presence.leaves.is_empty()
		or not match_presence.joins.is_empty()
	)
	if has_presences_changed:
		match_presences_changed.emit()


func _on_received_matchmaker_matched(matched: NakamaRTAPI.MatchmakerMatched) -> void:
	print("[matchmaker]: Matched: ", matched.match_id)
	Online.socket.received_matchmaker_matched.disconnect(_on_received_matchmaker_matched)
	var joined: bool = await _join_match_by_id(matched.match_id, true)
	if not joined:
		print("[matchmaker]: Failed to join match")
		return

