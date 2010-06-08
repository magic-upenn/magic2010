function result = ipcAPIDefine(varargin)
global IPC

result = 0;
if isempty(IPC) || ~isfield(IPC,'connected') || ~IPC.connected
  disp('not connected to ipc');
  return
end

if (nargin == 1)
  result = IPC.handle('define',varargin{1});
elseif (nargin == 2)
  result = IPC.handle('define',varargin{1},varargin{2});
else
  error('incorrect number of arguments');
end