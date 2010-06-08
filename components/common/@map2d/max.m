function h = max(h, field, x, y, c);

[i,j] = xysubs(h, x, y);

subs_max(h.data.(field), i, j, c);
