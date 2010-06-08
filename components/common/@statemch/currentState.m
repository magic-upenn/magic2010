function state = currentState(h)
% state = currentState(h)

%state = h.currentState;
state = h.states{h.currentState};
