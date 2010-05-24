%convert desired velocities (m/s and rad/s) to motor commands
function [vCmd wCmd] = VelocityVals2VelocityCmd(vVal,wVal)

%TODO: figure out the mapping
vCmd = vVal*100;
wCmd = wVal*100;