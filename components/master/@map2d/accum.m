function h = accum(h, field, x, y, c);

[i,j] = xysubs(h, x, y);

subs_accum(h.data.(field), i, j, c);
