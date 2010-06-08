function c = interp(h, field, x, y)
% c = interp(h, field, x, y)

[i,j] = xysubs(h, x, y);

c = subs_interp(h.data.(field), i, j);
