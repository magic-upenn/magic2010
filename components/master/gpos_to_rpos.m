function [xr, yr, ar] = gpos_to_rpos(id, xg, yg, ag);

global GTRANSFORM

if nargin < 4,
  ag = 0;
end

ca = cos(GTRANSFORM{id}.dyaw);
sa = sin(GTRANSFORM{id}.dyaw);

dx = ca*xg - sa*yg;
dy = sa*xg + ca*yg;

xr = dx + GTRANSFORM{id}.dx;
yr = dy + GTRANSFORM{id}.dy;
ar = ag + GTRANSFORM{id}.dyaw;
