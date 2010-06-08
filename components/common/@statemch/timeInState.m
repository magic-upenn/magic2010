function t = time_in_state(h)
% t = time_in_state(h)

t = etime(clock,h.entry_time);
