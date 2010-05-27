function status = ipcInit(host)

global IPC
if isempty(IPC)
  if nargin < 1
    host = 'localhost';
  end
  ipcAPIConnect(host);
  IPC.connected = 1;
  disp('IPC initialized');
end

status = 1;
