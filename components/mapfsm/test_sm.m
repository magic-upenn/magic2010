global MP

% Construct state machine:
MP.sm = statemch('sInitial', ...
                 'sFreeze' ...
                 );

MP.sm = setTransition(MP.sm, 'sInitial', ...
                             'pose', 'sFreeze' ...
                             );

MP.sm = entry(MP.sm);
for i = 1:1000,
  MP.sm = update(MP.sm);
end

