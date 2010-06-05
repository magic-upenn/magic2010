function test_hokuyo1(addr,id)

SetMagicPaths;
ipcInit('localhost');

lidar1Init;
%servo1Init;

ipcReceiveSetFcn(GetMsgName('Lidar1'),      @slamProcessLidar1);
%ipcReceiveSetFcn(GetMsgName('Servo1'),      @slamProcessServo1);

loop = 1;
while loop,
  ipcReceiveMessages;
end
