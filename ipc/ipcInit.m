function status = ipcInit

global IPC
if isempty(IPC)
  ipcAPIConnect;
  IPC.connected = 1;
end

status = true;

disp('IPC initialized');