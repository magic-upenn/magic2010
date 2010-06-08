function h = setState(h, state, varargin)
%setState Set state in state machine.

if ischar(state),
  % Set next state with string name
  h.nextState = find(strcmp(h.states, state));
  if isempty(h.nextState),
    warning(sprintf('Could not set state to: %s', state));
  end
else
  % Set next state with numeric index
  h.nextState = state;
end
