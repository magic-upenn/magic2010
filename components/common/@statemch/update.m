function h = update(h)
% Update state machine.

currentStateName = h.states{h.currentState};

% If set_state has not been called, update current state function:
if isempty(h.nextState),
  ret = feval(currentStateName, 'update');
  if ~isempty(ret) && isstr(ret),
    % Append return in events
    h.events{end+1} = ret;
  end

  for i = 1:length(h.events)
    event = h.events{i};
    next = h.transitions{h.currentState}.(ret);
    if ~isempty(next),
      h.nextState = next;
      break;
    else
      warning('Unknown event: %s from state %d', event, h.currentState);
    end
  end
  h.events = {};
end

if ~isempty(h.nextState),
  feval(currentStateName, 'exit');
  h.history = {currentStateName, h.history{1:end-1}};

  h.currentState = h.nextState;
  currentStateName = h.states{h.currentState};
  h.nextState = [];
  h.entryTime = clock;
  
  feval(currentStateName, 'entry');    
end
