local nk = require("nakama")

local Generator = {}

local char_set = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
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

local function _capitalize(str)
	local upper_str = string.upper(string.sub(str, 1, 1))
	local lower_str = string.sub(str, 2, -1)
	return upper_str..lower_str
end

function Generator.is_match_code_unique(match_code)
	nk.logger_info(string.format("Checking if code '%s' is unique...", match_code))
	local data = {
		collection = "RegisteredMatches",
		key = match_code,
		user_id = nil
	}
	local result = nk.storage_read(data)
	local is_unique = true
	for _, _ in ipairs(result) do
		is_unique = false
		break
	end
	if is_unique then
		nk.logger_info("Code is unique!")
	else
		nk.logger_info("Code is not unique!")
	end
	return is_unique
end

function Generator.generate_match_code()
	local code = ""
	repeat
		nk.logger_info("Generating match code!")
		code = ""
		for i=1, 6 do
			local index = math.random(1, string.len(char_set))
			local rand_char = string.sub(char_set, index, index)
			code = code..rand_char
		end
	until Generator.is_match_code_unique(code)
	nk.logger_info(string.format("Generated match code: %s", tostring(match_code)))
	return {match_code = code}
end

function Generator.generate_username()
	math.randomseed(os.time())
	local n_noun = math.random(1, table.getn(nouns))
	local noun = _capitalize(nouns[n_noun])
	local n_adjective = math.random(1, table.getn(adjectives))
	local adjective = _capitalize(adjectives[n_adjective])
	local suffix_number = tostring(math.random(1, 999999))
	local result = noun..adjective..suffix_number
	return result
end

return Generator