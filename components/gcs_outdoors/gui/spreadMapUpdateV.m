function recvMapUpdateV(data, name)

global RMAP

if isempty(data)
  return
end

fprintf(1,'got MapUpdateV of size %d from %s\n',length(data),name);
id = sscanf(name, 'robot%d_');

update = deserialize(data);

accum(RMAP{id}, 'vlidar', ...
      double(update.xs), double(update.ys), double(update.cs)./256);
