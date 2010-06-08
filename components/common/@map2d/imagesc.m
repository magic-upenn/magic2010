function him = imagesc(h, field, varargin)
% Display scaled image.

f = h.data.(field);
him = imagesc(h.dx, h.dy, f, varargin{:});
