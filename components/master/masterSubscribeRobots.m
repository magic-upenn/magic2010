function masterSubscribeRobots(msgNames,handles,queueLength)
global ROBOTS

%check whether the connection to robots has already been established
%if it has, then  ROBOTS struct will be non-empty
if isempty(ROBOTS)
  error('ROBOTS struct is empty : not connected');
end

nRobots = length(ROBOTS);
if nRobots < 1
  error('ROBOTS struct has length < 1: not connected');
end

if nargin < 3
  setQueueLengths = 0;
else
  setQueueLengths = 1;
end

nMsgs = length(msgNames);
if nMsgs ~= length(handles) || ((setQueueLengths == 1) && (nMsgs ~=length(queueLength)))
  error('number of message names is not equal to number of handles or the queue length');
end

for ii=1:nRobots
  if (ROBOTS(ii).connected == 1)
    for jj=1:nMsgs
        %generate the message name
        msgName = sprintf('Robot%d/%s',ROBOTS(ii).id,msgNames{jj});
        
        %assign a handle to the message name and optionally set the queue
        %length
        if setQueueLengths == 1
          ipcReceiveSetFcn(msgName,handles{jj},ROBOTS(ii).ipcAPI,queueLength(jj));
        else
           ipcReceiveSetFcn(msgName,handles{jj},ROBOTS(ii).ipcAPI);
        end
    end
  end
end