function [xm, ym, am, omax] = mapMatch(map, field, xp, yp, xs, ys, as)
% Match laser xp, yp with map2d field and return best xs, ys, as shifts

[xsg, ysg, asg] = ndgrid(xs, ys, as);

res = resolution(map);
xmap = x(map);
ymap = y(map);

c = getdata(map, field);
olap = array_match(c, xp./res, yp./res, ...
                   (xsg-xmap(1))./res, ...
                   (ysg-ymap(1))./res, ...
                   asg);

xsg0 = max(abs(xsg(:)))+eps;
ysg0 = max(abs(ysg(:)))+eps;
asg0 = max(abs(asg(:)))+eps;

olapbias = olap - .1*((xsg./xsg0).^2 + (ysg./ysg0).^2 + (asg./asg0).^2);

[omax, imax] = max(olapbias(:));
xm = xsg(imax);
ym = ysg(imax);
am = asg(imax);
