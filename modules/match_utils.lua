local nk = require("nakama")
local gen = require("generator")

local MatchUtils = {}

function MatchUtils.register_match_code(match_code, match_id)
	local data = {
		collection = "RegisteredMatches",
		key = match_code,
		user_id = nil,
		value = {match_id = match_id},
		permission_read = 2,
		permission_write = 0
	}
	nk.storage_write({data})
	nk.logger_info(string.format(
		"Registered match '%s' with code '%s'.", match_id, match_code))
end

function MatchUtils.unregister_match_code(match_code)
	local data = {
		collection = "RegisteredMatches",
		key = match_code,
		user_id = nil
	}
	nk.storage_delete({data})
	nk.logger_info(string.format("Unregistered match with code '%s'.", match_code))
end

local function _get_registered_match(match_code)
	nk.logger_info(string.format("Attempting to get match with code %s", match_code))
	local data = {
		collection = "RegisteredMatches",
		key = match_code,
		user_id = nil
	}
	local result = nk.storage_read({data})
	if table.getn(result) > 0 then
		local value = result[1].value
		local match_id = value.match_id
		return match_id
	else
		return nil
	end
end

local function create_match(context, _)
	local success, result = pcall(gen.generate_match_code)
	if not success then
		nk.logger_info(string.format("Failed request %q", result))
		error("Unable to generate match code")
	else
		local match_code = result.match_code
		local modulename = "match_handler"
		local initialstate = {match_code = match_code}
		local match_id = nk.match_create(modulename, initialstate)
		MatchUtils.register_match_code(match_code, match_id)
		local result = {
			match_id = match_id,
			match_code = match_code
		}
		return nk.json_encode(result)
	end
end

local function get_match_id_by_code(_, payload)
	local json = nk.json_decode(payload)
	local match_code = json.match_code
	local match_id = _get_registered_match(match_code)
	if match_id == nil then
		nk.logger_info(string.format("Match with code %s not found!", match_code))
		error(string.format("Match with code %s not found!", match_code))
		match_code = nil
	end
	local result = {
		match_id = match_id,
		match_code = match_code
	}
	nk.logger_info(string.format(
		"Returning result: match_id='%s' | match_code='%s'", match_id, match_code))
	return nk.json_encode(result)
end

nk.register_rpc(create_match, "create_match")
nk.register_rpc(get_match_id_by_code, "get_match_id_by_code")

return MatchUtils