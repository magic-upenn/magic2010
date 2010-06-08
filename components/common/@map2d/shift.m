function h = shift(h, x, y);

x0_old = h.x0;
y0_old = h.y0;

h.nshift = h.nshift + 1;
h.x0 = x;
h.y0 = y;

dix = round((h.x0 - x0_old)./h.resolution);
diy = round((h.y0 - y0_old)./h.resolution);

ix = [1:h.nx] + dix;
ix_valid = find((ix >= 1) & (ix <= h.nx));
ix0 = ix(ix_valid);

iy = [1:h.ny] + diy;
iy_valid = find((iy >= 1) & (iy <= h.ny));
iy0 = iy(iy_valid);

for i = 1:length(h.fields),
  fname = h.fields{i};
  f0 = h.data.(fname);
  f = zeros(h.nx, h.ny);
  f(ix_valid, iy_valid) = f0(ix0, iy0);
  h.data.(fname) = f;
end
