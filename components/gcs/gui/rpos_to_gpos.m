function [xg, yg, ag] = rpos_to_gpos(id, xr, yr, ar);

global GTRANSFORM

if nargin < 4,
  ar = 0;
end

dx = xr - GTRANSFORM{id}.dx;
dy = yr - GTRANSFORM{id}.dy;

ca = cos(GTRANSFORM{id}.dyaw);
sa = sin(GTRANSFORM{id}.dyaw);

xg = ca*dx + sa*dy;
yg = -sa*dx + ca*dy;
ag = ar - GTRANSFORM{id}.dyaw;
