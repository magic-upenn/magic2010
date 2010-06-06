function handlerIncMapUpdateV(data, name)

global RMAP

if isempty(data)
  return
end

msgSize = length(data);
fprintf(1,'got vertical map update of size %d from %s\n',msgSize,name);
id = GetIdFromName(name);

update = deserialize(data);

accum(RMAP{id}, 'vlidar', ...
      double(update.xs), double(update.ys), double(update.cs)./256);
