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

local function create_match(context, payload)
	local success, result = pcall(gen.generate_match_code)
	if not success then
		nk.logger_info(string.format("Failed request %q", result))
		error("Unable to generate match code")
	else
		local match_code = result.match_code
		local modulename = "match_handler"
		local invited = {}
		if payload.invited ~= nil then
			invited = payload.invited
		end
		local initialstate = {
			match_code = match_code,
			invited = invited
		}
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

local function find_available_match(context, _)
	local limit = 10
	local min_size = 0
	local max_size = 8
	local filter = "+label.visibility:public"
	local matches = nk.match_list(limit, true, "", min_size, max_size, filter)
	local match_id = nil

	nk.logger_info(string.format("Result of match listing: %s matches found!",
		table.getn(matches)))
	if (table.getn(matches) > 0) then
		table.sort(matches, function(a, b)
			return a.size > b.size;
		end)
		match_id = matches[1].match_id
	end
	return nk.json_encode({match_id = match_id})
end

local function on_matchmaker_matched(context, matched_users)
	local success, result = pcall(gen.generate_match_code)
	if not success then
		nk.logger_info(string.format("Failed request %q", result))
		error("Unable to generate match code")
		return nil
	else
		local match_code = result.match_code
		local modulename = "match_handler"
		local initialstate = {
			match_code = match_code,
			invited = matched_users
		}
		local match_id = nk.match_create("match_handler", initialstate)
		nk.logger_info(string.format("Matchmaker matched: Match ID: %s", match_id))
		return match_id
	end
end

nk.register_rpc(create_match, "create_match")
nk.register_rpc(get_match_id_by_code, "get_match_id_by_code")
nk.register_rpc(find_available_match, "find_available_match")

nk.register_matchmaker_matched(on_matchmaker_matched)

return MatchUtils