function ret = ipcAPIBridgeExternalSubscribe(msgName, queueLen)
global IPC_BRIDGE_EXTERNAL

if (isempty(IPC_BRIDGE_EXTERNAL) || IPC_BRIDGE_EXTERNAL.connected ~=1)
  error('not connected to external ipc');
end

if (nargin < 2)
  queueLen = 10;
end

ret = IPC_BRIDGE_EXTERNAL.handle('subscribe',msgName);

IPC_BRIDGE_EXTERNAL.handle('set_msg_queue_length',msgName,queueLen);
