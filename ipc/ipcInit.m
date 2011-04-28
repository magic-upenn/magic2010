function status = ipcInit(host,ipcAPIHandle)

global IPC
if isempty(IPC) || ~isfield(IPC,'connected') || ~IPC.connected
  if nargin < 1
    host = 'localhost';
  end
  
  fprintf(1,'connecting to ipc central at %s\n',host);
  
  if (nargin < 2)
    ipcAPIHandle = @ipcAPI;
  end
  ipcAPIHandle('connect',host);
  ipcAPIHandle('set_capacity',5);
  IPC.handle = ipcAPIHandle;
  IPC.connected = 1;
  disp('IPC initialized');
end

status = 1;
