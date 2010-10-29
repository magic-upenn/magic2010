function gmapAdd(id, p);

global GMAP
global RT

xm = double(p.xs);
ym = double(p.ys);
cm = double(p.cs);

tr = RT{id}.tr;

vg = tr.rotA*[xm(:) ym(:)]' + ...
     repmat([tr.dE; tr.dN],[1 length(xm)]);

asgn(GMAP, 'cost', vg(1,:), vg(2,:), cm);
