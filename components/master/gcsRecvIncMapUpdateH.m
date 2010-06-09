function gcsRecvIncMapUpdateH(data, name)

global RMAP
global GPOSE GMAP

if isempty(data)
  return
end

msgSize = length(data);
fprintf(1,'got horizontal map update of size %d from %s\n',msgSize,name);
id = GetIdFromName(name);

update = deserialize(data);

xm = double(update.xs);
ym = double(update.ys);
cm = double(update.cs);

asgn(RMAP{id}, 'hlidar', xm, ym, cm);
asgn(RMAP{id}, 'cost', xm, ym, cm);

if ~isempty(GPOSE{id}),
  [xg, yg] = rpos_to_gpos(id, xm, ym);
  asgn(GMAP, 'hlidar', xg, yg, cm);
  asgn(GMAP, 'cost', xg, yg, cm);
end
