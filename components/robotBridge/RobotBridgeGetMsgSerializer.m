function ret = RobotBridgeGetMsgSerializer(msgName)

global MSGS

idx = find(strcmp(MSGS.names,msgName));

ret = MSGS.serializers{idx};
