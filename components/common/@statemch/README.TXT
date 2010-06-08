This directory implements a generic state machine object
for Matlab.

To use it, make sure that the @statemch directory is
located in a parent directory that's in your Matlab path.

First define states in .m files as follows:

%--- BEGIN State1.m file
function ret = State1(event, varargin);

persistent update_count entry_time;
max_time = 1.0;

switch event
  case 'entry'
    update_count = 0;
    entry_time = clock;
    disp('State1 entry');

  case 'exit'
    
  case 'update'
    update_count = update_count+1;
    disp('State1 update');

    if (etime(clock, entry_time) > max_time),
      ret = 'timeout';
      return;
    end

  otherwise
    warning('Unknown state event');
end
ret = [];

%--- END State1.m file


Then you setup the statemch object in Matlab as follows:

sm = statemch('State1', ...
	      'State2', ...
	      );

sm = setTransition(sm,'State1', ...
                      'timeout','State2'...
                  );
sm = setTransition(sm,'State2', ...
                      'timeout','State1'...
                      'success','State2'...
                  );

sm = start(sm);
for i = 1:1000,
  pause(0.1);
  sm = update(sm);
end
