local nk = require("nakama")
local utils = require("match_utils")
local gen = require("generator")

local M = {}

function M.match_init(context, params)
	local match_code = params.match_code
	nk.logger_info(string.format("Match code: %s", tostring(match_code)))
	local state = {
		presences = {},
		match_code = match_code
	}
	local tick_rate = 1
	local label = "code=" .. match_code

	return state, tick_rate, label
end

function M.match_join(context, dispatcher, tick, state, presences)
	-- Presences format:
	-- {
	--   {
	--     user_id = "user unique ID",
	--     session_id = "session ID of the user's current connection",
	--     username = "user's unique username",
	--     node = "name of the Nakama node the user is connected to"
	--   },
	--  ...
	-- }
	for _, presence in ipairs(presences) do
		state.presences[presence.session_id] = presence
	end
	return state
  end

function M.match_join_attempt(context, dispatcher, tick, state, presence, metadata)
	local acceptuser = true
	-- Presence format:
	-- {
	--   user_id = "user unique ID",
	--   session_id = "session ID of the user's current connection",
	--   username = "user's unique username",
	--   node = "name of the Nakama node the user is connected to"
	-- }
	return state, acceptuser
end

-- function M.match_join(context, dispatcher, tick, state, presences)
--   for _, presence in ipairs(presences) do
--     state.presences[presence.session_id] = presence
--   end

--   return state
-- end

function M.match_leave(context, dispatcher, tick, state, presences)
	for _, presence in ipairs(presences) do
		state.presences[presence.session_id] = nil
	end

	nk.logger_info(string.format("Player left. Presences count: %s", tostring(table.getn(state.presences))))
	if table.getn(state.presences) == 0 then
		nk.logger_info(string.format("Finishing match with code '%s'", state.match_code))
		utils.unregister_match_code(state.match_code)
		return nil
	end

	return state
end

function M.match_loop(context, dispatcher, tick, state, messages)
	return state
end

function M.match_terminate(context, dispatcher, tick, state, grace_seconds)
  local message = "Server shutting down in " .. grace_seconds .. " seconds"
  dispatcher.broadcast_message(2, message)

  utils.unregister_match_code(state.match_code)

  return nil
end

function M.match_signal(context, dispatcher, tick, state, data)
  return state, "signal received: " .. data
end

return M