local nk = require("nakama")

local nouns = {
	"rain", "squirrel", "porter", "company", "knee", "face", "cow", "slope",
	"pear", "show", "spot", "frame", "way", "orange", "visitor", "nose",
	"bridge", "leg", "deer", "edge", "cushion", "rail", "smile", "books",
	"brake", "eggs", "butter", "ray", "giraffe", "roof", "song", "mountain",
	"clouds", "ants", "rabbits", "powder", "tail", "zinc", "game", "gate",
	"fan", "sleet", "can", "coil", "turn", "magic", "stick", "jewel",
	"cave", "spark", "potato", "night"
}
local adjectives = {
	"overt", "madly", "slimy", "sloppy", "damp", "secret", "handy",
	"mighty", "sudden", "cute", "half", "serious", "fabulous", "omniscient",
	"shaggy", "gainful", "misty", "special", "hard", "pink", "clean",
	"shallow", "annoying", "unsightly", "careless", "lethal", "curious",
	"ashamed", "precious", "accurate", "difficult", "uttermost", "amuck",
	"knotty", "tall", "flimsy", "elite", "swanky", "cold", "drab", "few",
	"shy", "cut", "high", "jagged", "skillful", "spiffy", "talented",
	"tight", "rustic", "whole", "tangible"
}

local function capitalize(str)
	local upper_str = string.upper(string.sub(str, 1, 1))
	local lower_str = string.sub(str, 2, -1)
	return upper_str..lower_str
end

local function is_username_taken(_, payload)
	local json = nk.json_decode(payload)
	local query = [[
		SELECT id FROM users WHERE username = $1::TEXT
	]]
	local username = json.username
	local params = {username}
	local rows = nk.sql_query(query, params)
	for i, row in ipairs(rows)
	do
		return nk.json_encode({is_taken = "true"})
	end
	return nk.json_encode({is_taken = "false"})
end

local function generate_username(_, _)
	math.randomseed(os.time())
	local n_noun = math.random(1, table.getn(nouns))
	local noun = capitalize(nouns[n_noun])
	local n_adjective = math.random(1, table.getn(adjectives))
	local adjective = capitalize(adjectives[n_adjective])
	local suffix_number = tostring(math.random(1, 999999))
	local result = noun..adjective..suffix_number
	return nk.json_encode({username = result})
end

nk.register_rpc(generate_username, "generate_username")
nk.register_rpc(is_username_taken, "is_username_taken")
