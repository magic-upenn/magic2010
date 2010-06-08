function state = previous_state(h)
% state = previous_state(h)

if ~isempty(h.history),
  state = h.history{1};
else
  state = '';
end
