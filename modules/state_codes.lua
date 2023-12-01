local Codes = {}

Codes.OPCODE = {
	READY = 1,		-- Sent by client to indicate that the player is ready
	COUNTDOWN = 2,	-- Sent by server to indicate that all players are ready
	START = 3,		-- Sent by server to indicate that the game is starting (after countdown)
	UPDATE = 4,
	MESSAGE = 5,
	JOINING = 6,
	END = 7
}

Codes.MATCH_STATUS = {
	ON_LOBBY = 1,
	STARTING = 2,
	PLAYING = 3,
	ENDED = 4
}

Codes.COUNTDOWN_STATE = {
	STARTED = 1,
	FINISHED = 2,
	STOPPED = 3
}

return Codes