function status = ipcReceiveSetFcn(name, func)

global IPC

if nargin < 2 || ~isa(func,'function_handle'),
  error('Need to input a function handle');
end

status = ipcAPISubscribe(name);

%matlab does not like "/" in the name, so replace with "_"
name(name=='/')='_';
IPC.handler.(name) = func;