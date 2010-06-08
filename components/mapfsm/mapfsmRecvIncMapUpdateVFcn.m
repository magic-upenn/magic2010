function mapfsmRecvIncMapUpdateVFcn(data, name)

global MAP

if isempty(data)
  return
end

update = deserialize(data);

xv = double(update.xs);
yv = double(update.ys);
cv = double(update.cs)./126;

% Assignment to sparse set of points in vlidar map
MAP = asgn(MAP, 'vlidar', xv, yv, cv);

% Get corresponding points in hlidar map
ch = nearest(MAP, 'hlidar', xv, yv);

% Decay costs:
MAP = scale(MAP, 'cost', 0.99);

% Update total cost map:
ctotal = cv + ch;
MAP = asgn(MAP, 'cost', xh, yh, ctotal);
