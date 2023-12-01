local nk = require("nakama")
local tmr = require("timer_utils")
local utils = require("match_utils")
local codes = require("state_codes")

local MatchLoop = {}

local function _procedure_opcode_ready(dispatcher, state, sender_id, is_ready)

	state.players[sender_id]["is_ready"] = is_ready
	if is_ready then
		nk.logger_info(string.format("Player %s is ready", sender_id))
	else
		nk.logger_info(string.format("Player %s is not ready", sender_id))
	end
	dispatcher.broadcast_message(codes.OPCODE.READY, nk.json_encode(
		{user_id = sender_id, is_ready = is_ready}
	))
	nk.logger_info(string.format(
		"[match_loop][broadcast]: sending 'ready' message to all players: Player %s is ready: %s",
		sender_id, tostring(is_ready)))
end

local function _loop_check_all_players_ready(dispatcher, state)

	local all_ready = true
	for _, player in pairs(state.players) do
		if not player["is_ready"] then
			all_ready = false
			break
		end
	end

	local timer = state.tmr_countdown
	if all_ready then
		state.match_status = codes.MATCH_STATUS.STARTING
		dispatcher.broadcast_message(
			codes.OPCODE.COUNTDOWN, nk.json_encode({
				stage = codes.COUNTDOWN_STATE.STARTED,
				remaining_msecs = tmr.remaining_time(timer)
			}))
		nk.logger_info("[match_loop][broadcast]: sending 'countdown started' message to all players")
		tmr.restart(timer)
	else
		-- Check if countdown is running when someone signals not ready
		if state.match_status == codes.MATCH_STATUS.STARTING then
			-- Interrupt countdown
			state.match_status = codes.MATCH_STATUS.ON_LOBBY
			dispatcher.broadcast_message(
				codes.OPCODE.COUNTDOWN, nk.json_encode({
					stage = codes.COUNTDOWN_STATE.STOPPED
				}))
			nk.logger_info("[match_loop][broadcast]: sending 'countdown stopped' message to all players")
			tmr.stop(timer)
		end
	end
end

local function _loop_check_messages(context, dispatcher, state, messages)

	for _, message in ipairs(messages) do
		local json = nk.json_decode(message.data)
		if message.op_code == codes.OPCODE.READY then
			_procedure_opcode_ready(
				dispatcher, state, message.sender.user_id, json.is_ready)
			_loop_check_all_players_ready(dispatcher, state)
		end
	end
end

local function _loop_check_empty_match(state)

	local timer = state.tmr_empty_match

	if state.player_count == 0 then
		if not tmr.is_running(timer) then
			tmr.restart(timer)
		end
		tmr.tk_increase(timer, 1)
	else
		tmr.reset(timer)
	end

	if tmr.is_finished(timer) then
		return true
	else
		return false
	end
end

local function _procedure_opcode_countdown(context, dispatcher, tick, state, messages)

	local timer = state.tmr_countdown

	if state.match_status == codes.MATCH_STATUS.STARTING then
		tmr.tk_increase(state.tmr_countdown, 1)

		if tmr.is_finished(state.tmr_countdown) then
			state.match_status = codes.MATCH_STATUS.PLAYING
			dispatcher.broadcast_message(
				codes.OPCODE.COUNTDOWN, nk.json_encode({
					stage = codes.COUNTDOWN_STATE.FINISHED
				}))
			nk.logger_info("[match_loop][broadcast]: sending 'countdown finished' message to all players")
			-- dispatcher.broadcast_message(
			-- 	codes.OPCODE.START, nk.json_encode({}))
			-- nk.logger_info("[match_loop][broadcast]: sending start message to all players")
		end

	end
end

function MatchLoop.loop(context, dispatcher, tick, state, messages)

	if _loop_check_empty_match(state) then
		nk.logger_info(
			string.format("Finishing match with code '%s' due to inactivity!", state.match_code))
		utils.unregister_match_code(state.match_code)
		return nil
	end

	_loop_check_messages(context, dispatcher, state, messages)

	_procedure_opcode_countdown(context, dispatcher, tick, state, messages)

	return state
end

return MatchLoop