function RobotBridgeInitMessages()
clear global MSGS

global MSGS

MSGS.names       = cell(0);
MSGS.serializers = cell(0);

AddMsg('Lidar0',@MagicLidarScanSerializer);
AddMsg('Lidar1',@MagicLidarScanSerializer);
AddMsg('Servo1',@MagicServoStateSerializer);

function AddMsg(name,serializer)
global MSGS

name2                   = GetMsgName(name);
MSGS.names{end+1}       = name2;
MSGS.serializers{end+1} = serializer;
ipcAPIBridgeExternalDefine(name2,serializer('getFormat'));
fprintf('defined external message %s\n',name2);
