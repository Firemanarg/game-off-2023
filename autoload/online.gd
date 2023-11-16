extends Node


const Scheme: String = "http"
const Host: String = "127.0.0.1"
const Port: int = 7350
const ServerKey: String = "defaultkey"

## Response of auth functions.
enum AuthResponse {
	SUCCESS,		## Successfully auth.
	INVALID_AUTH,	## Invalid field of auth attempt.
	PREV_REG_EMAIL,	## Email was registered previously.
	SOCKET_ERROR,	## Error when connecting socket.
}

var session: NakamaSession = null
var account: NakamaAPI.ApiAccount = null

@onready var client: NakamaClient = Nakama.create_client(
	ServerKey, Host, Port, Scheme, 10, NakamaLogger.LOG_LEVEL.ERROR)
@onready var socket: NakamaSocket = Nakama.create_socket_from(client)


func _ready() -> void:
	pass


func _process(_delta: float) -> void:
	pass


func _physics_process(_delta: float) -> void:
	pass


func call_rpc_func(func_id: String, params: Dictionary = {}) -> NakamaAPI.ApiRpc:
	var json_params = null
	if not params.is_empty():
		json_params = JSON.stringify(params)
	var response: NakamaAPI.ApiRpc = await Online.client.rpc_async(
		Online.session, func_id, json_params
	)
	return response


func device_auth(username = null) -> AuthResponse:
	var device_id: String = OS.get_unique_id()
	session = await client.authenticate_device_async(device_id, username)
	return await _update_online_data(session)
#	if session.is_exception():
#		var exception: NakamaException = session.get_exception()
#		print("[auth_error]: ", exception.message)
#		return AuthResponse.INVALID_AUTH
#	var response: AuthResponse = await _update_account()
#	if not response == AuthResponse.SUCCESS:
#		return response
#	response = await _connect_socket()
#	if not response == AuthResponse.SUCCESS:
#		return response
#	return AuthResponse.SUCCESS


func debug_auth(id: String) -> AuthResponse: # Parei aqui
	session = await client.authenticate_custom_async(id)
	return await _update_online_data(session)


func _update_online_data(session: NakamaSession) -> AuthResponse:
	if session.is_exception():
		var exception: NakamaException = session.get_exception()
		print("[auth_error]: >", exception.message)
		return AuthResponse.INVALID_AUTH
	var response: AuthResponse = await _update_account()
	if not response == AuthResponse.SUCCESS:
		return response
	response = await _connect_socket()
	if not response == AuthResponse.SUCCESS:
		return response
	return AuthResponse.SUCCESS


func _update_account() -> AuthResponse:
	account = await client.get_account_async(session)
	if account.is_exception():
		print("[auth_error]: >", account.get_exception().message)
		return AuthResponse.INVALID_AUTH
	return AuthResponse.SUCCESS


func _connect_socket() -> AuthResponse:
	var response: NakamaAsyncResult = await socket.connect_async(session)
	if response.is_exception():
		print("[socket_error]: >", response.get_exception().message)
		return AuthResponse.SOCKET_ERROR
	return AuthResponse.SUCCESS

