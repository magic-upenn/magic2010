function istate = getStateIndex(h, state)
% istate = getStateIndex(h, state)

istate = find(strcmp(h.states, state));
