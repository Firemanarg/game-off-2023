extends Node


@export var skill_origin: Node

var is_authed: bool = false
var is_on_match: bool = false


func _ready() -> void:
	print("Test screen")
	OnlineMatch.match_created.connect(_on_match_created)
	OnlineMatch.match_joined.connect(_on_match_joined)
	OnlineMatch.match_presences_changed.connect(_update_players_list)
#	var auth_response: Online.AuthResponse = await Online.device_auth()
	var auth_response: Online.AuthResponse = await Online.debug_auth(	# DEBUG
		Time.get_time_string_from_system())	# DEBUG
	print("Auth response: ", auth_response)
	if not auth_response == Online.AuthResponse.SUCCESS:
		return
	is_authed = true
	_update_fields()


func _process(_delta: float) -> void:
	pass


func _physics_process(_delta: float) -> void:
	pass


func _update_fields() -> void:
	# Login Info
	%LineEditUsername.set_text("")
	%LineEditUserID.set_text("")

	# Multiplayer Menu
#	%LineEditMatchCode.set_text("")

	# Match Lobby
	%LineEditLobbyCode.set_text("")
	%ItemListPlayers.clear()

	if is_authed:
		%LineEditUsername.set_text(Online.account.user.username)
		%LineEditUserID.set_text(Online.account.user.id)
	if is_on_match:
		%LineEditLobbyCode.set_text(OnlineMatch.match_code)
		_update_players_list()


func _update_players_list() -> void:
	%ItemListPlayers.clear()
	%ItemListPlayers.add_item(OnlineMatch.match_.self_user.username)
	for presence in OnlineMatch.match_presences:
		%ItemListPlayers.add_item(presence.username, null, false)


func _on_match_created(match_created) -> void:
	is_on_match = true
	_update_fields()


func _on_match_joined() -> void:
	is_on_match = true
	_update_fields()


func _on_button_create_match_pressed() -> void:
	await OnlineMatch.create_match()


func _on_button_join_match_pressed() -> void:
	var match_code: String = %LineEditMatchCode.text
	await OnlineMatch.join_match(match_code)


func _on_button_quick_join_match_pressed() -> void:
	pass # Replace with function body.
