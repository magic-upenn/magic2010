function ret = visionConnectGCS(addr)
%ipcAPIPrefix = 'ipcAPI';
global VISION_IPC; 

ipcAPIPrefix = 'ipcWrapperAPI';
id = 10; 
%initialize the ipcAPI function handles
VISION_IPC = str2func(sprintf('%s%d',ipcAPIPrefix,id));
  %specify ip address and (optionally) port 
  %in format 'xxx.xxx.xxx.xxx:port'
  %use the a different ipcAPI for each robot
  %provide index as 3rd argument to generate unique name for each
  %connection
VISION_IPC('connect',addr,id);
ret = 1; 
