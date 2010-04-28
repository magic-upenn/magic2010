function status = ipcReceiveSetFcn(name, func)

global IPC

if nargin < 2 || ~isa(func,'function_handle'),
  error('Need to input a function handle');
end

IPC.handler.(name) = func;
status = ipcAPISubscribe(name);