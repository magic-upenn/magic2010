function h = asgn(h, field, x, y, c);

[i,j] = xysubs(h, x, y);

subs_asgn(h.data.(field), i, j, c);
