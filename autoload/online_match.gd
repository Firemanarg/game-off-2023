extends Node


signal match_created(match_code)
signal match_creation_failed()
signal match_joined()
signal match_join_failed()
signal match_quickjoin_failed()
signal match_presences_changed()
signal ready_state_changed()

enum {
	READY_OP_CODE = 1,
	GAME_STARTING_OP_CODE = 2,
}

var match_code: String = ""

@onready var match_: NakamaRTAPI.Match = null
@onready var matchmaker_ticket: NakamaRTAPI.MatchmakerTicket = null

# Key is user_id. Values: "presence": NakamaRTAPI.UserPresence; "is_ready": bool
@onready var match_players: Dictionary = {}


func _ready() -> void:
	pass


func _process(_delta: float) -> void:
	pass


func _physics_process(_delta: float) -> void:
	pass


func create_match() -> void:
	Online.debug_print("create_match", "Creating match...")
	var response: NakamaAPI.ApiRpc = await Online.call_rpc_func("create_match")
	if response.is_exception():
		Online.debug_print("create_match", "Error: " + response.get_exception().message)
		match_creation_failed.emit()
		return
	var json = JSON.parse_string(response.payload)
	var match_id: String = json.get("match_id")
	var match_code: String = json.get("match_code")
	Online.debug_print("create_match", "Match created: (%s) (%s)" % [match_code, match_id])
	await _join_match_by_id(match_id, false)
	match_created.emit(match_code)


func join_match(match_code: String) -> void:
	var payload: Dictionary = {"match_code" : match_code}
	var response = await Online.call_rpc_func("get_match_id_by_code", payload)
	if response.is_exception():
		Online.debug_print("join_match", "Error: " + response.get_exception().message)
		match_ = null
		match_join_failed.emit()
		return
	var json = JSON.parse_string(response.payload)
	var match_id: String = json.get("match_id", "")
	if match_id.is_empty():
		Online.debug_print("join_match", "Error retrieving match_id")
		match_ = null
		match_join_failed.emit()
		return
	var joined: bool = await _join_match_by_id(match_id, true)
	if not joined:
		match_join_failed.emit()
		match_ = null
		return
	match_joined.emit()


func quick_join_match() -> void:
	match_ = null
	var joined: bool = await _quickjoin_attempt_find()
	if joined:
		return
	Online.socket.received_matchmaker_matched.connect(_on_received_matchmaker_matched)
	var min_players: int = 2
	var max_players: int = 8
	var query: String = ""
	var string_properties: Dictionary = {}
	var numeric_properties: Dictionary = {}
	print("[quickjoin_match]: Starting matchmaking...")
	Online.debug_print("quickjoin_match", "Starting matchmaking...")
	matchmaker_ticket = await Online.socket.add_matchmaker_async(
		query, min_players, max_players, string_properties, numeric_properties
	)


func set_ready_state(state: bool) -> void:
	var data: String = JSON.stringify({ "is_ready": state })
	Online.debug_print("set_ready_state", "Sending data: %s" % [str(data)])
	await Online.socket.send_match_state_async(
		match_.match_id,
		READY_OP_CODE,
		data,
	)


func _quickjoin_attempt_find() -> bool:
	var response = await Online.call_rpc_func("find_available_match")
	if response.is_exception():
		Online.debug_print("quickjoin_find", "No available match found")
		match_quickjoin_failed.emit()
		return false
	var json = JSON.parse_string(response.payload)
	var match_id: String = json.get("match_id", "")
	if match_id.is_empty():
		return false
	Online.debug_print("quickjoin_find", "Found available match: (%s) %s" % [match_code, match_id])
	var joined: bool = await _join_match_by_id(match_id, true)
	if not joined:
		match_join_failed.emit()
		return false
	return true


func _join_match_by_id(match_id: String, emit_signals: bool = true) -> bool:
	Online.socket.received_match_presence.connect(_on_received_match_presence)
	Online.socket.received_match_state.connect(_on_received_match_state)
	match_code = ""
	matchmaker_ticket = null
	Online.debug_print("_join_match_by_id", "Cleaning all presences!")
	match_players.clear()
	match_ = await Online.socket.join_match_async(match_id)
	_update_match_presences()
	if match_.is_exception():
		Online.debug_print(
			"_join_match_by_id", "Error: " + OnlineMatch.match_.get_exception().message)
		match_ = null
		if emit_signals:
			match_join_failed.emit()
		return false
	Online.debug_print("_join_match_by_id", "Match code: Parsing label: " + match_.label)
	var json = JSON.parse_string(match_.label)
	match_code = json.get("code", "")
	if emit_signals:
		match_joined.emit()
	Online.debug_print("_join_match_by_id", "Joined match: (%s) %s" % [match_code, match_id])
	return true


func _update_match_presences() -> void:
	Online.debug_print("_update_match_presences", "Updating presences")
	if not match_ == null:
		if not match_players.has(match_.self_user.user_id):
			match_players[match_.self_user.user_id] = {}
		match_players[match_.self_user.user_id]["presence"] = match_.self_user
		for presence in match_.presences:
#			match_presences[presence.user_id] = presence
			if not match_players.has(presence.user_id):
				match_players[presence.user_id] = {}
			match_players[presence.user_id]["presence"] = presence
		match_presences_changed.emit()


func _on_received_match_presence(match_presence: NakamaRTAPI.MatchPresenceEvent) -> void:
	Online.debug_print("match_presence", "Received presences: " + str(match_presence))
	for presence in match_presence.leaves:
		print("\t> Player ", presence.username, " left match")
		match_players.erase(presence.user_id)
	for presence in match_presence.joins:
		print("\t> Player ", presence.username, " joined match")
		if not match_players.has(presence.user_id):
			Online.debug_print(
				"match_presence", "Creating player dict for key " + presence.user_id)
			match_players[presence.user_id] = {}
		match_players[presence.user_id]["presence"] = presence
	var has_presences_changed: bool = (
		not match_presence.leaves.is_empty()
		or not match_presence.joins.is_empty()
	)
	if has_presences_changed:
		match_presences_changed.emit()


func _on_received_match_state(match_state: NakamaRTAPI.MatchData) -> void:
	Online.debug_print("match_state", "Received signal: " + str(match_state))
	var data = JSON.parse_string(match_state.data)
	if match_state.op_code == READY_OP_CODE:
		var user_id: String = data.get("user_id", "")
		var is_ready: bool = data.get("is_ready", true)
		if user_id.is_empty():
			Online.debug_print("match_state", "User ID is empty: Skipping player update.")
			return
		elif not match_players.has(user_id):
			Online.debug_print("match_state", "Creating player dict for key " + str(user_id))
			match_players[user_id] = { "is_ready": is_ready }
			return
		if is_ready:
			Online.debug_print("match_state", "Player %s is ready!" % [user_id])
		else:
			Online.debug_print("match_state", "Player %s is not ready!" % [user_id])
		Online.debug_print(
			"match_state",
			"Received match state for id %s: Setting is_ready to %s" % [user_id, str(is_ready)]
		)
		match_players[user_id]["is_ready"] = is_ready
		Online.debug_print(
			"value_check", "match_players[%s][\"is_ready\"]: %s" % [
				user_id, str(match_players[user_id]["is_ready"])
			]
		)
		ready_state_changed.emit()


func _on_received_matchmaker_matched(matched: NakamaRTAPI.MatchmakerMatched) -> void:
	Online.debug_print("matchmaker", "Matched: " + matched.match_id)
	Online.socket.received_matchmaker_matched.disconnect(_on_received_matchmaker_matched)
	var joined: bool = await _join_match_by_id(matched.match_id, true)
	if not joined:
		Online.debug_print("matchmaker", "Failed to join match")
		return

