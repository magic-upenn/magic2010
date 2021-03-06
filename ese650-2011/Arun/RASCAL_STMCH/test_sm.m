global MP

dt = 0.05;
% Construct state machine:
MP.sm = statemch('sInitial', ...
                 'sWait', ...
                 'sScan' ...
                 );

MP.sm = setTransition(MP.sm, 'sInitial', ...
                             'pose', 'sWait' ...                                
                             );
MP.sm = setTransition(MP.sm, 'sWait', ...
                             'scan', 'sScan' ...                                
                             );
                         

MP.sm = entry(MP.sm);
for i = 1:1000,
  MP.sm = update(MP.sm);
  pause(dt);
end
