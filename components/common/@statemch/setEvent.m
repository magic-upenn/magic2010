function h = setEvent(h, event)
%setEvent Set event in state machine.

h.events{end+1} = event;
