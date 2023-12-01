local nk = require("nakama")
local gen = require("generator")

local LoginUtils = {}

-- local nouns = {
-- 	"rain", "squirrel", "porter", "company", "knee", "face", "cow", "slope",
-- 	"pear", "show", "spot", "frame", "way", "orange", "visitor", "nose",
-- 	"bridge", "leg", "deer", "edge", "cushion", "rail", "smile", "books",
-- 	"brake", "eggs", "butter", "ray", "giraffe", "roof", "song", "mountain",
-- 	"clouds", "ants", "rabbits", "powder", "tail", "zinc", "game", "gate",
-- 	"fan", "sleet", "can", "coil", "turn", "magic", "stick", "jewel",
-- 	"cave", "spark", "potato", "night"
-- }
-- local adjectives = {
-- 	"overt", "madly", "slimy", "sloppy", "damp", "secret", "handy",
-- 	"mighty", "sudden", "cute", "half", "serious", "fabulous", "omniscient",
-- 	"shaggy", "gainful", "misty", "special", "hard", "pink", "clean",
-- 	"shallow", "annoying", "unsightly", "careless", "lethal", "curious",
-- 	"ashamed", "precious", "accurate", "difficult", "uttermost", "amuck",
-- 	"knotty", "tall", "flimsy", "elite", "swanky", "cold", "drab", "few",
-- 	"shy", "cut", "high", "jagged", "skillful", "spiffy", "talented",
-- 	"tight", "rustic", "whole", "tangible"
-- }

-- local function capitalize(str)
-- 	local upper_str = string.upper(string.sub(str, 1, 1))
-- 	local lower_str = string.sub(str, 2, -1)
-- 	return upper_str..lower_str
-- end

-- Util function
function LoginUtils.is_username_taken(username)
	local query = [[
		SELECT id FROM users WHERE username = $1::TEXT
	]]
	local params = {username}
	local rows = nk.sql_query(query, params)
	for i, row in ipairs(rows)
	do
		return true
	end
	return false
end

-- RPC function
function LoginUtils.rpc_is_username_taken(_, payload)
	local json = nk.json_decode(payload)
	local username = json.username
	local is_taken = _is_username_taken(username)
	return nk.json_encode({is_taken = is_taken})
end
	-- local json = nk.json_decode(payload)
	-- local query = [[
	-- 	SELECT id FROM users WHERE username = $1::TEXT
	-- ]]
	-- local username = json.username
	-- local params = {username}
	-- local rows = nk.sql_query(query, params)
	-- for i, row in ipairs(rows)
	-- do
	-- 	return nk.json_encode({is_taken = "true"})
	-- end
	-- return nk.json_encode({is_taken = "false"})
-- end

function LoginUtils.generate_unique_username()
	local is_taken = true
	local username = ""
	repeat
		local success, result = pcall(gen.generate_username)
		if not success then
			nk.logger_info(string.format("Failed request %q", result))
			error("Unable to generate username")
		else
			username = result
			is_taken = LoginUtils.is_username_taken(username)
		end
	until not is_taken
	if username == "" then
		error("Unable to generate username")
	else
		return username
	end
end

function LoginUtils.rpc_generate_unique_username(_, _)
	local username = LoginUtils.generate_unique_username()
	return nk.json_encode({username = username})
end
	-- local success, result = pcall(gen.generate_username)
	-- if not success then
	-- 	nk.logger_info(string.format("Failed request %q", result))
	-- 	error("Unable to generate username")
	-- else
	-- 	local username = result.username
	-- 	local is_taken = UsernameUtils.is_username_taken(username)
	-- 	while is_taken do
	-- 		username = gen.generate_username()
	-- 		is_taken = UsernameUtils.is_username_taken(username)
	-- 	end
	-- 	return nk.json_encode({username = username})
	-- end
-- end

function LoginUtils.set_username(_, payload)
	local json = nk.json_decode(payload)
	local username = json.username
	local user_id = json.user_id
	local error = nk.account_update_id(user_id, {}, username, nil, nil, nil, nil, nil)
	if not error == nil then
		nk.logger_info(string.format("Failed request %q", error))
		error("Unable to set username")
	end
end

local function generate_new_account_username(context, payload)
	if payload.created then
		local user_id = context.user_id
		local username = LoginUtils.generate_unique_username()
		LoginUtils.set_username(
			context, nk.json_encode({username = username, user_id = user_id}))
	end
	return payload
end

nk.register_req_after(generate_new_account_username, "AuthenticateDevice")
nk.register_req_after(generate_new_account_username, "AuthenticateCustom")

nk.register_rpc(LoginUtils.rpc_generate_unique_username, "generate_unique_username")
nk.register_rpc(LoginUtils.rpc_is_username_taken, "is_username_taken")

return LoginUtils
