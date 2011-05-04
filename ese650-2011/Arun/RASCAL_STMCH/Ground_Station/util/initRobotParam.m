function initRobotParam()
global rParam


rParam.vmax = 1;    % maximum linear velocity [m/s]
rParam.amax = 100;  % maximum linear acceleration [m/s^2]

rParam.wmax = 2.7; % maximum angular velocity [rad/s] (up to 2.7 rad/s)
rParam.umax = 100;  % maximum angular acceleration [rad/s^2]

rParam.vlim = 1;    % artificial limit to the maximum velocity
rParam.wlim = 2.1; % artificial limit to the maximum angular velocity

rParam.wheelRad = 0.127;    % meters
rParam.minTurnRad = 0.25;   % meters
rParam.width = 0.4763;      % meters along body y axis
rParam.length = 0.5842;     % meters along body x axis

rParam.robotRad = (rParam.width+rParam.length)/4; % meters
rParam.robotRadFudge = 1.5574; %meters (calculated from 5 datasets)

rParam.encMetersPerTic = 0.0022;    % encoders meters per tic
end