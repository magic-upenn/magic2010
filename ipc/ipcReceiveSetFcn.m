function status = ipcReceiveSetFcn(name, func, ipcApiHandle, queueLength)

global IPC

if nargin < 2 || ~isa(func,'function_handle'),
  error('Need to input a function handle');
end

%ipcApiHandle is a function handle which is a copy of ipcAPI
%this allows to explicitly specify which ipcAPI mexfile to use
if nargin < 3
  ipcApiHandle = @ipcAPI;
end

if nargin < 4
  setQueueLength = 0;
else
  setQueueLength = 1;
end

status = ipcApiHandle('subscribe',name);

%set (if needed) the queue length for the maximum number of messages
%to be buffered between the calls to receive messages
if (setQueueLength == 1)
  ipcApiHandle('set_msg_queue_length',name,queueLength);
end

%matlab does not like "/" in the name, so replace with "_"
name(name=='/')='_';
IPC.handler.(name) = func;