local TimerUtils = {}

function TimerUtils.new_timer(duration, tick_rate)
	if tick_rate == nil or tick_rate < 0 then
		tick_rate = 1
	end
	local timer = {}
	timer["duration"] = duration	-- in milliseconds
	timer["elapsed_time"] = 0		-- in milliseconds
	timer["tick_rate"] = tick_rate	-- in milliseconds
	timer["is_running"] = false
	timer["is_paused"] = false
	timer["is_finished"] = false
	return timer
end

function TimerUtils.start(timer)
	timer.is_running = true
end

function TimerUtils.stop(timer)
	timer.is_running = false
end

function TimerUtils.pause(timer)
	timer.is_paused = true
end

function TimerUtils.resume(timer)
	timer.is_paused = false
end

function TimerUtils.reset(timer)
	timer.elapsed_time = 0
	timer.is_running = false
	timer.is_paused = false
	timer.is_finished = false
end

function TimerUtils.restart(timer)
	TimerUtils.reset(timer)
	TimerUtils.start(timer)
end

function TimerUtils.tk_increase(timer, ticks)
	if timer.is_running and not timer.is_paused then
		local ms_ticks = ticks * (1000.0 / timer.tick_rate)
		timer.elapsed_time = timer.elapsed_time + ms_ticks
		if timer.elapsed_time >= timer.duration then
			timer.elapsed_time = timer.duration
			timer.is_finished = true
		end
	end
end

function TimerUtils.ms_increase(timer, msecs)
	if timer.is_running and not timer.is_paused then
		timer.elapsed_time = timer.elapsed_time + msecs
		if timer.elapsed_time >= timer.duration then
			timer.elapsed_time = timer.duration
			timer.is_finished = true
		end
	end
end

function TimerUtils.remaining_time(timer)	-- in milliseconds
	return timer.duration - timer.elapsed_time
end

function TimerUtils.is_finished(timer)
	return timer.is_finished
end

function TimerUtils.is_running(timer)
	return timer.is_running
end

return TimerUtils
