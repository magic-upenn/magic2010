function handlerIncMapUpdateH(data, name)

global RMAP

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
