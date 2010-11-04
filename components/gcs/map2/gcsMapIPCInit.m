function gcsMapIPCInit(arg)
  
global IPC_OUTPUT
  
if (arg)
  IPC_OUTPUT.ipcAPI = str2func('ipcAPI');
  IPC_OUTPUT.ipcAPI('connect');
  IPC_OUTPUT.ipcAPI('define', 'Global_Map');
  IPC_OUTPUT.ipcAPI('define', 'RPose');
  IPC_OUTPUT.ipcAPI('define', 'IncH');
  IPC_OUTPUT.ipcAPI('define', 'IncV');
end
