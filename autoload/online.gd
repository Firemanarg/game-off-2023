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


func _process(delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	pass


func device_auth(username = null) -> AuthResponse:
	var device_id: String = OS.get_unique_id()

	session = await client.authenticate_device_async(device_id, username)
	if session.is_exception():
		var exception: NakamaException = session.get_exception()
		print("[auth_error]: ", exception.message)
		return AuthResponse.INVALID_AUTH
	return AuthResponse.SUCCESS

