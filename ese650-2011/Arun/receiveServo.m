SetMagicPaths;

servoMsgName = GetMsgName('Servo1');

ipcAPIConnect;
ipcAPISubscribe(servoMsgName);


while(1)
  msgs = ipcAPIReceive(10);
  len = length(msgs);
  if len > 0
    for i=1:len
      servoData = MagicServoStateSerializer('deserialize',msgs(i).data)
      %fprintf(1,'.');
    end
  end
end