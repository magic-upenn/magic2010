function result = ipcAPIConnect(hostname,ipcAPIHandle)
global IPC

if nargin < 1,
  hostname = 'localhost'; % Default hostname
end

if nargin < 2
  ipcAPIHandle = @ipcAPI;
end

if ~(isempty(IPC) || ~isfield(IPC,'connected') || ~IPC.connected)
  result = 1;
  %disp('already connected to ipc');
  return;
end

result = ipcAPIHandle('connect',hostname);
IPC.handle = ipcAPIHandle;
IPC.connected = 1;
