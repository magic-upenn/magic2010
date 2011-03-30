function ipcAPIBridgeInternalConnect()
global IPC_BRIDGE_INTERNAL

IPC_BRIDGE_INTERNAL.handle = @ipcAPIBridgeInternal;

centralInternal = getenv('IPC_CENTRAL_INTERNAL');

if isempty(centralInternal)
  error('server address is not defined');
end

IPC_BRIDGE_INTERNAL.handle('connect',centralInternal);
IPC_BRIDGE_INTERNAL.connected = 1;
IPC_BRIDGE_INTERNAL.central = centralInternal;
