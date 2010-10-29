function gcsRecvIncVFcn(data, name)

global RMAP
global GPOSE GMAP GCS

if isempty(data)
  return
end

msg = deserialize(data);
id = msg.id;
fprintf(1,'got vertical map update from %d\n',id);

update = msg.update;

xm = double(update.xs);
ym = double(update.ys);
cm = double(update.cs);

asgn(RMAP{id}, 'vlidar', xm, ym, cm);
asgn(RMAP{id}, 'cost', xm, ym, cm);

