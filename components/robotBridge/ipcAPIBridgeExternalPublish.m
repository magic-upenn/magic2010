function ret = ipcAPIBridgeExternalPublish(msgName,data)
global IPC_BRIDGE_EXTERNAL

if (isempty(IPC_BRIDGE_EXTERNAL) || IPC_BRIDGE_EXTERNAL.connected ~=1)
  error('not connected to external ipc');
end

serializer = RobotBridgeGetMsgSerializer(msgName);

if ~isempty(serializer)
  ret = IPC_BRIDGE_EXTERNAL.handle('publishVC',msgName,data);
else
  ret = IPC_BRIDGE_EXTERNAL.handle('publish',msgName,data);
end