function p = gmapPoints(im, xim, yim, xplim, yplim, threshold);

if nargin < 6,
  threshold = 0;
end

[nx, ny] = size(im);
x1 = xim(1)+[0:nx-1]*(xim(end)-xim(1))/(nx-1);
y1 = yim(1)+[0:ny-1]*(yim(end)-yim(1))/(ny-1);

ix = find((x1 >= xplim(1)) & (x1 <= xplim(end)));
iy = find((y1 >= yplim(1)) & (y1 <= yplim(end)));

if (length(ix)==0) || (length(iy)==0),
  p = zeros(3,0);
  return;
end

imsub = im(ix, iy);
[ip, jp, sp] = find(imsub > threshold);

x1sub = x1(ix);
y1sub = y1(iy);

xp = x1sub(ip);
yp = y1sub(jp);
cp = double(sp);

p = [xp(:) yp(:) cp(:)]';
