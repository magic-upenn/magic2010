%Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use.
function result = ipcAPIDefine(varargin)

if (nargin == 1)
  result = ipcAPI('define',varargin{1});
elseif (nargin == 2)
  result = ipcAPI('define',varargin{1},varargin{2});
else
  error('incorrect number of arguments');
end