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

% Decay costs
tDecay = 10.0;
MAP = scale(MAP, 'cost', exp(-.025/tDecay));

% Update total cost map:
MAP = asgn(MAP, 'cost', xh, yh, ch);
