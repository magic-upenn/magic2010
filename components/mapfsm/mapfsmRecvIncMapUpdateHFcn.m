function mapfsmRecvIncMapUpdateHFcn(data, name)

global MAP

if isempty(data)
  return
end

update = deserialize(data);

xh = double(update.xs);
yh = double(update.ys);
ch = double(update.cs)./256;


% Assignment to sparse set of points in hlidar map
MAP = asgn(MAP, 'hlidar', xh, yh, ch);

% Get corresponding points in vlidar map
cv = nearest(MAP, 'vlidar', xh, yh);

% Decay costs:
MAP = scale(MAP, 'cost', 0.99);

% Update total cost map:
total = cv + ch;
MAP = asgn(MAP, 'cost', xh, yh, ctotal);
