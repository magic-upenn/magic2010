function h = addState(h, state, varargin)
%setState Add state to state machine.

nstate = h.nStates+1;
h.nStates = nstate;
h.states{nstate} = state;
h.statesHash.(state) = nstate;

h.transitions{nstate} = struct();
