function ipcAPIBridgeExternalConnect()
global IPC_BRIDGE_EXTERNAL

IPC_BRIDGE_EXTERNAL.handle = @ipcAPIBridgeExternal;

centralExternal = getenv('IPC_CENTRAL_EXTERNAL');

if isempty(centralExternal)
  error('server address is not defined');
end

IPC_BRIDGE_EXTERNAL.handle('connect',centralExternal);
IPC_BRIDGE_EXTERNAL.connected = 1;
IPC_BRIDGE_EXTERNAL.central = centralExternal;
