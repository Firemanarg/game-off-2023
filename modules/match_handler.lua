local nk = require("nakama")
local utils = require("match_utils")
local gen = require("generator")
local scd = require("state_codes")

local READY_OP_CODE = 1
local GAME_STARTING_OP_CODE = 2

local M = {}

function M.match_init(context, params)
	local match_code = params.match_code
	nk.logger_info(string.format("Match code: %s", tostring(match_code)))
	local state = {
		players = {},
		player_count = 0,
		match_code = match_code,
		empty_ticks = 0
	}
	local tick_rate = 1
	local label_data = {
		visibility = "public",
		code = match_code
	}
	local label = nk.json_encode(label_data)

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
		state.players[presence.user_id] = {}
		state.players[presence.user_id]["presence"] = presence
		state.players[presence.user_id]["is_ready"] = false
		state.player_count = state.player_count + 1
	end

	for _, player in pairs(state.players) do
		if player.is_ready then
			dispatcher.broadcast_message(
				scd.OPCODE.READY,
				nk.json_encode({user_id = player.user_id, is_ready = true},
				presences
			))
		end
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

function M.match_leave(context, dispatcher, tick, state, presences)
	for _, presence in ipairs(presences) do
		state.players[presence.user_id] = nil
		state.player_count = state.player_count - 1
	end

	return state
end

local function _loop_check_empty_match(state, max_ticks)

	if state.player_count == 0 then
		state.empty_ticks = state.empty_ticks + 1
	else
		state.empty_ticks = 0
	end

	if state.empty_ticks > max_ticks then
		return true
	else
		return false
	end
end

local function _loop_check_all_players_ready(state)

	local all_ready = true
	for _, player in pairs(state.players) do
		if not player["is_ready"] then
			all_ready = false
			break
		end
	end

	return all_ready
end

function M.match_loop(context, dispatcher, tick, state, messages)

	if _loop_check_empty_match(state, 100) then
		nk.logger_info(
			string.format("Finishing match with code '%s' due to inactivity!", state.match_code))
		utils.unregister_match_code(state.match_code)
		return nil
	end

	for _, message in ipairs(messages) do
		local json = nk.json_decode(message.data)
		if message.op_code == scd.OPCODE.READY then
			local user_id = message.sender.user_id
			local ready_state = json.is_ready
			state.players[user_id]["is_ready"] = ready_state
			if ready_state then
				nk.logger_info(string.format("Player %s is ready", user_id))
			else
				nk.logger_info(string.format("Player %s is not ready", user_id))
			end
			dispatcher.broadcast_message(scd.OPCODE.READY, nk.json_encode(
				{user_id = user_id, is_ready = ready_state}
			))

			-- if _loop_check_all_players_ready(state) then
			-- 	local message = "Game starting!"
			-- 	dispatcher.broadcast_message(GAME_STARTING_OP_CODE, message)
			-- end
		end
	end

	return state
end

function M.match_terminate(context, dispatcher, tick, state, grace_seconds)
	local message = "Server shutting down in " .. grace_seconds .. " seconds"
	dispatcher.broadcast_message(2, message)

	nk.logger_info(
		string.format("Finishing match with code '%s' due to server shutdown!", state.match_code))
	utils.unregister_match_code(state.match_code)

	return nil
end

function M.match_signal(context, dispatcher, tick, state, data)
	return state, "signal received: " .. data
end

return M