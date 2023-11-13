extends Node


signal match_created(match_code)
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
	print("[match]: function create called")	# DEBUG
	var response: NakamaAPI.ApiRpc = await Online.call_rpc_func("generate_match_code")
	if response.is_exception():
		print("[match_creation]: error while generating match code")
		return
	match_code = JSON.parse_string(response.payload).get("match_code")
	print("[match]: generated code: ", match_code)
	OnlineMatch.match_ = await Online.socket.create_match_async(match_code)
	if OnlineMatch.match_.is_exception():
		pass
	match_created.emit(match_code)
	print("[match]: created successfully!")
	Online.socket.received_match_presence.connect(_on_received_match_presence)
	return


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

