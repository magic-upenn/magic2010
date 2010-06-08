function h = setTransition(h, state, varargin)
%setTransition Set transitions from a state in state machine.

istate = getStateIndex(h, state);
if isempty(istate),
  error('Unknown state');
end

transitions = h.transitions{istate};
if isempty(transitions),
  transitions = struct();
end

for itrans = 1:2:length(varargin);
  retcode = varargin{itrans};
  nextstate = varargin{itrans+1};

  transitions.(retcode) = getStateIndex(h, nextstate);
end

h.transitions{istate} = transitions;
