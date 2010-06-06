function handlerIncMapUpdateH(data, name)

global RMAP

if isempty(data)
  return
end

msgSize = length(data);
fprintf(1,'got horizontal map update of size %d from %s\n',msgSize,name);
id = GetIdFromName(name);

update = deserialize(data);

accum(RMAP{id}, 'hlidar', ...
      double(update.xs), double(update.ys), double(update.cs)./256);
