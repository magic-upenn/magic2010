function ret = ipcAPIBridgeExternalListen(ms)
global IPC_BRIDGE_EXTERNAL

if (isempty(IPC_BRIDGE_EXTERNAL) || IPC_BRIDGE_EXTERNAL.connected ~=1)
  error('not connected to external ipc');
end

if (nargin < 1)
  ms = 0;
end

ret = IPC_BRIDGE_EXTERNAL.handle('listen',ms);
