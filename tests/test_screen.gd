extends Node


@export var skill_origin: Node

var is_authed: bool = false
var is_on_match: bool = false


func _ready() -> void:
	OnlineMatch.match_created.connect(_on_match_created)
	OnlineMatch.match_joined.connect(_on_match_joined)
	OnlineMatch.match_presences_changed.connect(_update_players_list)
	OnlineMatch.ready_state_changed.connect(_on_ready_state_changed)
#	var auth_response: Online.AuthResponse = await Online.device_auth()
	randomize()	# DEBUG
	var random_auth_id: String = str(100000 + randi() % 100000)	# DEBUG
	var auth_response: Online.AuthResponse = await Online.debug_auth(random_auth_id)	# DEBUG
	if not auth_response == Online.AuthResponse.SUCCESS:
		return
	Online.session.refresh(Online.session)
	Online.debug_print("test_screen", "Player is authenticated!")
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
	Online.debug_print("update_players_list", "Checking players ready state:")
	print("\t#> Match Players: ", OnlineMatch.match_players)
	for player in OnlineMatch.match_players.values():
		if not player.has("presence"):
			continue
		var text: String = player.presence.username
		print("\t> Player data: ", player)
		print("\t> Player ", player.presence.username,
			" is ready!" if player.get("is_ready", false) else " is not ready!")
		if player.get("is_ready", false):
			text += " - READY"
			print("\t> [update_players_list]: Player ", player.presence.username, " is ready!")
			print("\t> Text: ", text)
		%ItemListPlayers.add_item(text, null, false)
	Online.debug_print("players_list", "updated")


func _on_match_created(match_created) -> void:
	is_on_match = true
	_update_fields()


func _on_match_joined() -> void:
	is_on_match = true
	_update_fields()


func _on_button_create_match_pressed() -> void:
	Online.debug_print("button_pressed", "Pressed 'create_match'")
	await OnlineMatch.create_match()


func _on_button_join_match_pressed() -> void:
	var match_code: String = %LineEditMatchCode.text
	Online.debug_print("button_pressed", "Pressed 'join_match'")
	await OnlineMatch.join_match(match_code)


func _on_button_quick_join_match_pressed() -> void:
	Online.debug_print("button_pressed", "Pressed 'quickjoin_match'")
	await OnlineMatch.quick_join_match()


func _on_button_ready_pressed() -> void:
	Online.debug_print("button_pressed", "Pressed 'ready'")
	%ButtonReady.disabled = true
	OnlineMatch.set_ready_state(true)
	pass

func _on_ready_state_changed() -> void:
	Online.debug_print("test_screen", "Signal received: ready_state_changed")
	_update_players_list()

