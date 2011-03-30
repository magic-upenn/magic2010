function ret = ipcAPIBridgeInternalSubscribe(msgName, queueLen)
global IPC_BRIDGE_INTERNAL

if (isempty(IPC_BRIDGE_INTERNAL) || IPC_BRIDGE_INTERNAL.connected ~=1)
  error('not connected to external ipc');
end

if (nargin < 2)
  queueLen = 10;
end

ret = IPC_BRIDGE_INTERNAL.handle('subscribe',msgName);

IPC_BRIDGE_INTERNAL.handle('set_msg_queue_length',msgName,queueLen);
