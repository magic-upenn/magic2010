joy = @JoystickLogitechX3dAPI;

joy('connect','/dev/input/event7');

while(1)
  [v w] = joy('getCmd');
  %fprintf('v = %d, w = %d\n',v,w);
  pause(0.01)
end
