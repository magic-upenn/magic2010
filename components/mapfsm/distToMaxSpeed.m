function v = distToMaxSpeed(d)
% v = distToMaxSpeed(d)
% Convert obstacle detection distance to max speed:

tdelay = 0.2; % Delay time in s
abrake = 0.3; % Braking acceleration in m/s^2

% Derived from initial delay of tdelay followed by braking acceleration:
% d = v*tdelay + 0.5*(v^2/abrake)

d = max(d, 0);
v = abrake*(sqrt(tdelay^2 + 2*d./abrake) - tdelay);

return;
