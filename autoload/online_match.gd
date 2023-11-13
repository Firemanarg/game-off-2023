extends Node


signal match_created(match_code)

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
	return

