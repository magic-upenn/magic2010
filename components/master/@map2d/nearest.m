function c = nearest(h, field, x, y)
% c = nearest(h, field, x, y)

[i,j] = xysubs(h, x, y);
i = min(max(round(i),1),h.nx);
j = min(max(round(j),1),h.ny);
ind = i + h.nx*(j-1);

f = h.data.(field);
c = f(ind);
