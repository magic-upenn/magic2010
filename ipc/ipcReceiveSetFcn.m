function status = ipcReceiveSetFcn(name, func, ipcApiHandle)

global IPC

if nargin < 2 || ~isa(func,'function_handle'),
  error('Need to input a function handle');
end

%ipcApiHandle is a function handle which is a copy of ipcAPI
%this allows to explicitly specify which ipcAPI mexfile to use
if nargin < 3
  ipcApiHandle = @ipcAPI;
end

status = ipcApiHandle('subscribe',name);

%matlab does not like "/" in the name, so replace with "_"
name(name=='/')='_';
IPC.handler.(name) = func;