function disp(h)
% DISP Display method for the statemch object.

disp('  State Machine');
disp(sprintf('    status: %s', h.status));
disp(['    states:' sprintf(' ''%s''',h.states{:})]);
disp(sprintf('    current state: %d', h.currentState));
disp(sprintf('    next state: %d', h.nextState));
for istate = 1:h.nStates
  disp(sprintf('    state[%d]:',istate));
  disp(h.transitions{istate});
end
disp(sprintf(['   events:' sprintf(' %s', h.events{:})]));
