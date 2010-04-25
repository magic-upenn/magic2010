function result = ipcAPIDefine(varargin)

if (nargin == 1)
  result = ipcAPI('define',varargin{1});
elseif (nargin == 2)
  result = ipcAPI('define',varargin{1},varargin{2});
else
  error('incorrect number of arguments');
end