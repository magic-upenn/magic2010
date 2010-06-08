function h = entry(h)
%start Start state machine.

h.entryTime = clock;
feval(h.states{h.currentState}, 'entry');

h.status = 'Running';
