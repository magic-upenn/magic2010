function handlerIncMapUpdateV(data, name)

global RMAP

if isempty(data)
  return
end

msgSize = length(data);
fprintf(1,'got vertical map update of size %d from %s\n',msgSize,name);
id = GetIdFromName(name);

update = deserialize(data);

xm = double(update.xs);
ym = double(update.ys);
cm = double(update.cs);

asgn(RMAP{id}, 'vlidar', xm, ym, cm);
asgn(RMAP{id}, 'cost', xm, ym, cm);
