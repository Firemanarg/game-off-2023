extends Node


const Scheme: String = "http"
const Host: String = "127.0.0.1"
const Port: int = 7350
const ServerKey: String = "defaultkey"

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

