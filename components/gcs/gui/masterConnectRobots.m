function ret = masterConnectRobots(ids,addr)
global ROBOTS
%initialize the data structure for the maximum number of robots
maxRobots = 10;

%ipcAPIPrefix = 'ipcAPI';
ipcAPIPrefix = 'ipcWrapperAPI';

for ii=1:maxRobots
  %initialize the ids
  ROBOTS(ii).id     = ii;

  %initialize the ipcAPI function handles
  ROBOTS(ii).ipcAPI = str2func(sprintf('%s%d',ipcAPIPrefix,ii));
  
  %specify ip address and (optionally) port 
  %in format 'xxx.xxx.xxx.xxx:port'
  if nargin >1
    ROBOTS(ii).addr   = addr;
  else
    ROBOTS(ii).addr   = sprintf('192.168.10.%d',ii+100);
  end
  ROBOTS(ii).connected = 0;
end

for ii=1:length(ids)
  %use the a different ipcAPI for each robot
  %provide index as 3rd argument to generate unique name for each
  %connection
  id = ids(ii);
  ROBOTS(id).ipcAPI('connect',ROBOTS(id).addr,id);
  ROBOTS(id).connected = 1;
end

ret = 1;
