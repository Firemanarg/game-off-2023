local Codes = {}

Codes.OPCODE = {
	READY = 1,
	START = 2,
	END = 3,
	UPDATE = 4,
	MESSAGE = 5
}

Codes.MATCH_STATUS = {
	WAITING_FOR_PLAYERS_READY = 1,
	STARTING = 2,
	PLAYING = 3,
	ENDED = 4
}

return Codes