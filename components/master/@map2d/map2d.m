function h = map2d(nx, ny, resolution, varargin)
% map2d(nx, ny, resolution, varargin)
% Create a 2D map object.

if nargin < 1,
  nx = 100;
end
if nargin < 2,
  ny = 100;
end
if nargin < 3,
  resolution = 1.0;
end

h.nx = nx;
h.ny = ny;
h.resolution = resolution;
h.fields = varargin;

h.x0 = 0;
h.y0 = 0;
h.dx = h.resolution*([0:h.nx-1]-.5*(h.nx-1));
h.dy = h.resolution*([0:h.ny-1]-.5*(h.ny-1));
h.nshift = 0;

for i = 1:length(varargin),
  h.data.(varargin{i}) = zeros(nx,ny);
end

% Make the cast.
h = class(h,'map2d');
