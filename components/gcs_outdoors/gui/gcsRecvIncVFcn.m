function gcsRecvIncVFcn(data, name)

global RMAP
global GPOSE GMAP GCS

if isempty(data)
  return
end

msg = deserialize(data);
id = msg.id;
if ~any(id==GCS.ids)
  return;
end
fprintf(1,'got vertical map update from %d\n',id);

update = msg.update;

xm = double(update.xs);
ym = double(update.ys);
cm = double(update.cs);

xlim = RMAP{id}.x0+RMAP{id}.dx;
ylim = RMAP{id}.y0+RMAP{id}.dy;
map_filter(RMAP{id}.cost, xlim, ylim, [xm(:) ym(:) cm(:)]', 0.3);

