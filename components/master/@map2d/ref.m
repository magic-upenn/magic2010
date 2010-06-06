function d = ref(h, field, x, y);

[i,j] = xysubs(h, x, y);

d = subs_ref(h.data.(field), i, j);
