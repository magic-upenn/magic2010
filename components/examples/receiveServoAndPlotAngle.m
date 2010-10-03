SetMagicPaths;

servoMsgName = GetMsgName('Servo1');

ipcAPIConnect;
ipcAPISubscribe(servoMsgName);


len = 300;

figure(1); clf(gcf);
angles = zeros(1,len);
h = plot(1:len,angles);


while(1)
  msgs = ipcAPIReceive(10);
  len = length(msgs);
  if len > 0
    for i=1:len
      servoData = MagicServoStateSerializer('deserialize',msgs(i).data)
      angles = [servoData.position/pi*180 angles(1:end-1)];
      set(h,'ydata',angles); drawnow;
      %fprintf(1,'.');
    end
  end
end