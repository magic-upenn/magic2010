function ret = ipcAPIBridgeExternalDefine(msgName, fmt)
global IPC_BRIDGE_EXTERNAL

if (isempty(IPC_BRIDGE_EXTERNAL) || IPC_BRIDGE_EXTERNAL.connected ~=1)
  error('not connected to external ipc');
end

if (nargin < 2)
  ret = IPC_BRIDGE_EXTERNAL.handle('define',msgName);
else
  ret = IPC_BRIDGE_EXTERNAL.handle('define',msgName,fmt);
end
