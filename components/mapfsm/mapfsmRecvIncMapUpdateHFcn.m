function mapfsmRecvIncMapUpdateHFcn(data, name)

global MAP

if isempty(data)
  return
end

update = deserialize(data);

xh = double(update.xs);
yh = double(update.ys);
ch = double(update.cs);

% Assignment to sparse set of points in hlidar map
MAP = asgn(MAP, 'hlidar', xh, yh, ch);

% Decay costs:
MAP = scale(MAP, 'cost', 0.999);

% Update total cost map:
MAP = asgn(MAP, 'cost', xh, yh, ch);
