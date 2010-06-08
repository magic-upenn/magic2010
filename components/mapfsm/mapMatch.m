function [xm, ym, am] = mapMatch(map, xp, yp, x0, y0, a0)
% Match laser xp, yp with map2d and return best xm, ym, am shifts

persistent DATA

if isempty(DATA),
  DATA.xs = [-.02:.01:.02];
  DATA.ys = [-.02:.01:.02];
  DATA.as = [-.2:.1:.2]*pi/180;

  % 3-d ndgrid
  [DATA.xsg, DATA.ysg, DATA.asg] = ndgrid(DATA.xs, DATA.ys, DATA.as);
end

res = resolution(map);
xmap = x(map);
ymap = y(map);

c = getdata(map, 'cost');
olap = array_match(c, xp./res, yp./res, ...
                   (DATA.xsg+x0-xmap(1))./res, ...
                   (DATA.ysg+y0-ymap(1))./res, ...
                   DATA.asg+a0);

[omin, imin] = min(olap(:));
xm = DATA.xsg(imin);
ym = DATA.ysg(imin);
am = DATA.ysg(imin);
