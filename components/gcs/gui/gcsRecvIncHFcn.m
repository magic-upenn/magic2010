function gcsRecvIncHFcn(data, name)

global RMAP

if isempty(data)
  return
end

msg = deserialize(data);
id = msg.id;

fprintf(1,'got horizontal map update from %d\n',id);

update = msg.update;

xm = double(update.xs);
ym = double(update.ys);
cm = double(update.cs);

asgn(RMAP{id}, 'hlidar', xm, ym, cm);
asgn(RMAP{id}, 'cost', xm, ym, cm);

