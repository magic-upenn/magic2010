function ret = ipcAPIBridgeInternalListen(ms)
global IPC_BRIDGE_INTERNAL

if (isempty(IPC_BRIDGE_INTERNAL) || IPC_BRIDGE_INTERNAL.connected ~=1)
  error('not connected to external ipc');
end

if (nargin < 1)
  ms = 0;
end

ret = IPC_BRIDGE_INTERNAL.handle('listen',ms);
